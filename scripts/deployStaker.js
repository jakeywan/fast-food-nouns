const { svgData } = require('../files/svgData.js')
const { seeds } = require('../files/seeds.js')

async function main() {

  const [deployer] = await ethers.getSigners()
  console.log('Deploying contracts with the account:', deployer.address)

  const Staker = await ethers.getContractFactory('Staker')
  // NOTE: Mainnet values used here
  const staker = await Staker.deploy('0x86e4dc95c7fbdbf52e33d563bbdb00823894c287', '0xfe5e5D361b2ad62c541bAb87C45a0B9B018389a2')
  console.log('Staker deployed to: ', staker.address)

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });