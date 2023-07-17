// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

interface ITreasury {

    event Withdraw(address indexed asset, address indexed recipient, uint256 amount, address indexed sender);
    event Relinquish(address indexed asset, uint256 amount, address indexed sender);
    event Deposit(address indexed asset, uint256 amount, address indexed sender);
    event Loss(address indexed asset, uint256 amount, address indexed sender);
    event Skim(address indexed asset, uint256 amount, address indexed recipient, address indexed sender);

    function roleOf(address asset) external pure returns (bytes32);
    function reserves(address asset) external view returns (uint256);
    function balanceOf(address asset) external view returns (uint256);

    function withdraw(address asset, address recipient, uint256 amount) external returns (uint256 reserves);
    function relinquish(address asset, uint256 amount) external returns (uint256 reserves);

    function sync(address asset, uint256 maxToSync) external returns (uint256 received);
    function syncAndWithdraw(address asset, address recipient, uint256 amount, uint256 maxToSync) external returns (uint256 reserves_, uint256 received);

    function skim(address asset, address recipient) external returns (uint256 sent);
}