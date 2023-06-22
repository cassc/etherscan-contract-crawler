// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMonsterStaking {
    function getAllStakedBalances(address _address) external view returns (uint256[7] memory);
}