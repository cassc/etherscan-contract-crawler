// SPDX-License-Identifier: MIT

/// @title Aqua by Rich Caldwell
/// @author transientlabs.xyz

pragma solidity 0.8.14;

import "ERC721TLCreator.sol";

contract Aqua is ERC721TLCreator {

    constructor(address _royaltyRecipient, uint256 _royaltyPercentage, address _admin)
    ERC721TLCreator("Aqua", "AQUA", _royaltyRecipient, _royaltyPercentage, _admin)
    {}
}