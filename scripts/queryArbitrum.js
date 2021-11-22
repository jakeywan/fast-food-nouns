const ethers = require('ethers')
require('dotenv').config()

const queryArbitrum = async () => {
  // Provider
  const provider = new ethers.providers.JsonRpcProvider(`https://goerli.infura.io/v3/${process.env.INFURA_PROJECT_ID}`)

  // Signer
  const wallet = new ethers.Wallet(process.env.WALLET_PRIVATE_KEY, provider)
  
  // Contract
  const address = '0x7785d3AC4DAc5894c30a5C2807C055CF51487a22'
  const abi = '[{"inputs":[{"internalType":"address","name":"_checkpointManager","type":"address"},{"internalType":"address","name":"_fxRoot","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"inputs":[],"name":"SEND_MESSAGE_EVENT_SIG","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"checkpointManager","outputs":[{"internalType":"contract ICheckpointManager","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"fxChildTunnel","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"fxRoot","outputs":[{"internalType":"contract IFxStateSender","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"operator","type":"address"},{"internalType":"address","name":"from","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"onERC721Received","outputs":[{"internalType":"bytes4","name":"","type":"bytes4"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"name":"processedExits","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes","name":"inputData","type":"bytes"}],"name":"receiveMessage","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_contract","type":"address"}],"name":"setChildContract","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_fxChildTunnel","type":"address"}],"name":"setFxChildTunnel","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"stakedOwners","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"tokenContract","outputs":[{"internalType":"contract ERC721","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"unstake","outputs":[],"stateMutability":"nonpayable","type":"function"}]'
  let contract = new ethers.Contract(address, abi, wallet)
  
  // Functions
  // const totalSupply = await contract.mint(10, {
  //   value: '300000000000000000'
  // })
  // console.log(totalSupply)

  // const safeTransfer = await contract['safeTransferFrom(address,address,uint256)'](
  //   '0xaBCF7ca8Ba78eB75d79DFf6B0F9fa23e78293cCB',
  //   '0x7785d3AC4DAc5894c30a5C2807C055CF51487a22',
  //   2
  // )

  const unstake = await contract.unstake(2)


  
}

queryArbitrum()