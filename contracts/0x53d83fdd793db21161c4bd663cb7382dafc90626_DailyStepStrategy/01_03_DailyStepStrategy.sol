// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IFaucetStrategy} from "./IFaucetStrategy.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title A daily step vesting strategy for faucets.
/// @author tbtstl <[email protected]>
contract DailyStepStrategy is IFaucetStrategy {
    /// @notice The total amount of token that could be claimable at a particular timestamp
    /// @param _totalAmt The total amount of token that exists in the faucet
    /// @param _faucetStart The timestamp that the faucet was created on
    /// @param _faucetExpiry The timestamp that the faucet will finish vesting on
    /// @param _timestamp The current timestamp to check against
    function claimableAtTimestamp(
        uint256 _totalAmt,
        uint256 _faucetStart,
        uint256 _faucetExpiry,
        uint256 _timestamp
    ) external view returns (uint256) {
        if (_timestamp < _faucetStart) {
            return 0;
        } else if (_timestamp >= _faucetExpiry) {
            return _totalAmt;
        } else {
            uint256 numSteps = (_faucetExpiry - _faucetStart) / (60 * 60 * 24); // number of total steps in strategy
            if (numSteps == 0) return 0; // If the duration of this faucet is less than a day, wait til expiry.
            uint256 stepMagnitude = _totalAmt / numSteps; // Size to be unlocked after each step
            uint256 currentStep = (_timestamp - _faucetStart) / (60 * 60 * 24); // The step for this timestamp

            return currentStep * stepMagnitude;
        }
    }

    function supportsInterface(bytes4 interfaceId) external view virtual override(IERC165) returns (bool) {
        return interfaceId == type(IFaucetStrategy).interfaceId;
    }
}