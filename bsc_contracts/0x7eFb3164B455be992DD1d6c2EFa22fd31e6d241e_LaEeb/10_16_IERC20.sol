// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IERC20 代币协议规范
interface IERC20 {
    // 代币精度，即小数位有多少位
    function decimals() external view returns (uint8);

    // 代币符号
    function symbol() external view returns (string memory);

    // 代币名称
    function name() external view returns (string memory);

    // 代币发行的总量
    function totalSupply() external view returns (uint256);

    // 指定账户地址的代币余额
    function balanceOf(address account) external view returns (uint256);

    // 转账，代币拥有者主动把自己的代币转给别人
    function transfer(address recipient, uint256 amount) external returns (bool);

    // 授权额度，某个账户地址授权给使用者使用自己代币的额度，一般是授权给智能合约，让智能合约划转自己的资产
    function allowance(address owner, address spender) external view returns (uint256);

    // 授权，将自己的代币资产授权给其他人使用，一般是授权给智能合约
    function approve(address spender, uint256 amount) external returns (bool);

    // 转账，将指定账号地址的代币转给指定的接收地址，一般是智能合约调用，需配合授权方法使用
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // 转账事件
    event Transfer(address indexed from, address indexed to, uint256 value);

    // 授权事件
    event Approval(address indexed owner, address indexed spender, uint256 value);
}