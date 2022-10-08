// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.11;

import "./ISpendable.sol";

interface IScales is ISpendable {
    function getAllOwned(address) external view returns (uint256[] memory);
    function claimRWaste() external;
}