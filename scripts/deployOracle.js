const { Bridge } = require('arb-ts')
const { hexDataLength } = require('@ethersproject/bytes')

async function main() {

  const [deployer] = await ethers.getSigners();
  console.log('Deploying contracts with the account:', deployer.address)

  // DEPLOY ORACLE
  const Oracle = await ethers.getContractFactory('FFNOracle')
  const oracle = await Oracle.deploy()
  console.log('Oracle deployed to: ', oracle.address)

  // FOR RINKEBY
  await oracle.updateFFNContract('0x419ccff619e671dd772c0fc7326a5c0368ea751c')
  await oracle.updateArbisNounsContract('0xc77e10614d33a1de721f047ea97307f434bcf210')
  console.log('Updated contract addresses')

  // UPDATE 0 TOKEN OWNERSHIP DATA
  // https://github.com/OffchainLabs/arbitrum-tutorials/blob/487f3bbf9006dfe648acb673c6387fe1b2360077/packages/greeter/scripts/exec.js

  /**
   * Use wallets to create an arb-ts bridge instance to use its convenience methods
   */
  const l1Provider = new ethers.providers.JsonRpcProvider(`https://rinkeby.infura.io/v3/${process.env.INFURA_PROJECT_ID}`)
  const l2Provider = new ethers.providers.JsonRpcProvider('https://rinkeby.arbitrum.io/rpc')
  const signer = new ethers.Wallet(process.env.WALLET_PRIVATE_KEY)

  const l1Signer = signer.connect(l1Provider)
  const l2Signer = signer.connect(l2Provider)
  const bridge = await Bridge.init(l1Signer, l2Signer)
  
  /**
   * Base submission cost is a special cost for creating a retryable ticket;
   * querying the cost requires us to know how many bytes of calldata out retryable
   * ticket will require, so let's figure that out.
   * We'll get the bytes for our address and tokenId data, then add 4 for the
   * 4-byte function signature.
   */

  const totalBytes = ethers.utils.defaultAbiCoder.encode(
    ['uint256', 'address'],
    [0, '0x963C43558fDaA7e147A14A92d4B7346A65b59694']
  )
  const newGreetingBytesLength = hexDataLength(totalBytes) + 4 // 4 bytes func identifier

  /**
   * Now we can query the submission price using a helper method; the first value
   * returned tells us the best cost of our transaction; that's what we'll be using.
   * The second value (nextUpdateTimestamp) tells us when the base cost will
   * next update (base cost changes over time with chain congestion; the value
   * updates every 24 hours). We won't actually use it here, but generally it's
   * useful info to have.
   */
  const [_submissionPriceWei, nextUpdateTimestamp] =
    await bridge.l2Bridge.getTxnSubmissionPrice(newGreetingBytesLength)
  console.log(
    `Current retryable base submission price: ${_submissionPriceWei.toString()}`
  )

  /**
   * ...Okay, but on the off chance we end up underpaying, our retryable ticket
   * simply fails.
   * This is highly unlikely, but just to be safe, let's increase the amount we'll
   * be paying (the difference between the actual cost and the amount we pay gets
   * refunded to our address on L2 anyway)
   * (Note that in future releases, the max cost increase per 24 hour window of
   * 150% will be enforced, so this will be less of a concern.)
   */
  const submissionPriceWei = _submissionPriceWei.mul(5)

  /**
   * Now we'll figure out the gas we need to send for L2 execution; this requires the L2 gas price and gas limit for our L2 transaction
   */

  /**
   * For the L2 gas price, we simply query it from the L2 provider, as we would when using L1
   */

  const gasPriceBid = await bridge.l2Provider.getGasPrice()
  console.log(`L2 gas price: ${gasPriceBid.toString()}`)

  /**
   * For the gas limit, we'll simply use a hard-coded value (for more precise / dynamic estimates, see the estimateRetryableTicket method in the NodeInterface L2 "precompile")
   */
  const maxGas = 100000

  /**
   * With these three values, we can calculate the total callvalue we'll need our L1 transaction to send to L2
   */
  const callValue = submissionPriceWei.add(gasPriceBid.mul(maxGas))

  console.log(
    `Sending data to L2 with ${callValue.toString()} callValue for L2 fees:`
  )

  const updateArbisNounOwner = await oracle.updateArbisNounOwner(
    0, // string memory _greeting,
    submissionPriceWei,
    maxGas,
    gasPriceBid,
    {
      value: callValue,
    }
  )
  const receipt = await updateArbisNounOwner.wait()

  console.log(
    `Greeting txn confirmed on L1! 🙌 ${receipt.transactionHash}`
  )


}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });