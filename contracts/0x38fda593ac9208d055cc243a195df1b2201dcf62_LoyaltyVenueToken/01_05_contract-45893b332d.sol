// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

/// @custom:security-contact [email protected]
contract LoyaltyVenueToken is ERC20 {
    constructor() ERC20("LoyaltyVenue Token", "LOVEU") {
        _mint(msg.sender, 400000000 * 10 ** decimals());
    }
}