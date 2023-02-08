// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SafeMath.sol";

interface Gold_BlockChain
{
    function balanceOf(address user) external view returns(uint);
    function transferFrom(address _from, address _to, uint _value) external returns(bool);
}

contract Gold_BlockChain_MasterV2{
    using SafeMath for uint;
    Gold_BlockChain public GBCtoken;

    struct Deposit {
        uint amount ;
        uint timestamp;
    }

    struct  User {
        uint tolalAmount;
        uint withdrawan;
        Deposit [] deposit;
    }

     modifier onlyAdmin() {
        require(msg.sender == admin,"no acess");
        _;
    }


    bool public started;
    bool private IsInitinalized;
    address payable public admin;
    uint public tokenPrice;
    mapping (address => User)  public userdata;

    function initialize(address payable _admin, Gold_BlockChain _tokenAddress) external{
        require(IsInitinalized ==false);
        admin = _admin;
        GBCtoken = _tokenAddress;
        tokenPrice = 1e8;
        IsInitinalized = true ;
    }


   

    function deposit (uint _amount) public {
        User storage user = userdata[msg.sender];
       uint balance = GBCtoken.balanceOf(msg.sender);
       require(balance>=_amount,"Insufficant funds");
       user.tolalAmount = user.tolalAmount.add(_amount);
       user.deposit.push(Deposit(_amount,block.timestamp));
       GBCtoken.transferFrom(msg.sender, admin, _amount);       
    }

    function checkBalance(address _user) public view returns(uint){
        uint balance = GBCtoken.balanceOf(_user);
        return balance;
    }




    function getDepositLength(address _useraddress) public view returns(uint){
        User storage u = userdata[_useraddress] ;
        return u.deposit.length;
    }


    function getDeposit(uint _index ,address _useraddress) public view returns(uint,uint){
        User storage u = userdata[_useraddress] ;
        return (u.deposit[_index].amount,u.deposit[_index].timestamp);
    } 
       
}