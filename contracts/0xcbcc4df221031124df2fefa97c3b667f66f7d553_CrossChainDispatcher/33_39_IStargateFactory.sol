// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IStargateFactory {
    function getPool(uint256 _id) external view returns (address _pool);
}