// Copyright (C) 2021 BITFISH LIMITED

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only


pragma solidity ^0.8.0;

/// @notice Governs the life cycle of a single Eth2 validator with ETH provided by multiple stakers.
interface IStakefishServicesContract {
    /// @notice The life cycle of a services contract.
    enum State {
        NotInitialized,
        PreDeposit,
        PostDeposit,
        Withdrawn
    }

    /// @notice Emitted when a `spender` is set to allow the transfer of an `owner`'s deposit stake amount.
    /// `amount` is the new allownace.
    /// @dev Also emitted when {transferDepositFrom} is called.
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /// @notice Emitted when deposit stake amount is transferred.
    /// @param from The address of deposit stake owner.
    /// @param to The address of deposit stake beneficiary.
    /// @param amount The amount of transferred deposit stake.
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    /// @notice Emitted when a `spender` is set to allow withdrawal on behalf of a `owner`.
    /// `amount` is the new allowance.
    /// @dev Also emitted when {WithdrawFrom} is called.
    event WithdrawalApproval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /// @notice Emitted when `owner`'s ETH are withdrawan to `to`.
    /// @param owner The address of deposit stake owner.
    /// @param to The address of ETH beneficiary.
    /// @param amount The amount of deposit stake to be converted to ETH.
    /// @param value The amount of withdrawn ETH.
    event Withdrawal(
        address indexed owner,
        address indexed to,
        uint256 amount,
        uint256 value
    );

    /// @notice Emitted when 32 ETH is transferred to the eth2 deposit contract.
    /// @param pubkey A BLS12-381 public key.
    event ValidatorDeposited(
        bytes pubkey // 48 bytes
    );

    /// @notice Emitted when a validator exits and the operator settles the commission.
    event ServiceEnd();

    /// @notice Emitted when deposit to the services contract.
    /// @param from The address of the deposit stake owner.
    /// @param amount The accepted amount of ETH deposited into the services contract.
    event Deposit(
        address from,
        uint256 amount
    );

    /// @notice Emitted when operaotr claims commission fee.
    /// @param receiver The address of the operator.
    /// @param amount The amount of ETH sent to the operator address.
    event Claim(
        address receiver,
        uint256 amount
    );

    /// @notice Updates the exit date of the validator.
    /// @dev The exit date should be in the range of uint64.
    /// @param newExitDate The new exit date should come before the previously specified exit date.
    function updateExitDate(uint64 newExitDate) external;

    /// @notice Submits a Phase 0 DepositData to the eth2 deposit contract.
    /// @dev The Keccak hash of the contract address and all submitted data should match the `_operatorDataCommitment`.
    /// Emits a {ValidatorDeposited} event.
    /// @param validatorPubKey A BLS12-381 public key.
    /// @param depositSignature A BLS12-381 signature.
    /// @param depositDataRoot The SHA-256 hash of the SSZ-encoded DepositData object.
    /// @param exitDate The expected exit date of the created validator
    function createValidator(
        bytes calldata validatorPubKey, // 48 bytes
        bytes calldata depositSignature, // 96 bytes
        bytes32 depositDataRoot,
        uint64 exitDate
    ) external;

    /// @notice Deposits `msg.value` of ETH.
    /// @dev If the balance of the contract exceeds 32 ETH, the excess will be sent
    /// back to `msg.sender`.
    /// Emits a {Deposit} event.
    function deposit() external payable returns (uint256 surplus);


    /// @notice Deposits `msg.value` of ETH on behalf of `depositor`.
    /// @dev If the balance of the contract exceeds 32 ETH, the excess will be sent
    /// back to `depositor`.
    /// Emits a {Deposit} event.
    function depositOnBehalfOf(address depositor) external payable returns (uint256 surplus);

    /// @notice Settles operator service commission and enable withdrawal.
    /// @dev It can be called by operator if the time has passed `_exitDate`.
    /// It can be called by any address if the time has passed `_exitDate + MAX_SECONDS_IN_EXIT_QUEUE`.
    /// Emits a {ServiceEnd} event.
    function endOperatorServices() external;

    /// @notice Withdraws all the ETH of `msg.sender`.
    /// @dev It can only be called when the contract state is not `PostDeposit`.
    /// Emits a {Withdrawal} event.
    /// @param minimumETHAmount The minimum amount of ETH that must be received for the transaction not to revert.
    function withdrawAll(uint256 minimumETHAmount) external returns (uint256);

    /// @notice Withdraws the ETH of `msg.sender` which is corresponding to the `amount` of deposit stake.
    /// @dev It can only be called when the contract state is not `PostDeposit`.
    /// Emits a {Withdrawal} event.
    /// @param amount The amount of deposit stake to be converted to ETH.
    /// @param minimumETHAmount The minimum amount of ETH that must be received for the transaction not to revert.
    function withdraw(uint256 amount, uint256 minimumETHAmount) external returns (uint256);

