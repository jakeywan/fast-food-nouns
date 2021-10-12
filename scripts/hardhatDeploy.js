async function main() {

  const NounsToken = await ethers.getContractFactory('NounsToken');
  // Use the deployed descriptor address so NounsToken points to it
  const nounsToken = await NounsToken.deploy();

  console.log('NOUNSTOKEN DEPLOYED TO', nounsToken.address);

  // Execute a test mint
  const testAccounts = await ethers.provider.listAccounts()

  const mint = await nounsToken.mint('1', {
    from: testAccounts[0],
    gasPrice: 10000000000,
    value: '30000000000000000'
  })
  console.log('Minted')

  // set a new clothing item to the closet
  const clothing = await nounsToken.addClothes('<path d="M230 220H90V230H230V220Z" fill="#005A9C"/><path d="M230 230H90V240H230V230Z" fill="#005A9C"/><path d="M230 240H90V250H230V240Z" fill="#005A9C"/><path d="M110 250H90V260H110V250Z" fill="#005A9C"/><path d="M230 250H120V260H230V250Z" fill="#005A9C"/><path d="M110 260H90V270H110V260Z" fill="#005A9C"/><path d="M230 260H120V270H230V260Z" fill="#005A9C"/><path d="M110 270H90V280H110V270Z" fill="#005A9C"/><path d="M230 270H120V280H230V270Z" fill="#005A9C"/><path d="M110 280H90V290H110V280Z" fill="#005A9C"/><path d="M230 280H120V290H230V280Z" fill="#005A9C"/><path d="M110 290H90V300H110V290Z" fill="#005A9C"/><path d="M230 290H120V300H230V290Z" fill="#005A9C"/><path d="M110 300H90V310H110V300Z" fill="#005A9C"/><path d="M230 300H120V310H230V300Z" fill="#005A9C"/><path d="M110 310H90V320H110V310Z" fill="#005A9C"/><path d="M230 310H120V320H230V310Z" fill="#005A9C"/><path d="M160 230H150V280H160V230Z" fill="white"/><path d="M190 270H160V280H190V270Z" fill="white"/><path d="M180 260H170V300H180V260Z" fill="white"/><path d="M200 260H190V300H200V260Z" fill="white"/><path d="M190 250H180V260H190V250Z" fill="white"/><path d="M230 210H90V220H230V210Z" fill="#005A9C"/>', {
    from: testAccounts[0]
  })
  console.log('Added Dodgers shirt')

  const wearClothes = await nounsToken.wearClothes(0, [0, 1], {
    from: testAccounts[0]
  })
  console.log('Wearing shirt')

  const ourClothes = await nounsToken.getClothesForTokenId(0, {
    from: testAccounts[0]
  })
  console.log('Here is our clothes: ', ourClothes)

  // Fetch test tokenURI
  // const tokenURI = await nounsToken.tokenURI('0')
  // console.log('token uri', tokenURI)

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });