// SPDX-License-Identifier: MIT

/*
You wouldn't find the website here 
You wouldn't find twitter account
(However, You can make one if you want)

                    THE TRUE CRINGE STORY

And now the assignment folks:
    1. Post memes with any CRINGE you experienced to twitter with your wallet address
    2. Fill the whole twitter with $CRINGE tags 
        2.1 maybe worth mentioning the CRINGE ERC-20 address
    3. The most liked tweet will get some $CRINGE from the Deployer

Just some basic requirements here, you can go full degen mode here and do whatever you want 
#PEPEKILLER, mhm, what do you think?

And now listen, some sanity checks, yeah?
CRINGE ERC-20 ADDRESS: 0x1234523F9BB788eA7b29Fe2A46d2eeE2e25B917C
CRINGE DEPLOYER: 0x69090aecA9A86d93af3416dB94D11083FC5855c9

*/

pragma solidity ^0.8.9;
// What we see here?
// OpenZeppelin audited ERC20 smart contract
import "./ERC20.sol";

// Not ownable smart contract, nobody can change it
contract Cringe is ERC20 {
    constructor() ERC20("Cringe", "CRINGE") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}