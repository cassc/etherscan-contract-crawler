// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IMagicats {

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}