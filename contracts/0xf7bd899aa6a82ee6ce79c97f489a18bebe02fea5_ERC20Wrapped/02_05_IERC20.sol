// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account_) external view returns (uint256);

    function transfer(address to_, uint256 amount_) external returns (bool);

    function allowance(address owner_, address spender_)
        external
        view
        returns (uint256);

    function approve(address spender_, uint256 amount_) external returns (bool);

    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    ) external returns (bool);
}