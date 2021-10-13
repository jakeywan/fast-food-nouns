async function main() {

  const NounsToken = await ethers.getContractFactory('FastFoodNouns');
  // Use the deployed descriptor address so NounsToken points to it
  const nounsToken = await NounsToken.deploy();

  console.log('NOUNSTOKEN DEPLOYED TO', nounsToken.address);

  return; // FOR MAINNET, JUST STOP HERE

  // If we're deploying to mainnet, stop here
  if (process.env.HARDHAT_NETWORK !== 'rinkeby' && process.env.HARDHAT_NETWORK !== 'local') return;

  const testAccounts = await ethers.provider.listAccounts()
  console.log(testAccounts)

  // Set descriptor and seeder to rinkeby addresses
  const setSeeder = await nounsToken.setSeeder('0xA98A1b1Cc4f5746A753167BAf8e0C26AcBe42F2E', {
    from: testAccounts[0],
    gasLimit: 250000
  })
  const setDescriptor = await nounsToken.setDescriptor('0x53cB482c73655D2287AE3282AD1395F82e6a402F', {
    from: testAccounts[0],
    gasLimit: 250000
  })
  console.log('Updated seeder and descriptor')

  // Toggle sale active
  const toggleSale = await nounsToken.toggleSale({
    from: testAccounts[0],
    gasLimit: 250000
  })
  console.log('Toggled sale active')

  // Execute a test mint
  const mint = await nounsToken.mint(1, {
    from: testAccounts[0],
    gasLimit: 250000,
    value: '300000000000000000'
  })
  console.log('Minted 20 tokens')

  // Set a new clothing item to the closet
  const clothing = await nounsToken.addClothes('<path d="M230 220H90V230H230V220Z" fill="#005A9C"/><path d="M230 230H90V240H230V230Z" fill="#005A9C"/><path d="M230 240H90V250H230V240Z" fill="#005A9C"/><path d="M110 250H90V260H110V250Z" fill="#005A9C"/><path d="M230 250H120V260H230V250Z" fill="#005A9C"/><path d="M110 260H90V270H110V260Z" fill="#005A9C"/><path d="M230 260H120V270H230V260Z" fill="#005A9C"/><path d="M110 270H90V280H110V270Z" fill="#005A9C"/><path d="M230 270H120V280H230V270Z" fill="#005A9C"/><path d="M110 280H90V290H110V280Z" fill="#005A9C"/><path d="M230 280H120V290H230V280Z" fill="#005A9C"/><path d="M110 290H90V300H110V290Z" fill="#005A9C"/><path d="M230 290H120V300H230V290Z" fill="#005A9C"/><path d="M110 300H90V310H110V300Z" fill="#005A9C"/><path d="M230 300H120V310H230V300Z" fill="#005A9C"/><path d="M110 310H90V320H110V310Z" fill="#005A9C"/><path d="M230 310H120V320H230V310Z" fill="#005A9C"/><path d="M160 230H150V280H160V230Z" fill="white"/><path d="M190 270H160V280H190V270Z" fill="white"/><path d="M180 260H170V300H180V260Z" fill="white"/><path d="M200 260H190V300H200V260Z" fill="white"/><path d="M190 250H180V260H190V250Z" fill="white"/><path d="M230 210H90V220H230V210Z" fill="#005A9C"/>', {
    from: testAccounts[0],
    gasLimit: 1000000
  })
  console.log('Added Dodgers shirt to clothingList')

  // Put clothes on tokenId 0
  const wearClothes = await nounsToken.wearClothes(0, [0, 1], {
    from: testAccounts[0],
    gasLimit: 250000
  })
  console.log('tokenId 0 wearing hat and shirt')

  // Get clothes worn by tokenId 0
  const ourClothes = await nounsToken.getClothesForTokenId(0, {
    from: testAccounts[0],
    gasLimit: 250000
  })
  console.log('tokenId 0 clothing: ', JSON.stringify(ourClothes))

  // Fetch test tokenURI
  const tokenURI = await nounsToken.tokenURI('0', {
    from: testAccounts[0],
    gasLimit: 250000
  })
  console.log('token uri for tokenId 0: ', tokenURI)

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });