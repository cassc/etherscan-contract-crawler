// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//import "./polarsubscription.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Referral is Ownable {


    IERC20 public frost; //THIS IS THE TOKEN THAT IS REQUIRED FOR Withdrawal

    struct Referrer {
        uint balance;
        bool isBlacklisted;
    }

    mapping (address => Referrer) public referralDB;
    uint public referralValue = 4*10**18; //standard amount, can be changed with setter
    uint public referralRate = 24*10**18;   // standard amount, can be changed with setter


    function _refer(address referral) internal {
        referralDB[referral].balance += referralValue/(10**18);
    }

    function _verifyUser() internal view {
        require(referralDB[msg.sender].balance != 0, "You do not have referral Balance");
        require(referralDB[msg.sender].isBlacklisted == false, "This wallet is blacklisted. Request support");
    }


    //getters
    function getBalance()public view returns(uint){
        return referralDB[msg.sender].balance;
    }

    //setters
    function setRefferal(uint newReferral) external onlyOwner{
        referralValue = newReferral*10**18;
    }

    function setReferralRate(uint _newRate)external onlyOwner{
        referralRate = _newRate*10**18;
    }

    function setBlacklist(address _address)external onlyOwner{
        referralDB[_address].isBlacklisted = true;
    }

    function setFrostAddress(address _frost)external onlyOwner{
        frost = IERC20(_frost);
    }


}