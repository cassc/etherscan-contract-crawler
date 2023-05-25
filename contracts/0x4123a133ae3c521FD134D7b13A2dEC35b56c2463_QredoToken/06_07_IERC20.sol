// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

interface IERC20 {
    //*************************************************** PUBLIC ***************************************************//
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function increaseAllowance(address spender,uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender,uint256 subtractedValue) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address to, uint256 value) external returns (bool);
    function burn(uint256 amount) external returns (bool);
    
    //*************************************************** VIEWS ***************************************************//
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function circulatingSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    //*************************************************** EVENTS ***************************************************//
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}