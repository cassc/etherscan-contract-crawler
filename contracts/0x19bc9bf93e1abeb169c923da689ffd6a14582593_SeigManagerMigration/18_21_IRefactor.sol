// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRefactor {
  struct Balance {
        uint256 balance;
        uint256 refactoredCount;
    }

    struct Factor {
        uint256 factor;
        uint256 refactorCount;
    }
}