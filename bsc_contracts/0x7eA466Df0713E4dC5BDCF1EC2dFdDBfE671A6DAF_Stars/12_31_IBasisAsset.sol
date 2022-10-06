// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IBasisAsset {
    function mint(address recipient, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function owner() external view returns (address);

    function operator() external view returns (address);

    function transferOperator(address newOperator_) external;

    function balanceOf(address user) external view returns (uint256 balance);

    function approve(address to, uint256 amount) external;

    function allowance(address sender, address spender)
        external
        view
        returns (uint256);

    function transfer(address sender, uint256 amount) external;

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool authorized);
}