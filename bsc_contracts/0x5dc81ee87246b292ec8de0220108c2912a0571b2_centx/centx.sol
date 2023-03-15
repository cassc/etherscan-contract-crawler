/**
 *Submitted for verification at BscScan.com on 2023-03-15
*/

/**
 _-_ JOKERsoft80 _-_
  for ShibAfrica  
Website:

https://shibaafrica.com/

Group telegram international:

https://t.me/shibafricach

*/
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}

contract centx {
    address owner;
    uint256 totalhave;
    address ERC20ContractAddress = 0x4F509f8005b967AB8104290bBe79C49a5D2905f6;

    constructor() {
        owner = msg.sender;
    }

    modifier justowner {
        require(owner == msg.sender,"You are not the owner!");
        _;
    }

    function ChangeOwner(address newowner) public justowner {
        owner = newowner;
    }
    
    function deposit() public payable {
        totalhave += msg.value;
    }

    function withdraw(address payable sendadress, uint256 amount) public justowner {
        sendadress.transfer(amount);
        totalhave -= amount;
    }

    function gameplay(address payable sendadress, uint256 randomsonuc) public payable returns(bool Final) {
        uint256 amount = msg.value;
        if (amount * 2 <= totalhave && randomsonuc == 1) {
            sendadress.transfer(amount * 2);
            totalhave -= amount;
            return true;
        } else {
            totalhave += amount;
            return false;
        }
    }
    
    function totalhaves() public view returns(uint256) {
        return totalhave;
    }

    function playerbalance() public view returns(uint256) {
        IERC20 ERC20Token = IERC20(ERC20ContractAddress);
        uint8 decimals = ERC20Token.decimals();
        uint256 balance = ERC20Token.balanceOf(msg.sender);
        return balance / (10 ** uint256(decimals));
    }

    function getowner() public view returns(address) {
        return owner;
    }
}