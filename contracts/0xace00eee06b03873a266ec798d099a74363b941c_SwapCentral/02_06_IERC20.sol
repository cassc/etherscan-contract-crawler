// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function transfer(address to, uint256 amount) external;

    function allowance(
        address from,
        address to,
        uint256 amount
    ) external view returns (bool);

    function approve(address sender, uint256 amount) external;

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed from, address indexed to, uint256 amount);
}