    /// @notice Withdraws the ETH of `msg.sender` which is corresponding to the `amount` of deposit stake to a specified address.
    /// @dev It can only be called when the contract state is not `PostDeposit`.
    /// Emits a {Withdrawal} event.
    /// @param amount The amount of deposit stake to be converted to ETH.
    /// @param beneficiary The address of ETH receiver.
    /// @param minimumETHAmount The minimum amount of ETH that must be received for the transaction not to revert.
    function withdrawTo(
        uint256 amount,
        address payable beneficiary,
        uint256 minimumETHAmount
    ) external returns (uint256);

    /// @notice Sets `amount` as the allowance of `spender` over the caller's deposit stake.
    /// @dev Emits an {Approval} event.
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Increases the allowance granted to `spender` by the caller.
    /// @dev Emits an {Approval} event indicating the upated allowances;
    function increaseAllowance(address spender, uint256 addValue) external returns (bool);

    /// @notice Decreases the allowance granted to `spender` by the caller.
    /// @dev Emits an {Approval} event indicating the upated allowances;
    /// It reverts if current allowance is less than `subtractedValue`.
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /// @notice Decreases the allowance granted to `spender` by the caller.
    /// @dev Emits an {Approval} event indicating the upated allowances;
    /// It sets allowance to zero if current allowance is less than `subtractedValue`.
    function forceDecreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /// @notice Sets `amount` as the allowance of `spender` over the caller's deposit amount that can be withdrawn.
    /// @dev Emits an {WithdrawalApproval} event.
    function approveWithdrawal(address spender, uint256 amount) external returns (bool);

    /// @notice Increases the allowance of withdrawal granted to `spender` by the caller.
    /// @dev Emits an {WithdrawalApproval} event indicating the upated allowances;
    function increaseWithdrawalAllowance(address spender, uint256 addValue) external returns (bool);

    /// @notice Decreases the allowance of withdrawal granted to `spender` by the caller.
    /// @dev Emits an {WithdrawwalApproval} event indicating the upated allowances;
    /// It reverts if current allowance is less than `subtractedValue`.
    function decreaseWithdrawalAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /// @notice Decreases the allowance of withdrawal granted to `spender` by the caller.
    /// @dev Emits an {WithdrawwalApproval} event indicating the upated allowances;
    /// It reverts if current allowance is less than `subtractedValue`.
    function forceDecreaseWithdrawalAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /// @notice Withdraws the ETH of `depositor` which is corresponding to the `amount` of deposit stake to a specified address.
    /// @dev Emits a {Withdrawal} event.
    /// Emits a {WithdrawalApproval} event indicating the updated allowance.
    /// @param depositor The address of deposit stake holder.
    /// @param beneficiary The address of ETH receiver.
    /// @param amount The amount of deposit stake to be converted to ETH.
    /// @param minimumETHAmount The minimum amount of ETH that must be received for the transaction not to revert.
    function withdrawFrom(
        address depositor,
        address payable beneficiary,
        uint256 amount,
        uint256 minimumETHAmount
    ) external returns (uint256);

    /// @notice Transfers `amount` deposit stake from caller to `to`.
    /// @dev Emits a {Transfer} event.
    function transferDeposit(address to, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` deposit stake from `from` to `to`.
    /// @dev Emits a {Transfer} event.
    /// Emits an {Approval} event indicating the updated allowance.
    function transferDepositFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /// @notice Transfers operator claimable commission fee to the operator address.
    /// @dev Emits a {Claim} event.
    function operatorClaim() external returns (uint256);

    /// @notice Returns the remaining number of deposit stake that `spender` will be allowed to withdraw
    /// on behalf of `depositor` through {withdrawFrom}.
    function withdrawalAllowance(address depositor, address spender) external view returns (uint256);

    /// @notice Returns the operator service commission rate.
    function getCommissionRate() external view returns (uint256);

    /// @notice Returns operator claimable commission fee.
    function getOperatorClaimable() external view returns (uint256);

    /// @notice Returns the exit date of the validator.
    function getExitDate() external view returns (uint256);

    /// @notice Returns the state of the contract.
    function getState() external view returns (State);

    /// @notice Returns the address of operator.
    function getOperatorAddress() external view returns (address);

    /// @notice Returns the amount of deposit stake owned by `depositor`.
    function getDeposit(address depositor) external view returns (uint256);

    /// @notice Returns the total amount of deposit stake.
    function getTotalDeposits() external view returns (uint256);

    /// @notice Returns the remaining number of deposit stake that `spender` will be allowed to transfer
    /// on behalf of `depositor` through {transferDepositFrom}.
    function getAllowance(address owner, address spender) external view returns (uint256);

    /// @notice Returns the commitment which is the hash of the contract address and all inputs to the `createValidator` function.
    function getOperatorDataCommitment() external view returns (bytes32);

    /// @notice Returns the amount of ETH that is withdrawable by `owner`.
    function getWithdrawableAmount(address owner) external view returns (uint256);
}