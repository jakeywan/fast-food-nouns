const { svgData } = require('../files/svgData.js')
const { seeds } = require('../files/seeds.js')

async function main() {

  const [deployer] = await ethers.getSigners()
  console.log('Deploying contracts with the account:', deployer.address)

  const Staker = await ethers.getContractFactory('Staker')
  // NOTE: Goerli values used here
  const staker = await Staker.deploy('0x2890bA17EfE978480615e330ecB65333b880928e', '0x3d1d3E34f7fB6D26245E6640E1c50710eFFf15bA')
  console.log('Staker deployed to: ', staker.address)

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });