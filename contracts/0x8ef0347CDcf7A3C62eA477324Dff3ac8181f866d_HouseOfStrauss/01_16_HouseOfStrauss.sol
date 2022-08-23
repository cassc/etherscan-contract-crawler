// SPDX-License-Identifier: MIT

/// @title House of Strauss
/// @author Ben Strauss
/// @notice welcome home

pragma solidity 0.8.14;

import "ERC1155TLCore.sol";

contract HouseOfStrauss is ERC1155TLCore {

    constructor(address admin, address payout) ERC1155TLCore(admin, payout, "House of Strauss") {}
}