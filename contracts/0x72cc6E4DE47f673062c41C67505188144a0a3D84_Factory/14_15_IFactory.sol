//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IFactory {
    function getDaos() external view returns (address[] memory);

    function shop() external view returns (address);

    function monthlyCost() external view returns (uint256);

    function subscriptions(address _dao) external view returns (uint256);

    function containsDao(address _dao) external view returns (bool);
}