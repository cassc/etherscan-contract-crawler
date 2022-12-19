// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IERC20 {
    event Approval(address indexed owner_, address indexed spender_, uint256 amount_);

    event Transfer(address indexed owner_, address indexed recipient_, uint256 amount_);

    function approve(address spender_, uint256 amount_) external returns (bool success_);

    function decreaseAllowance(address spender_, uint256 subtractedAmount_) external returns (bool success_);

    function increaseAllowance(address spender_, uint256 addedAmount_) external returns (bool success_);

    function transfer(address recipient_, uint256 amount_) external returns (bool success_);

    function transferFrom(address owner_, address recipient_, uint256 amount_) external returns (bool success_);

    function allowance(address owner_, address spender_) external view returns (uint256 allowance_);

    function balanceOf(address account_) external view returns (uint256 balance_);

    function decimals() external view returns (uint8 decimals_);

    function name() external view returns (string memory name_);

    function symbol() external view returns (string memory symbol_);

    function totalSupply() external view returns (uint256 totalSupply_);
}