// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./IPool.sol";

interface IFactory {
   function getPool(uint256 poolId) external view returns(IPool); 
}