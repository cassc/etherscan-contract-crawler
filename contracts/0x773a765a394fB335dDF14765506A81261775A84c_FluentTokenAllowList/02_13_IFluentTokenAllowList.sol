// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

interface IFluentTokenAllowList {
    function addAllowList(address addr) external;

    function removeFromAllowList(address addr) external;

    function checkAllowList(address _addr) external view returns (bool);

    function transferErc20Token(
        address contractFrom,
        address to,
        address erc20Addr,
        uint256 amount
    ) external;

    function transferErc20(
        address to,
        address erc20Addr,
        uint256 amount
    ) external;
}