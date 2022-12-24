// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;

import "../../interfaces/multivault/IMultiVaultFacetWithdraw.sol";
import "../../interfaces/multivault/IMultiVaultFacetPendingWithdrawals.sol";
import "../../interfaces/multivault/IMultiVaultFacetTokens.sol";
import "../../interfaces/multivault/IMultiVaultFacetFees.sol";
import "../../interfaces/IEverscale.sol";
import "../../interfaces/IERC20.sol";

import "../../libraries/SafeERC20.sol";

import "../helpers/MultiVaultHelperFee.sol";
import "../helpers/MultiVaultHelperReentrancyGuard.sol";
import "../helpers/MultiVaultHelperWithdraw.sol";
import "../helpers/MultiVaultHelperEmergency.sol";
import "../helpers/MultiVaultHelperTokens.sol";
import "../helpers/MultiVaultHelperPendingWithdrawal.sol";
import "../helpers/MultiVaultHelperTokenBalance.sol";
import "../helpers/MultiVaultHelperCallback.sol";


contract MultiVaultFacetWithdraw is
    MultiVaultHelperFee,
    MultiVaultHelperReentrancyGuard,
    MultiVaultHelperWithdraw,
    MultiVaultHelperPendingWithdrawal,
    MultiVaultHelperTokens,
    MultiVaultHelperTokenBalance,
    MultiVaultHelperCallback,
    IMultiVaultFacetWithdraw
{
    using SafeERC20 for IERC20;

    /// @notice Save withdrawal for native token
    /// @param payload Withdraw payload
    /// @param signatures Payload signatures
    function saveWithdrawNative(
        bytes memory payload,
        bytes[] memory signatures
    )
        external
        override
        nonReentrant
        withdrawalNotSeenBefore(payload)
        onlyEmergencyDisabled
    {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        IEverscale.EverscaleEvent memory _event = _processWithdrawEvent(
            payload,
            signatures,
            s.configurationNative_
        );

        bytes32 payloadId = keccak256(payload);

        // Decode event data
        NativeWithdrawalParams memory withdrawal = decodeNativeWithdrawalEventData(_event.eventData);

        // Ensure chain id is correct
        require(withdrawal.chainId == block.chainid);

        // Derive token address
        // Depends on the withdrawn token source
        address token = _getNativeWithdrawalToken(withdrawal);

        // Ensure token is not blacklisted
        require(!s.tokens_[token].blacklisted);

        // Consider movement fee and send it to `rewards_`
        uint256 fee = _calculateMovementFee(
            withdrawal.amount,
            token,
            IMultiVaultFacetFees.Fee.Withdraw
        );

        _increaseTokenFee(token, fee);

        _withdraw(
            withdrawal.recipient,
            withdrawal.amount,
            fee,
            IMultiVaultFacetTokens.TokenType.Native,
            payloadId,
            token
        );

        _callbackNativeWithdrawal(withdrawal);
    }

    /// @notice Save withdrawal of alien token
    /// @param signatures List of payload signatures
    /// @param bounty Bounty size
    function saveWithdrawAlien(
        bytes memory payload,
        bytes[] memory signatures,
        uint bounty
    )
        public
        override
        nonReentrant
        withdrawalNotSeenBefore(payload)
        onlyEmergencyDisabled
    {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        IEverscale.EverscaleEvent memory _event = _processWithdrawEvent(
            payload,
            signatures,
            s.configurationAlien_
        );

        bytes32 payloadId = keccak256(payload);

        // Decode event data
        AlienWithdrawalParams memory withdrawal = decodeAlienWithdrawalEventData(_event.eventData);

        // Ensure chain id is correct
        require(withdrawal.chainId == block.chainid); // TODO: add errors

        // Ensure token is not blacklisted
        require(!s.tokens_[withdrawal.token].blacklisted);

        // Consider movement fee and send it to `rewards_`
        uint256 fee = _calculateMovementFee(
            withdrawal.amount,
            withdrawal.token,
            IMultiVaultFacetFees.Fee.Withdraw
        );

        _increaseTokenFee(withdrawal.token, fee);

        uint withdrawAmount = withdrawal.amount - fee;

        // Consider withdrawal period limit
        IMultiVaultFacetPendingWithdrawals.WithdrawalPeriodParams memory withdrawalPeriod = _withdrawalPeriod(
            withdrawal.token,
            _event.eventTimestamp
        );

        _withdrawalPeriodIncreaseTotalByTimestamp(
            withdrawal.token,
            _event.eventTimestamp,
            withdrawal.amount
        );

        bool withdrawalLimitsPassed = _withdrawalPeriodCheckLimitsPassed(
            withdrawal.token,
            withdrawal.amount,
            withdrawalPeriod
        );

        // Token balance sufficient and none of the limits are violated
        if (withdrawal.amount <= _vaultTokenBalance(withdrawal.token) && withdrawalLimitsPassed) {

            _withdraw(
                withdrawal.recipient,
                withdrawal.amount,
                fee,
                IMultiVaultFacetTokens.TokenType.Alien,
                payloadId,
                withdrawal.token
            );

            _callbackAlienWithdrawal(withdrawal);

            return;
        }

        // Create pending withdrawal
        uint pendingWithdrawalId = s.pendingWithdrawalsPerUser[withdrawal.recipient];

        s.pendingWithdrawalsPerUser[withdrawal.recipient]++;

        s.pendingWithdrawalsTotal[withdrawal.token] += withdrawAmount;

        // - Save withdrawal as pending
        s.pendingWithdrawals_[withdrawal.recipient][pendingWithdrawalId] = IMultiVaultFacetPendingWithdrawals.PendingWithdrawalParams({
            token: withdrawal.token,
            amount: withdrawAmount,
            bounty: msg.sender == withdrawal.recipient ? bounty : 0,
            timestamp: _event.eventTimestamp,
            approveStatus: IMultiVaultFacetPendingWithdrawals.ApproveStatus.NotRequired
        });

        emit PendingWithdrawalCreated(
            withdrawal.recipient,
            pendingWithdrawalId,
            withdrawal.token,
            withdrawAmount,
            payloadId
        );

        if (!withdrawalLimitsPassed) {
            _pendingWithdrawalApproveStatusUpdate(
                IMultiVaultFacetPendingWithdrawals.PendingWithdrawalId(withdrawal.recipient, pendingWithdrawalId),
                IMultiVaultFacetPendingWithdrawals.ApproveStatus.Required
            );
        }

        _callbackAlienWithdrawalPendingCreated(withdrawal);
    }

    /// @notice Save withdrawal of alien token
    function saveWithdrawAlien(
        bytes memory payload,
        bytes[] memory signatures
    )  external override {
        saveWithdrawAlien(payload, signatures, 0);
    }

    function decodeNativeWithdrawalEventData(
        bytes memory eventData
    ) internal pure returns (NativeWithdrawalParams memory) {
        (
            int8 native_wid,
            uint256 native_addr,

            string memory name,
            string memory symbol,
            uint8 decimals,

            uint128 amount,
            uint160 recipient,
            uint256 chainId,

            uint160 callback_recipient,
            bytes memory callback_payload,
            bool callback_strict
        ) = abi.decode(
            eventData,
            (
                int8, uint256,
                string, string, uint8,
                uint128, uint160, uint256,
                uint160, bytes, bool
            )
        );

        return NativeWithdrawalParams({
            native: IEverscale.EverscaleAddress(native_wid, native_addr),
            meta: IMultiVaultFacetTokens.TokenMeta(name, symbol, decimals),
            amount: amount,
            recipient: address(recipient),
            chainId: chainId,
            callback: Callback(
                address(callback_recipient),
                callback_payload,
                callback_strict
            )
        });
    }

    function decodeAlienWithdrawalEventData(
        bytes memory eventData
    ) internal pure returns (AlienWithdrawalParams memory) {
        (
            uint160 token,
            uint128 amount,
            uint160 recipient,
            uint256 chainId,

            uint160 callback_recipient,
            bytes memory callback_payload,
            bool callback_strict
        ) = abi.decode(
            eventData,
            (
                uint160, uint128, uint160, uint256,
                uint160, bytes, bool
            )
        );

        return AlienWithdrawalParams({
            token: address(token),
            amount: uint256(amount),
            recipient: address(recipient),
            chainId: chainId,
            callback: Callback(
                address(callback_recipient),
                callback_payload,
                callback_strict
            )
        });
    }

    function withdrawalIds(bytes32 id) external view override returns(bool) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.withdrawalIds[id];
    }
}