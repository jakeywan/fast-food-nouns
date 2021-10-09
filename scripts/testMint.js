// Run a test mint against a local contract. Make sure to run a local network
// with npx hardhat node, then npm run deploy-local, then replace local contract
// address.
async function main () {
  // Set up an ethers contract, representing our deployed Box instance
  const address = '0x927b167526bAbB9be047421db732C663a0b77B11'
  const NounsToken = await ethers.getContractFactory('NounsToken')
  const nounsToken = await NounsToken.attach(address)
  const testAccounts = await ethers.provider.listAccounts()

  const mint = await nounsToken.mint('1', {
    from: testAccounts[0],
    // gas: gasValue,
    value: '3000000000000000000'
  })

  const tokenURI = await nounsToken.tokenURI('0')
  console.log('Minted: ', tokenURI)

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });