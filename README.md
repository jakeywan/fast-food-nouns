# @nouns/contracts

## Basic Architecture

We're deploying our own version of NounsToken with adjustments to convert the
release mechanism and remove the DAO/auction functions.

We're also releasing our own version of NounsDescriptor. HOWEVER, in order to avoid
having to repopulate the Descriptor with asset parts from the encoded-files.json
file, we're going to reference the live NounsDescriptor to pull in parts. PLUS
the descriptor will add a function which will layer in our new hat. Then this will
get sent out to the NFTDescriptor (which is live, we can use the same one from Nouns)
to build and compose the SVG and give us back a uri.

This means we'll need to encoded our hat image with RLE encoding. See link below
for the script. This means that we'll have a:

1. Custom NounsToken contract
2. Custom NounsDescriptor contract (but with minimal modifications)

The only other dependency is the NFTDescriptor, and we can use the live one for
that.


### Nouns Contracts
https://github.com/nounsDAO/nouns-monorepo/blob/soli-nouns-sdk/packages/nouns-sdk/src/contract/addresses.ts#L16-L27

### Good info on Nouns rendering
https://nouns.notion.site/Noun-Protocol-32e4f0bf74fe433e927e2ea35e52a507#f7d579663e65480193e182355a29af63

### For RLE encoding svgs
https://github.com/nounsDAO/nouns-monorepo/tree/soli-nouns-sdk/packages/nouns-assets