// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../util/IERC721Lockable.sol";

interface IViriumId is IERC721Lockable {
    function burn(uint256[] memory tokenIds) external;

    function softMint() external returns (uint256[] memory);
}