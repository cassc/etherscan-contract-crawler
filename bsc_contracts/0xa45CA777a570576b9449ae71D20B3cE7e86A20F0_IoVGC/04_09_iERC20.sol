pragma solidity ^0.6.12;
// SPDX-License-Identifier: MIT

// This interface gives the virtual methods for IoVT and another ERC-20 (BP-20) functions.
interface iERC20 {
    function name() external view returns(string memory);
    
    function symbol() external view returns(string memory);
    
    function decimals() external view returns(uint8);
    
    function totalSupply() external view returns(uint256);

    function balanceOf(address account) external view returns(uint256);

    function transfer(address recipient, uint256 amount) external returns(bool);

    function allowance(address owner, address spender) external view returns(uint256);

    function approve(address spender, uint256 amount) external returns(bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);

    function increaseAllowance(address _spender, uint256 _addedValue) external returns(bool);

    function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns(bool);

    function changeOwner(address payable _owner) external;

    function getOwner() external view returns(address);

    function blockAccount(address _account) external;

    function unblockAccount(address _account) external;

    function isAccountBlocked(address _account) external view returns(bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

}
