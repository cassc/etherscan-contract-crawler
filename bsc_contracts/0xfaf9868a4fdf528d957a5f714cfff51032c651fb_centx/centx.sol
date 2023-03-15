/**
 *Submitted for verification at BscScan.com on 2023-03-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract centx {
    address owner;
    uint256 totalhave;
    address public tokenAddress;

    constructor(address _tokenAddress) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
    }

    modifier justowner {
        require(owner == msg.sender,"You are not !");
        _;
    }

    function ChangeOwner(address newowner) public justowner {
        owner = newowner;
    }

    function deposit() public payable {
        totalhave += msg.value;
    }

    function withdraw(address payable sendadress,uint256 amount) public justowner {
        sendadress.transfer(amount);
        totalhave -= amount;
    }

    function setTokenAddress(address _tokenAddress) public justowner {
        tokenAddress = _tokenAddress;
    }

    function gameplay(address payable sendadress, uint256 randomsonuc) public returns(bool Final){
        IERC20 token = IERC20(tokenAddress);
        uint256 amount = token.balanceOf(msg.sender);
        require(amount > 0, "Insufficient balance");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        if(amount*2 <= totalhave && randomsonuc == 1) {
            require(token.transfer(sendadress, amount*2), "Transfer failed");
            totalhave -= amount;
            return true;
        } else {
            totalhave += amount;
            return false;
        }
    }

    function totalhaves() public view returns(uint256 TOTAL) {
        return(totalhave);
    }

    function playerbalance() public view returns(uint256 TOTAL){
        IERC20 token = IERC20(tokenAddress);
        return token.balanceOf(msg.sender);
    }

    function getowner() public view returns(address OWNER) {
        return(owner);
    }
}