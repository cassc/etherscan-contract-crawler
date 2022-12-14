// SPDX-License-Identifier: MIT

/// @title Where 2 Souls Meet
/// @author Daniel Volkov
/// @notice welcome home

pragma solidity 0.8.14;

import "ERC1155TLCore.sol";

contract Where2SoulsMeet is ERC1155TLCore {

    constructor(address admin, address payout) ERC1155TLCore(admin, payout, "Where 2 Souls Meet") {}
}