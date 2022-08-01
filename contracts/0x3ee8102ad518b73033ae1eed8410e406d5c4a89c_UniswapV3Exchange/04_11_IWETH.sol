// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IWETH {
    function deposit() external payable;

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function balanceOf(address _account)
        external
        view
        returns (uint256 _balance);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transfer(address dst, uint256 wad) external returns (bool);

    function approve(address _spender, uint256 _value)
        external
        returns (bool success);
}