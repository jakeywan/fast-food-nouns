const { svgData } = require('../files/svgData.js')
const { seeds } = require('../files/seeds.js')
const ethers = require('ethers')
require('dotenv').config()

const execPolygon = async () => {
  // Provider
  const provider = new ethers.providers.JsonRpcProvider(`https://polygon-mainnet.infura.io/v3/${process.env.INFURA_PROJECT_ID}`)

  // Signer
  const wallet = new ethers.Wallet(process.env.WALLET_PRIVATE_KEY, provider)
  
  // Contract
  const address = '0x514715Fc7F687Ed94E585CaB2bB3009d70C2Cc40'
  const abi = '[{"inputs":[{"internalType":"address","name":"_fxChild","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"approved","type":"address"},{"indexed":true,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"operator","type":"address"},{"indexed":false,"internalType":"bool","name":"approved","type":"bool"}],"name":"ApprovalForAll","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bytes","name":"message","type":"bytes"}],"name":"MessageSent","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":true,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"Transfer","type":"event"},{"inputs":[{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"approve","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"backgrounds","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"fxChild","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"fxRootTunnel","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"generateSVGImage","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"getApproved","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"getWearableRefsForTokenId","outputs":[{"components":[{"internalType":"address","name":"contractAddress","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"internalType":"struct IOpenWearables.WearableRef[]","name":"","type":"tuple[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"headPositions","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"headSVGs","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"operator","type":"address"}],"name":"isApprovedForAll","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"ownerOf","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"stateId","type":"uint256"},{"internalType":"address","name":"rootMessageSender","type":"address"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"processMessageFromRoot","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"bytes","name":"_data","type":"bytes"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"seeds","outputs":[{"internalType":"uint48","name":"background","type":"uint48"},{"internalType":"uint48","name":"body","type":"uint48"},{"internalType":"uint48","name":"accessory","type":"uint48"},{"internalType":"uint48","name":"head","type":"uint48"},{"internalType":"uint48","name":"glasses","type":"uint48"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"operator","type":"address"},{"internalType":"bool","name":"approved","type":"bool"}],"name":"setApprovalForAll","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_fxRootTunnel","type":"address"}],"name":"setFxRootTunnel","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_fxRootTunnel","type":"address"}],"name":"setFxRootTunnelAddress","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes4","name":"interfaceId","type":"bytes4"}],"name":"supportsInterface","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"index","type":"uint256"}],"name":"tokenByIndex","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"tokenDescription","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"uint256","name":"index","type":"uint256"}],"name":"tokenOfOwnerByIndex","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"tokenURI","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"transferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"seed","type":"uint256"},{"internalType":"string","name":"svg","type":"string"}],"name":"updateHeadSVG","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"components":[{"internalType":"uint48","name":"background","type":"uint48"},{"internalType":"uint48","name":"body","type":"uint48"},{"internalType":"uint48","name":"accessory","type":"uint48"},{"internalType":"uint48","name":"head","type":"uint48"},{"internalType":"uint48","name":"glasses","type":"uint48"}],"internalType":"struct INounsSeeder.Seed","name":"seed","type":"tuple"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"updateSeed","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"description","type":"string"}],"name":"updateTokenDescription","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"uint256","name":"headPosition","type":"uint256"},{"components":[{"internalType":"address","name":"contractAddress","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"internalType":"struct IOpenWearables.WearableRef[]","name":"wRefs","type":"tuple[]"}],"name":"wearWearables","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"wearableRefsByTokenId","outputs":[{"internalType":"address","name":"contractAddress","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"stateMutability":"view","type":"function"}]'
  let contract = new ethers.Contract(address, abi, wallet)

  // wait a few seconds 
  const timer = () => {
    return new Promise((resolve, reject) => {
      setTimeout(() => {
        resolve()
      }, 2000)
    })
  }
  
  // Update head svgs
  // let nonce = 400
  // for (let i = 228; i < svgData.heads.length; i++) {
    // if (i !== 152) continue
    // const update = await contract.updateHeadSVG(i, svgData.heads[i].innerSVG, {
    //   gasPrice: 50000000000,
    //   nonce: nonce
    // })
    // console.log(`head updated at position ${i}`)
    // await timer()
    // console.log(ethers.BigNumber.from(update.gasPrice).toNumber())
    // const receipt = await update.wait()
    // if (receipt.status === 1) {
    //   console.log('updated: ', receipt)
    // } else {
    //   console.log('err with update: ', receipt)
    // }
    // nonce = nonce + 1
  // }

  // UPDATE SEEDS
  // let nonce = 307
  for (let i = 720; i < seeds.length; i++) {
    const seed = await contract.updateSeed(seeds[i], i, {
        gasPrice: 60000000000,
        // nonce: nonce
      })
    console.log('seed updated ', i)
    console.log(seed)
    // nonce++
  }


  
}

execPolygon()