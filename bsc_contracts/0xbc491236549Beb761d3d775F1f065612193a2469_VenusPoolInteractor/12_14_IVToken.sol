// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

interface IVToken {
    function mint(uint256 mintAmount) external returns (uint256);

    function mint() external payable;

    function mintBehalf(address receiver, uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function underlying() external view returns (address);

    function transfer(address dst, uint amount) external returns (bool);

    function transferFrom(address src, address dst, uint amount) external returns (bool);

    function approve(address spender, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function balanceOfUnderlying(address owner) external returns (uint);

    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);

    function borrowRatePerBlock() external view returns (uint);

    function supplyRatePerBlock() external view returns (uint);

    function totalBorrowsCurrent() external returns (uint);

    function borrowBalanceCurrent(address account) external returns (uint);

    function exchangeRateStored() external view returns (uint);

    function totalSupply() external view returns (uint);

    function isVToken() external view returns (bool);
}