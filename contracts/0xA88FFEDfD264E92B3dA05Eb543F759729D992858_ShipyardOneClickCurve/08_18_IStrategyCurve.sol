// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IStrategy.sol";

interface IStrategyCurve is IStrategy {

    function pool() external view returns (address);
    function poolSize() external view returns (uint256);
    function preferredUnderlyingToken() external returns (address) ;
    function underlyingToken(address _tokenAddress) external returns (bool);
    function underlyingTokenIndex(address _tokenAddress) external returns (uint256);
}