// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

import 'src/interfaces/IERC2612.sol';

interface IERC5095 is IERC2612 {
    function maturity() external view returns (uint256);

    function underlying() external view returns (address);

    function convertToUnderlying(uint256) external view returns (uint256);

    function convertToShares(uint256) external view returns (uint256);

    function maxRedeem(address) external view returns (uint256);

    function previewRedeem(uint256) external view returns (uint256);

    function maxWithdraw(address) external view returns (uint256);

    function previewWithdraw(uint256) external view returns (uint256);

    function previewDeposit(uint256) external view returns (uint256);

    function withdraw(
        uint256,
        address,
        address
    ) external returns (uint256);

    function redeem(
        uint256,
        address,
        address
    ) external returns (uint256);

    function deposit(uint256, address) external returns (uint256);

    function mint(uint256, address) external returns (uint256);

    function authMint(address, uint256) external returns (bool);

    function authBurn(address, uint256) external returns (bool);

    function authApprove(
        address,
        address,
        uint256
    ) external returns (bool);
}