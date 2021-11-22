async function main() {

  const [deployer] = await ethers.getSigners()
  console.log('Deploying contracts with the account:', deployer.address)

  const NounsToken = await ethers.getContractFactory('FastFoodNouns')
  const nounsToken = await NounsToken.deploy()
  console.log('Goerli Nouns deployed to: ', nounsToken.address)

  await nounsToken.toggleSale()

  await nounsToken.mint(1, {
    gasLimit: 250000,
    value: '30000000000000000'
  })

  console.log('Minted token 0')

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });