// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import "./IERC20Detailed.sol";

import "./IPoLidoNFT.sol";

/// @title StMATIC interface.
/// StMATIC is the core contract which acts as a liquid staking pool.
/// The contract is responsible for deposits, withdrawals, minting and burning liquid tokens,
/// delegating funds to node operators, applying fees and distributing rewards.
/// StMATIC contract also defines stMATIC, an ERC20 token that represents the account's share of the total supply of MATIC tokens inside Lido on Polygon system.
/// It is a non-rebasable token, which means that the amount of tokens in the user's wallet is not going to change.
/// During time, the value of this token is changing, since the amount of MATIC tokens inside the protocol is not constant.
interface IStMATIC is IERC20Detailed {
    struct RequestWithdraw {
        uint256 amount2WithdrawFromStMATIC;
        uint256 validatorNonce;
        uint256 requestEpoch;
        address validatorAddress;
    }

    struct FeeDistribution {
        uint8 dao;
        uint8 operators;
        uint8 insurance;
    }

    function withdrawTotalDelegated(address _validatorShare) external;

    /// @notice 90% of all the rewards gets restaked on the Lido on Polygon validators.
    /// Remaining 10% gets split into 3 parts:
    /// 25% goes to the DAO
    /// 50% gets split up across all the operators
    /// 25% goes to the insurance
    function entityFees()
        external
        returns (
            uint8,
            uint8,
            uint8
        );

    function getMaticFromTokenId(uint256 _tokenId) external view returns (uint256);

    function poLidoNFT() external view returns (IPoLidoNFT);

    function token() external view returns (address);

    function lastWithdrawnValidatorId() external view returns (uint256);

    function totalBuffered() external view returns (uint256);

    function delegationLowerBound() external view returns (uint256);

    function submitThreshold() external view returns (uint256);

    function submitHandler() external view returns (bool);

    function getMinValidatorBalance() external view returns (uint256);

    function token2WithdrawRequest(uint256 _requestId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            address
        );

    function DAO() external view returns (bytes32);

    /// @notice Send MATIC to the StMATIC contract and mints stMATIC to msg.sender.
    /// @dev  The user has first to approve the amount to the StMATIC contract.
    /// @param _amount Amount of MATIC to send.
    /// @param ref referral
    function submit(uint256 _amount, address ref) external returns (uint256);

    /// @notice Allows users to request withdrawal of an amount of Matic tokens depending on the amount submitted of stMATIC.
    /// @dev This will mint a Lido NFT token which can be used later to claim the amount.
    /// @param _amount Amount to withdraw in stMATIC.
    /// @param ref referral
    function requestWithdraw(uint256 _amount, address ref) external;

    /// @notice Allows users to claim their tokens from the validators.
    /// @dev This requires user to have an NFT that was minted during the requestWithdraw transaction.
    /// @param _tokenId NFT Token ID of a pending withdrawal request.
    function claimTokens(uint256 _tokenId) external;

    /// @notice Claim and transfer the tokens from a spécific validator share contract to the StMATIC contract.
    /// @dev  This requires a valid Lido NFT token.
    /// @param _tokenId Token ID of the claim request.
    function claimTotalDelegated2StMatic(uint256 _tokenId) external;

    /// @notice Returns the total delegated MATICs across all validators.
    function getTotalStakeAcrossAllValidators() external view returns (uint256);

    /// @notice Returns total pooled matic
    function getTotalPooledMatic() external view returns (uint256);

    /// @notice Returns the MATIC value of any StMatic amount passed to the function
    /// return (balanceInMATIC, totalShares, totalPooledMATIC)
    function convertStMaticToMatic(uint256 _balance)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /// @notice Returns the StMatic value of any MATIC amount passed to the function
    /// return (balanceInStMatic, totalShares, totalPooledMATIC)
    function convertMaticToStMatic(uint256 _balance)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}