async function main() {

  const [deployer] = await ethers.getSigners();
  console.log('Deploying contracts with the account:', deployer.address)
  console.log('Account balance:', (await deployer.getBalance()).toString())

  const NounsToken = await ethers.getContractFactory('FFNWearables')
  // Use the deployed descriptor address so NounsToken points to it
  const wearablesContract = await NounsToken.deploy();

  console.log('Wearables deployed to: ', wearablesContract.address)

  // const testAccounts = await ethers.provider.listAccounts()
  // console.log('Test account: ', testAccounts[0])

  // // Mint the default shirt
  // const defaultShirt = {
  //   name: 'Fast Food Uniform',
  //   innerSVG: '<path d="M1 0H0V1H1V0Z" fill="#E1D7D5"/><path d="M230 210H90V220H230V210Z" fill="#867C1D"/><path d="M230 220H90V230H230V220Z" fill="#867C1D"/><path d="M230 230H90V240H230V230Z" fill="#867C1D"/><path d="M230 210H90V250H230V210Z" fill="#E11833"/><path d="M110 250H90V260H110V250Z" fill="#867C1D"/><path d="M230 250H120V260H230V250Z" fill="#867C1D"/><path d="M110 260H90V270H110V260Z" fill="#867C1D"/><path d="M230 260H120V270H230V260Z" fill="#867C1D"/><path d="M110 270H90V280H110V270Z" fill="#867C1D"/><path d="M230 270H120V280H230V270Z" fill="#867C1D"/><path d="M110 280H90V290H110V280Z" fill="#867C1D"/><path d="M230 280H120V290H230V280Z" fill="#867C1D"/><path d="M110 290H90V300H110V290Z" fill="#867C1D"/><path d="M230 290H120V300H230V290Z" fill="#867C1D"/><path d="M110 300H90V310H110V300Z" fill="#867C1D"/><path d="M230 300H120V310H230V300Z" fill="#867C1D"/><path d="M110 210H90V320H110V210Z" fill="#E11833"/><path d="M230 210H120V320H230V210Z" fill="#E11833"/><path d="M200 260H150V270H200V260Z" fill="#EED811"/><path d="M160 250H150V260H160V250Z" fill="#EED811"/><path d="M170 240H160V250H170V240Z" fill="#EED811"/><path d="M180 250H170V260H180V250Z" fill="#EED811"/><path d="M190 240H180V250H190V240Z" fill="#EED811"/><path d="M200 250H190V260H200V250Z" fill="#EED811"/>',
  // }

  // const mint = await wearablesContract.adminMintNew(deployer.address, 1, defaultShirt, {
  //   gasLimit: 10000000
  // })
  // console.log('Minted')

  // const tokenURI = await wearablesContract.tokenURI(0)
  // console.log('TokenURI: ', tokenURI);

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });