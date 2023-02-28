//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

interface IPieRegistry {
    function inRegistry(address _pool) external view returns(bool);
    function entries(uint256 _index) external view returns(address);
    function addSmartPool(address _smartPool) external;
    function removeSmartPool(uint256 _index) external;
}