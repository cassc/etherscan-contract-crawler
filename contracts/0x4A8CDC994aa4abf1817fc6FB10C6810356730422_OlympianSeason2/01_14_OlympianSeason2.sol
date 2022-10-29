// SPDX-License-Identifier: MIT

/// @title Olympian - Season 2 by Rich Caldwell
/// @author transientlabs.xyz

pragma solidity 0.8.14;

import "ERC721TLCreator.sol";

contract OlympianSeason2 is ERC721TLCreator {

    constructor(address _royaltyRecipient, uint256 _royaltyPercentage, address _admin)
    ERC721TLCreator("Olympian - Season 2", "OLYMP", _royaltyRecipient, _royaltyPercentage, _admin)
    {}
}