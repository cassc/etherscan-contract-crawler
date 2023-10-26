// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Tradable.sol";

/**
 * @title CryptoCardsClub
 * CryptoCardsClub - a contract for Creature Accessory semi-fungible tokens.
 */
contract CryptoCardsClub is ERC1155Tradable {
    constructor(address _proxyRegistryAddress)
        ERC1155Tradable(
            "CryptoCards Club",
            "CCC",
            "",
            _proxyRegistryAddress
        ) {}
}