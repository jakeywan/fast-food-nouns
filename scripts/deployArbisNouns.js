async function main() {

  const [deployer] = await ethers.getSigners();
  console.log('Deploying contracts with the account:', deployer.address)

  //=========================DEPLOY CONTRACTS================================

  // DEPLOY ARBIS NOUNS
  const ArbisNouns = await ethers.getContractFactory('ArbisNouns')
  const arbisNouns = await ArbisNouns.deploy()
  console.log('ArbisNouns deployed to: ', arbisNouns.address)

  // Update address of oracle
  await arbisNouns.updateOracle('0xc77540882c27a0cf96061B64BeE92Fe5ef4F0453')
  console.log('Updated oracle address')

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });