// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract MCGenesisSplits {
    address[] internal addresses = [
        0xcA6ebEEB2fC3cea204e17541Bc75Ac6586AEd31c, // Project Wallet
        0x0a701C5f7063656354e5701176AeB9aB7552d30F, // Founders Wallet
        0x4474efe96982D38997B5BbF231EABB587201124E  // Dev Wallet
    ];

    uint256[] internal splits = [75, 10, 15];
}