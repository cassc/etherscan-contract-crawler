// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**

$UNIVERSE (Unicorn Metaverse) is a utility bridge between Rarity Garden and The Otherside Metaverse.

Rarity Garden aims at offering a one-stop shop for tools that help you to succeed on The Otherside.

For more information, see below.

Website: https://rarity.garden/
Twitter: https://twitter.com/rarity_garden
Discord: https://discord.gg/Ur8XGaurSd

*/
contract UnicornMetaverse is ERC20 {

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) ERC20(name, symbol) {
        _mint(owner, initialSupply);
    }
}