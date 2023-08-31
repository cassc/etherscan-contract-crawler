// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Modified Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private reentrancyStatus;

    error Reentrancy();

    function __initReentrancyGuard() internal {
        if (reentrancyStatus != 0) revert Reentrancy();
        reentrancyStatus = 1;
    }

    modifier nonReentrant() {
        if (reentrancyStatus != 1) revert Reentrancy();

        reentrancyStatus = 2;

        _;

        reentrancyStatus = 1;
    }
}