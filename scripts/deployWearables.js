async function main() {

  const [deployer] = await ethers.getSigners();
  console.log('Deploying contracts with the account:', deployer.address)
  console.log('Account balance:', (await deployer.getBalance()).toString())

  const NounsToken = await ethers.getContractFactory('FFNWearables')
  // Use the deployed descriptor address so NounsToken points to it
  const nounsToken = await NounsToken.deploy();

  console.log('Wearables deployed to: ', nounsToken.address)

  // If we're deploying to mainnet, stop here
  if (process.env.HARDHAT_NETWORK !== 'rinkeby' && process.env.HARDHAT_NETWORK !== 'localhost') return

  const testAccounts = await ethers.provider.listAccounts()
  console.log('Test account: ', testAccounts[0])

  // Mint first wearables
  const wearable = {
    rleData: '0x0015171f090e020e02020201030302020406020102030302020204010202050302010201030100010301020104010201040102030502020202010004020104020202050202020201000702010503020202010002020105080202020100040201040602020201000b02020201000b02',
    palette: ["", "000000", "ede7ce", "ddd1a0", "c15927", "e0c12e"],
    gridSize: 32
  }
  const mint = await nounsToken.mint(10, wearable, {
    gasLimit: 550000
  })
  console.log('Minted')

  const tokenURI = await nounsToken.tokenURI(0)
  console.log('TokenURI: ', tokenURI);

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });