// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;
import "../interfaces/ReentrancyErrors.sol";
import "../storage/ReentrancyGuardStorage.sol";

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard is ReentrancyGuardStorage, ReentrancyErrors {
  function _initialize() internal virtual {
    locked = 1;
  }

  modifier nonReentrant() virtual {
    if (locked != 1) {
      revert Reentrancy();
    }

    locked = 2;
    _;
    locked = 1;
  }
}