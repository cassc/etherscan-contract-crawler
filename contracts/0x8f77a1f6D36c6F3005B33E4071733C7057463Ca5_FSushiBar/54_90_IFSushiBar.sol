// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./IFSushiRestaurant.sol";

interface IFSushiBar is IFSushiRestaurant {
    error Bankrupt();
    error InvalidDuration();
    error InvalidAccount();
    error NotEnoughBalance();
    error WithdrawalDenied();

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Deposit(address indexed sender, address indexed beneficiary, uint256 shares, uint256 assets);
    event Withdraw(address indexed owner, address indexed beneficiary, uint256 shares, uint256 assets, uint256 yield);

    function asset() external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function previewDeposit(uint256 assets, uint256 _weeks) external view returns (uint256 shares);

    function previewWithdraw(address owner)
        external
        view
        returns (
            uint256 shares,
            uint256 assets,
            uint256 yield
        );

    function depositSigned(
        uint256 assets,
        uint256 _weeks,
        address receiver,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256);

    function deposit(
        uint256 assets,
        uint256 _weeks,
        address receiver
    ) external returns (uint256);

    function withdraw(address beneficiary)
        external
        returns (
            uint256 shares,
            uint256 assets,
            uint256 yield
        );
}