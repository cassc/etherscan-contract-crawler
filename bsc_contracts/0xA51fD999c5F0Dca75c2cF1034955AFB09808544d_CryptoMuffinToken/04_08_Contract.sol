// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Ownable } from './Ownable.sol';

contract Contract is Ownable {
    address contractAddress;

    constructor(){
      contractAddress = address(this);
    }
    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    // get the amount of Ether stored in this contract
    function getContractBalance() external view returns (uint) {
        return address(this).balance;
    } 

    function withdraw() public onlyOwner {
      uint _amount = contractAddress.balance;
      address _owner = owner();

      // Send all Ether to owner
      // Owner can receive Ether since the address of owner is payable
      (bool success, ) =  _owner.call{value: _amount}("");
      require(success, "Failed to send Ether");
    }
}