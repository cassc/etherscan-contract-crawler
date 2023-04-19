/**
 *Submitted for verification at BscScan.com on 2023-04-18
*/

//SPDX-License-Identifier: UNLICENSED

//This contract takes a deposit amount of eth and records a destination address for that amount. 
//The list of destinations and amounts go from 0 to trnsfNo. 0 being the first deposit. 
//Call wipeTrnsfQueue after the transfers have been processed. 
pragma solidity 0.8.17;

interface ERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function transfer(address dst, uint wad) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

contract TUNNELBANAN_deposits {

mapping(uint => address) public recipients;
mapping(uint => uint) public amounts;
uint public trnsfNo = 0;
mapping(address => bool) public isOwner;

constructor() {
    isOwner[msg.sender] = true;
}

modifier onlyOwner{
    require(isOwner[msg.sender] = true);_;
}

    function addOwner(address newOwner) public onlyOwner{
        isOwner[newOwner] = true;
    }

    function depositToTrnsfQueue(uint amount, address recipient) public payable{
        recipients[trnsfNo] = recipient;
        amounts[trnsfNo] = amount;
        trnsfNo += 1;
    }

    function wipeTrnsfQueue() public onlyOwner{
        trnsfNo = 0;
    }

    function withdrawETH(address dst) public onlyOwner{
        uint contractBalance = address(this).balance;
        payable(dst).transfer(contractBalance);
    }

    function withdrawTokens(address token) public onlyOwner{
        ERC20 TOKEN = ERC20(token);
        uint contractBalance = TOKEN.balanceOf(address(this));
        TOKEN.transfer(msg.sender, contractBalance);
    }

    receive() external payable {}
    fallback() external payable {}

}