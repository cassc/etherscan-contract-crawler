// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IComplianceManager {
    function addBlockList(address addr) external;

    function removeFromBlockList(address addr) external;

    function addAllowList(address addr) external;

    function removeFromAllowList(address addr) external;

    function checkWhiteList(address _addr) external view returns (bool);

    function checkBlackList(address _addr) external view returns (bool);

    function transferErc20(
        address to,
        address erc20Addr,
        uint256 amount
    ) external;
}