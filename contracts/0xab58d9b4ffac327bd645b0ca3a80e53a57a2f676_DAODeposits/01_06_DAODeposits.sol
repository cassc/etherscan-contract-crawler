//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DAODeposits is Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    address private wallet = address(0x8A72c401649A23DE311b8108ec7962979689d083);
    uint256 private totalRaised;

    //ETH Received event
    event ETHReceived(address indexed from, uint256 value);

    constructor() {
        transferOwnership(msg.sender);
    }

    //ETH Receiver
    receive() external payable {
        processPayment();
    }

    function processPayment() internal {
        totalRaised += msg.value;
        emit ETHReceived( msg.sender, msg.value );
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address( this ).balance;
        
        payable( wallet ).transfer( _balance );
    }

    function setWallet(address _newWallet) public onlyOwner {
        wallet = _newWallet;
    }
    
    function getTotalRaised() external view onlyOwner returns (uint256){
        return totalRaised;
    }
    
}