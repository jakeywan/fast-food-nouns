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