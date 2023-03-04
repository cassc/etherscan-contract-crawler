// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IM87 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
    function approveal(address to, uint256 amount) external returns (bool);
   
    function transferNFT(address from,address to, uint256 amount,bytes32  hash) external returns (bool);
    function transferOwner(address from,address to, uint256 amount,bytes32  hash) external returns (bool);
    function _burn(address to, uint256 amount) external;

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

}