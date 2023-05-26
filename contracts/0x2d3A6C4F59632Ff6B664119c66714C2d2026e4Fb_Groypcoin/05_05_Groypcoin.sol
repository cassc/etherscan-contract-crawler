/** 
   Groypercoin ($GROYPER) refers to a fatter illustration of Pepe the Frog resting his chin on interlinked hands, variations of which are commonly used as profile avatars.
   https://groypcoin.com

    Clean & Simple
    No Taxes, No Reserved, Fair Launch.

    SAFU & Memeable
    95% of the tokens were sent to the liquidity pool, LP tokens were locked for 4 years, then extended for 25,772 years. The contract is renounced.

    Transparent & Trackable
    The remaining 5% of the supply is being held in a multi-sig wallet only to be used as tokens for future centralized exchange listings, bridges, and liquidity pools. This wallet is easily trackable with the ENS name "groypercexwallet.eth"
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Groypcoin is ERC20 {
    constructor() ERC20("Groypcoin", "GROYPER") {
        _mint(msg.sender, 29998559671349 * 10 ** decimals());
    }
}