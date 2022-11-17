// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IAToken {
    function balanceOf(address _user) external view returns (uint256);

    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    function POOL() external view returns (address);

    function transfer(address to, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function decimals() external view returns (uint256);
}