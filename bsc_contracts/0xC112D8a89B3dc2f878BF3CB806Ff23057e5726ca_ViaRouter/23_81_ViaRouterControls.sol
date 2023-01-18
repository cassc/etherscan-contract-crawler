// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./ViaRouterStorage.sol";
import "./ViaRouterEvents.sol";
import "../libraries/Transfers.sol";
import "../libraries/Errors.sol";
import "../libraries/Whitelist.sol";

abstract contract ViaRouterControls is ViaRouterStorage, ViaRouterEvents {
    using Transfers for address;

    // PUBLIC OWNER FUNCTIONS

    /// @notice Sets new validator (owner only)
    /// @param validator_ Address of the new validator
    function setValidator(address validator_) external onlyOwner {
        validator = validator_;
        emit ValidatorSet(validator_);
    }

    /// @notice Sets address as enabled or disabled adapter (owner only)
    /// @param adapter Address to set
    /// @param active True to enable as adapter, false to disable
    function setAdapter(address adapter, bool active) external onlyOwner {
        adapters[adapter] = active;
        emit AdapterSet(adapter, active);
    }

    /// @notice Sets whitelist state for list of target contracts
    /// @param targets List of addresses of target contracts to set
    /// @param whitelisted List of flags if each address should be whitelisted or blacklisted
    function setWhitelistedTargets(
        address[] calldata targets,
        bool[] calldata whitelisted
    ) external onlyOwner {
        require(targets.length == whitelisted.length, Errors.LENGHTS_MISMATCH);

        for (uint256 i = 0; i < targets.length; i++) {
            Whitelist.setWhitelisted(targets[i], whitelisted[i]);

            emit WhitelistedSet(targets[i], whitelisted[i]);
        }
    }

    /// @notice Withdraws collected fee from contract (owner only)
    /// @param token Token to withdraw (address(0) to withdrawn native token)
    /// @param receiver Receiver of the withdrawal
    /// @param amount Amount to withdraw
    function withdrawFee(
        address token,
        address receiver,
        uint256 amount
    ) external onlyOwner {
        require(
            collectedFees[token] >= amount,
            Errors.INSUFFICIENT_COLLECTED_FEES
        );

        uint256 balanceBefore = Transfers.getBalance(token);
        Transfers.transferOut(token, receiver, amount);
        uint256 balanceAfter = Transfers.getBalance(token);
        collectedFees[token] -= balanceBefore - balanceAfter;

        emit FeeWithdrawn(token, receiver, amount);
    }

    // PUBLIC VIEW FUNCTIONS

    /// @notice Checks if address is whitelisted as target
    /// @param target Address to check
    /// @return _ True if whitelisted, false otherwise
    function isWhitelistedTarget(address target) external view returns (bool) {
        return Whitelist.isWhitelisted(target);
    }
}