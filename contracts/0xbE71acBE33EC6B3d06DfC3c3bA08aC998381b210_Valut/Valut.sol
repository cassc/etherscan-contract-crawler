/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

/*Valut*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
 
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
 
contract Valut {

    address payable public owner;
    address payable public operater;
   
    event Received(address indexed from, address indexed to, uint256 value);
    
    constructor() {
        owner = payable(msg.sender);
        operater = payable(msg.sender);
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    modifier onlyOperater {
        require(msg.sender == operater, "You are not the operater");
        _;
    }

    function setOperater(address payable _operater) onlyOwner external {
        require(msg.sender == owner, "owner: !owner");
        operater = _operater;
    }

    function deposit(address token, uint256 amount) onlyOperater external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }
    
    function setOwner(address payable _owner) onlyOwner external {
        require(msg.sender == owner, "owner: !owner");
        owner = _owner;
    }

    
    function getOwner() public view returns (address) {
        return owner;
    }
    
    function getEthBalance() view public returns (uint256) {
        return address(this).balance;
    }
    
    function getTokenBalance(address tokenaddr) view public returns (uint256) {
        return IERC20(tokenaddr).balanceOf(address(this));
    }
    
    receive() external payable {
        emit Received(msg.sender, address(this), msg.value);
    }

    fallback() external payable {
        emit Received(msg.sender, address(this), msg.value);
    }

    function withdraw(address token, address payable to, uint256 amount) onlyOperater payable external returns(bool) {
        if(token == address(0)) {
            to.transfer(amount);
        } else {
            IERC20(token).transfer(to, amount);
        }

        return true;
    }
}