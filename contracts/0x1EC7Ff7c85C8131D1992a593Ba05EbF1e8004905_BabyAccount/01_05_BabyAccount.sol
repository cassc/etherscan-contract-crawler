// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "hardhat/console.sol";

contract BabyAccount is Ownable, ReentrancyGuard { 


    // some mapping to manage who sent us monies ..
    mapping (address =>  uint256) babyFriends;

    /**
    * Current custodian can withdraw the funds
     */
    function withdraw(uint256 amount) payable external nonReentrant onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    /**
    * Anyone can deposit funds
    */
    function deposit() external payable {
        babyFriends[msg.sender] =   babyFriends[msg.sender] + msg.value;
        emit ContributionMade(msg.sender, address(this).balance);
    }

    /**
    * Custodian can check account balance
    */
    function getBalance() external view  returns (uint256) {
        return address(this).balance;
    }

    /**
    * Anyone can check their contribution
    */
    function getMyContribution() external view returns (uint256) {

        return babyFriends[msg.sender];
    }

    event ContributionMade(address from, uint256 amount);

}