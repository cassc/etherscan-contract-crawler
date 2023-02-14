// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity >=0.8.0;

import "../Errors.sol";

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Clober (https://github.com/clober-dex/core/blob/main/contracts/utils/ReentrancyGuard.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 internal _locked = 1;

    modifier nonReentrant() virtual {
        if (_locked != 1) {
            revert Errors.CloberError(Errors.REENTRANCY);
        }

        _locked = 2;

        _;

        _locked = 1;
    }
}