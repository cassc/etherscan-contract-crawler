// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "./ISpendable.sol";

interface IScales is ISpendable {
    function getAllOwned(address) external view returns (uint256[] memory);
}