// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUSDT {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external;
    function approve(address spender, uint value) external;
    function transferFrom(address from, address to, uint value) external;
    function allowance(address owner, address spender) external view returns (uint);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}