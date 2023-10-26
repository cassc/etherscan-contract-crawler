//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC20Metadata as IERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../dependencies/IWETH9.sol";

interface IVaultErrors {

    error ZeroAmount();
    error UnsupportedToken(IERC20 token);
    error NotEnoughBalance(IERC20 token, uint256 balance, uint256 requested);

}

interface IVault is IVaultErrors {

    function nativeToken() external view returns (IWETH9);

    function isTokenSupported(IERC20 token) external view returns (bool);

    function setTokenSupport(IERC20 token, bool isSupported) external;

    function balanceOf(IERC20 token, address owner) external view returns (uint256);

    function totalBalanceOf(IERC20 token) external view returns (uint256);

    function deposit(IERC20 token, address account, uint256 amount) external returns (uint256);

    function depositTo(IERC20 token, address account, uint256 amount) external returns (uint256);

    function depositNative(address account) external payable returns (uint256);

    function withdraw(IERC20 token, address account, uint256 amount, address to) external returns (uint256);

    function withdrawNative(address account, uint256 amount, address to) external returns (uint256);

}