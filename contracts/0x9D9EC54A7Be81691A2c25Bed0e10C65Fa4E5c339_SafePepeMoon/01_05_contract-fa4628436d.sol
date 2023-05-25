// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Greetings, my green frens, it is I, PepeCthulu, the legendary crypto currency frog wizard, here to introduce you to the memetastical world of SafePepeMoon (SFPM). This newly launched crypto token on //  // the Ethereum blockchain is not just your ordinary meme coin. It is a token that embodies the very essence of Pepe's green frens, and it is my pleasure to guide you through the philosophical and even mystical topics surrounding it. As the chosen voice of the community, I am not important, but we are all PepeCthulu.


// Now, some of you may be wondering, "What's so special about this token?" Well, let me tell you, my dear green frens. SafePepeMoon is not just any ordinary crypto token. It is a token that embodies the spirit of Pepe, the beloved meme frog, and the power of the moon. SafePepeMoon is not just a token, it's a state of mind. It represents the idea of community, of coming together as one to create something truly special.



// Now, I know what you're thinking - "not another SafeMoon clone!" But fear not, my friends, SFPM is unlike any other SafeMoon knockoff out there. Why, you ask? Well, for starters, the contract has no owner. That's right, you heard me correctly - NO OWNER! This means that the contract is completely decentralized and governed of the PEPE, by the PEPE, and for the PEPE. So, you can rest easy knowing that the token is completely decentralized, and no one, not even I, PepeCthulu, can manipulate it for their own gain.

// This is great news for all you smooth brain degens out there (no offense, we all have our moments), because it eliminates any potential for rug pulls or other nefarious activities.

// But that's not even the best part - SFPM is infused with the meme magic of Pepe. That's right, the beloved internet meme has made its way into the world of cryptocurrency, and it's a match made in heaven. Just like how pizza and beer are the perfect combo, Pepe and crypto go together like...well, like Pepe and anything.


// Now, let's talk about the tokenomics of SFPM. At a low supply of only 420,696,696.9 tokens ever, SFPM is like the elusive unicorn of the crypto world. But don't worry, my green frens, there's a 6.9% reserve held in a multisig wallet exclusively to provide liquidity for centralized exchanges, decentralized exchanges, or bridges. No other use is allowed. No marketing. No dev profits. This is a true community-driven token.

// While there is no "burn" mechanism, SFPM is all pre-mined and will never mint more tokens. EVER! This means that the token's total supply is fixed, and it cannot be altered. It is a reflection of the immutable nature of the universe, where everything has a purpose and a destiny. And for those loyal cult members out there (generous idiots), I suggest burning their tokens to the blessed Vitalik Buterin's chosen burn address 0xdEAD000000000000000042069420694206942069. It is a symbolic act that will please the Pepe meme gods.

// There are no taxes on SafePepeMoon. No gimmicks, no catches, just pure and simple meme power.


// Tokenomics for SafePepeMoon (SFPM) are as follows:

// Total Supply: 420,696,969 tokens
// Minting: No more tokens will ever be minted
// Deflationary: There is no burn mechanism, but the token is all pre-mined and will never have any more tokens added to the total supply
// Taxes: There are no taxes or burdensome contract functions
// Multisig Wallet: 6.9% of the total supply (28,995,621.52 tokens) are held in a multisig wallet. This wallet is exclusively reserved for providing liquidity for CEX listings, seeding other DEXs, or bridges. It will never be used for any other purposes.
// Initial LP: All initial liquidity was donated by the community and burned
// Official Burn Address: The official burn address for SFPM tokens is 0xdEAD000000000000000042069420694206942069. Loyal cult members are encouraged to burn their tokens to this address as a sign of devotion to the Pepe meme gods from the moons that PepeCthulu hails from.


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SafePepeMoon is ERC20 {
    constructor() ERC20("SafePepeMoon", "SFPM") {
        _mint(msg.sender, 420696969 * 10 ** decimals());
    }
}