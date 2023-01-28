//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../interfaces/components/IUserDepositManager.1.sol";

import "../libraries/LibSanitize.sol";

import "../state/river/BalanceToDeposit.sol";

/// @title User Deposit Manager (v1)
/// @author Kiln
/// @notice This contract handles the inbound transfers cases or the explicit submissions
abstract contract UserDepositManagerV1 is IUserDepositManagerV1 {
    /// @notice Handler called whenever a user has sent funds to the contract
    /// @dev Must be overridden
    /// @param _depositor Address that made the deposit
    /// @param _recipient Address that receives the minted shares
    /// @param _amount Amount deposited
    function _onDeposit(address _depositor, address _recipient, uint256 _amount) internal virtual;

    /// @inheritdoc IUserDepositManagerV1
    function deposit() external payable {
        _deposit(msg.sender);
    }

    /// @inheritdoc IUserDepositManagerV1
    function depositAndTransfer(address _recipient) external payable {
        LibSanitize._notZeroAddress(_recipient);
        _deposit(_recipient);
    }

    /// @inheritdoc IUserDepositManagerV1
    receive() external payable {
        _deposit(msg.sender);
    }

    /// @inheritdoc IUserDepositManagerV1
    fallback() external payable {
        revert LibErrors.InvalidCall();
    }

    /// @notice Internal utility calling the deposit handler and emitting the deposit details
    /// @param _recipient The account receiving the minted shares
    function _deposit(address _recipient) internal {
        if (msg.value == 0) {
            revert EmptyDeposit();
        }

        BalanceToDeposit.set(BalanceToDeposit.get() + msg.value);

        _onDeposit(msg.sender, _recipient, msg.value);

        emit UserDeposit(msg.sender, _recipient, msg.value);
    }
}