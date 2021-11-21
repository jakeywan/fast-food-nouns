const { svgData } = require('../files/svgData.js')
const { seeds } = require('../files/seeds.js')

async function main() {

  const [deployer] = await ethers.getSigners();
  console.log('Deploying contracts with the account:', deployer.address)

  // DEPLOY ARBIS NOUNS
  const ArbisNouns = await ethers.getContractFactory('ArbisNouns')
  const arbisNouns = await ArbisNouns.deploy()
  console.log('ArbisNouns deployed to: ', arbisNouns.address)


  // UPDATE HEAD SVGS
  for (let i = 0; i < svgData.heads.length; i++) {
    await arbisNouns.updateHeadSVG(i, svgData.heads[i].innerSVG)
    console.log('head updated ', svgData.heads[i].innerSVG)
  }

  // UPDATE SEEDS
  for (let i = 0; i < seeds.length; i++) {
    await arbisNouns.updateSeed(seeds[i], i)
    console.log('seed updated ', i)
  }

  // UPDATE SNAPSHOT



}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });