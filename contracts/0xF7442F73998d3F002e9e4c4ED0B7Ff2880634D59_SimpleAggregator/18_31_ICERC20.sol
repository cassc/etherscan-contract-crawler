//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ICompoundController.sol";

interface ICERC20 is IERC20 {
    function comptroller() external view returns (ICompoundController);

    function exchangeRateCurrent() external returns (uint);

    function balanceOfUnderlying(address account) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function mint() external payable;

    function mint(uint256 amount) external returns (uint256);

    function redeem(uint256 amount) external returns (uint256);

    function redeemUnderlying(uint redeemAmount) external returns (uint);

    function borrow(uint256 amount) external returns (uint256);

    function repayBorrow() external payable returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);
}