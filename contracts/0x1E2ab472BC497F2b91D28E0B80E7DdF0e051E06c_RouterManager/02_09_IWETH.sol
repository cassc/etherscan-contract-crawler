// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function totalSupply() external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function decimals() external returns (uint8);

     function balanceOf(address account) external view returns (uint256);
}