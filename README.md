# Fast Food Nouns Contract
The official Fast Food Nouns contract.

## Basic Architecture

TLDR: in the tokenURI function, fetch the base64 encoded SVG for a given Fast Food
Noun, modify it according to the user's clothing selections, and return it to the
client.

TODO: write up a more detailed explanation.


## References
### Nouns Contracts
https://github.com/nounsDAO/nouns-monorepo/blob/soli-nouns-sdk/packages/nouns-sdk/src/contract/addresses.ts#L16-L27

### Good info on Nouns rendering
https://nouns.notion.site/Noun-Protocol-32e4f0bf74fe433e927e2ea35e52a507#f7d579663e65480193e182355a29af63

### For RLE encoding svgs
https://github.com/nounsDAO/nouns-monorepo/tree/soli-nouns-sdk/packages/nouns-assets


## Notes
* For our descriptor and clothing system, we should make it such that another project
 entirely (like a future "mutants" or "babies" FFNs) could use our clothing system


 ## Contracts

Rinkeby FFNs: 0x419ccff619e671dd772c0fc7326a5c0368ea751c
Arbitrum Rinkeby Arbis Nouns: 0xc77540882c27a0cf96061B64BeE92Fe5ef4F0453
Rinkeby Oracle: 0xDB13743795C0D90306085f714b63A0A7A9bf8fC3
ArbRetryableTransaction: 0x000000000000000000000000000000000000006e

 # Example inputs for update oracle call
 .05

0

4272053229

100000

20087094