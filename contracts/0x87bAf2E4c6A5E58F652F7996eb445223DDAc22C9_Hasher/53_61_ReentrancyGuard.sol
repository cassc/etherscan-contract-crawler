// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private _locked = 1;

    modifier nonReentrant() virtual {
        require(_locked == 1, "REENTRANCY");

        _locked = 2;

        _;

        _locked = 1;
    }
}