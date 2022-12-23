// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;

import "../../interfaces/multivault/IMultiVaultFacetFees.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces/IMultiVaultToken.sol";

import "../../libraries/SafeERC20.sol";

import "../storage/MultiVaultStorage.sol";

import "../helpers/MultiVaultHelperActors.sol";
import "../helpers/MultiVaultHelperEverscale.sol";
import "../helpers/MultiVaultHelperFee.sol";
import "../helpers/MultiVaultHelperReentrancyGuard.sol";


contract MultiVaultFacetFees is
    MultiVaultHelperActors,
    MultiVaultHelperEverscale,
    MultiVaultHelperFee,
    MultiVaultHelperReentrancyGuard,
    IMultiVaultFacetFees
{
    using SafeERC20 for IERC20;

    /// @notice Set deposit fee for specific token.
    /// This may be called only by `owner` or `management`.
    /// @param token Token address
    /// @param _depositFee Deposit fee, must be less than FEE_LIMIT.
    function setTokenDepositFee(
        address token,
        uint _depositFee
    )
        public
        override
        onlyGovernanceOrManagement
        respectFeeLimit(_depositFee)
    {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.tokens_[token].depositFee = _depositFee;

        emit UpdateTokenDepositFee(token, _depositFee);
    }

    /// @notice Set withdraw fee for specific token.
    /// This may be called only by `governance` or `management`
    /// @param token Token address, must be enabled
    /// @param _withdrawFee Withdraw fee, must be less than FEE_LIMIT.
    function setTokenWithdrawFee(
        address token,
        uint _withdrawFee
    )
        public
        override
        onlyGovernanceOrManagement
        respectFeeLimit(_withdrawFee)
    {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.tokens_[token].withdrawFee = _withdrawFee;

        emit UpdateTokenWithdrawFee(token, _withdrawFee);
    }

    /// @notice Skim multivault fees for specific token
    /// Can be called only by governance or management.
    /// @param token Token address, can be both native or alien
    function skim(
        address token
    ) external payable override nonReentrant onlyGovernanceOrManagement {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        uint fee = s.fees[token];

        require(fee > 0);

        s.fees[token] = 0;

        // Find out token type
        bool isNative = s.tokens_[token].isNative;

        if (isNative) {
            IMultiVaultToken(token).mint(s.governance, fee);
        } else {
            IERC20(token).safeTransfer(s.governance, fee);
        }

        emit SkimFee(token, false, fee);
    }

    /// @notice Set default deposit fee for native tokens.
    /// Charged on the `deposit`.
    /// @param fee Fee amount, should be less than FEE_LIMIT
    function setDefaultNativeDepositFee(
        uint fee
    )
        external
        override
        onlyGovernanceOrManagement
        respectFeeLimit(fee)
    {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.defaultNativeDepositFee = fee;

        emit UpdateDefaultNativeDepositFee(fee);
    }

    /// @notice Set default withdraw fee for native tokens.
    /// Charged on the `saveWithdrawNative`.
    /// @param fee Fee amount, should be less than FEE_LIMIT
    function setDefaultNativeWithdrawFee(
        uint fee
    )
        external
        override
        onlyGovernanceOrManagement
        respectFeeLimit(fee)
    {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.defaultNativeWithdrawFee = fee;

        emit UpdateDefaultNativeWithdrawFee(fee);
    }

    /// @notice Set default deposit fee for alien tokens.
    /// Charged on the `deposit`.
    /// @param fee Fee amount, should be less than FEE_LIMIT
    function setDefaultAlienDepositFee(
        uint fee
    )
        external
        override
        onlyGovernanceOrManagement
        respectFeeLimit(fee)
    {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.defaultAlienDepositFee = fee;

        emit UpdateDefaultAlienDepositFee(fee);
    }

    /// @notice Set default withdraw fee for alien tokens.
    /// Charged on the `saveWithdrawAlien`.
    /// @param fee Fee amount, should be less than FEE_LIMIT
    function setDefaultAlienWithdrawFee(
        uint fee
    )
        external
        override
        onlyGovernanceOrManagement
        respectFeeLimit(fee)
    {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.defaultAlienWithdrawFee = fee;

        emit UpdateDefaultAlienWithdrawFee(fee);
    }

    function fees(address _token) external view override returns (uint) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.fees[_token];
    }

    function defaultNativeWithdrawFee() external view override returns (uint) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.defaultNativeWithdrawFee;
    }

    function defaultNativeDepositFee() external view override returns (uint) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.defaultNativeDepositFee;
    }

    function defaultAlienDepositFee() external view override returns (uint) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.defaultAlienDepositFee;
    }

    function defaultAlienWithdrawFee() external view override returns (uint) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.defaultAlienWithdrawFee;
    }
}