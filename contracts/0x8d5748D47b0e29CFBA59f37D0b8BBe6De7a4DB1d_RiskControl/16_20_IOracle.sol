// contracts/Project.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {

    function getPrice() external view returns(uint256);

}