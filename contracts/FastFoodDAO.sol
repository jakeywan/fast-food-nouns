/**
GOAL:
Create a FastFoodDAO.sol contract to enable permanent, 24 hour voting cycles,
automated deployments for newly submitted designs, and establish a source of
funding. Inspired by the 24-hour auction cycle of OG Nouns, we will create a
completely automated and on-chain design curation and deployment process. One
new design, every day, forever. In this contract we would:
  1. Enable anybody in the world with an Ethereum address to submit new design
     proposals, without permission.
  2. Enable all Fast Foodies to try on the new designs, and vote yay or nay on
     each design once per day.
  3. Automatically select the winner every day (assuming we have submissions)
     and deploy them automatically to the Fast Food Nouns contract (assuming we
     have gas funds). Submissions that weren't selected can roll over the next
     day for N days. 
  4. Enable individuals or brands who would like to bypass the voting to pay to
     deploy their own personal designs (with some simple rules established and
     enforced by the DAO). Payment price to be established by the DAO, will go to
     the DAO treasury, and will be used to ensure the longevity of the system by
     providing additional gas money.
  5. Enable the DAO to bypass the voting process and add new designs at will,
     and to block or veto designs that violate the simple rules established.
*/

contract FastFoodDAO is Ownable {

  // define Submission object
  struct Submission {
    address artist;
    // is RLE encoding fine size-wise, or do we hash the RLE encoding to shrink?
    string svgHash;
    uint256 yays; // todo: research how to maket his gasless, not state based
    uint256 nays;
  }

  // establish an array of submissions
  Submission[] public submissions;

  // let anybody submit a design
  function submitDesign(string calldata svgHash) {
    // todo: require that this artist hasn't submitted a design today
    Submission newSub = Submission({
      artist: msg.sender,
      svgHash: svgHash,
      yays: 0,
      nays: 0
    });
    submissions.push(Submission);
  }

  // manage votes
  // https://yos.io/2018/11/16/ethereum-signatures/
  // we should try to do this off chain most likely, so it's gasless
  // or do we do snapshot.org integration?
  // https://docs.snapshot.org/graphql-api#proposals



}