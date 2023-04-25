// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";


contract Airdrop is Ownable{

     uint public dropFee = 0;
     address payable public administratorAddress;

    function changeAdminAddress(address payable _administratorAddress) public onlyOwner{
            administratorAddress = _administratorAddress;
    }
   
    function airdrop( address  tokenAddress,address[] calldata _recipients, uint256[] calldata _amount) public {
       sendDropFee();
       IBEP20 airdropToken = IBEP20(tokenAddress);
        require(_recipients.length == _amount.length, "The number of recipients is not equal to the number of values");
        for (uint i = 0; i < _amount.length; i++) {
            airdropToken.transferFrom(msg.sender, _recipients[i], _amount[i]);
        }
        
    }
    
    function sendDropFee() payable public{
        administratorAddress.transfer(dropFee);
    }

    function changeAirdropFee(uint _dropFee) public onlyOwner{
                dropFee = _dropFee;
    }
    
} 

interface IBEP20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}