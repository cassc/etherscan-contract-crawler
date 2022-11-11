// SPDX-License-Identifier: MIT
pragma solidity 0.8.16; 
interface IOracle {
    function getNFTPrice(uint256 _price) external view returns(uint256);
    function setRouter(address _router) external;
    function setUSDPair(address _usd) external;
}