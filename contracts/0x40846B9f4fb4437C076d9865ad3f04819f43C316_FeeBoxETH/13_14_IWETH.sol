// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IWETH {
    function allowance(address, address) external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function decimals() external view returns (uint8);

    function deposit() external payable;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function withdraw(uint256 wad) external;
}