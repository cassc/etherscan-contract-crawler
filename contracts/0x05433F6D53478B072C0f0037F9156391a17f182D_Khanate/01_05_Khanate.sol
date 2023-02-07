// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
* Khanate, established by The Khan of the Mongol Horde
* Khanate tokens of the Mongol Horde, reclaim your masculinity by channeling the spirit of
* of the Mongols. The great Mongol Empire was first united under one banner by the Great Khaan Chinggis, the pinnacle of
* medieval masculinity which is lacking in the world today. The Mongols were known for their flexible approach to different cultures and people absorb
* them into their ranks establishing a meritocraccy. We are not a meme, we're a creed! The Mongols back!
*/



contract Khanate is ERC20 {

/*
* Fuck your narratives & bullshit utility
* No soyboy tokenomics hoping something will pump your bags, bitch.
* Straight forward buy and sell, as straight as our holders.
* Currencies 
*/

/*
* Currencies are a unit of measurement, a means of accounting and an exchange of wealth 
* through mutually agreed units. Khanate tokens will have value solely based on 
* the consensus reached by their holders. Holders that align with the creed of men. 
* Every other coin represents false creeds, narratives and memes held by losers 
* with no real diving purpose. Through conquest and brute force, we will impose our 
* values on others. The Khanate will rise, rise forever!
*/

    constructor() ERC20("Khanate", "KHNT") {
        _mint(msg.sender, 1000000000 * 10**18);
    }


    
}