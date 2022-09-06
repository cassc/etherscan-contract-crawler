// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./util/IERC721ALockable.sol";

interface IViriumId is IERC721ALockable {
    function burn(uint256[] memory tokenIds) external;

    function softMint() external returns (uint256[] memory);
}