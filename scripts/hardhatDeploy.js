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

  // Fetch test tokenURI
  const tokenURI = await nounsToken.tokenURI('0')

  console.log('token uri', tokenURI)

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });