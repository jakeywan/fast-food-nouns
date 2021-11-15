async function main() {

  const [deployer] = await ethers.getSigners();
  console.log('Deploying contracts with the account:', deployer.address)

  //=========================DEPLOY CONTRACTS================================

  // DEPLOY ARBIS NOUNS
  const ArbisNouns = await ethers.getContractFactory('ArbisNouns');
  const arbisNouns = await ArbisNouns.deploy();
  console.log('AribsNouns deployed to: ', arbisNouns.address)  

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });