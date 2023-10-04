// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {DataTypesPeerToPeer} from "../peer-to-peer/DataTypesPeerToPeer.sol";
import {DataTypesPeerToPool} from "../peer-to-pool/DataTypesPeerToPool.sol";

interface IMysoTokenManager {
    function processP2PBorrow(
        uint128[2] memory currProtocolFeeParams,
        DataTypesPeerToPeer.BorrowTransferInstructions
            calldata borrowInstructions,
        DataTypesPeerToPeer.Loan calldata loan,
        address lenderVault
    ) external returns (uint128[2] memory applicableProtocolFeeParams);

    function processP2PCreateVault(
        uint256 numRegisteredVaults,
        address vaultCreator,
        address newLenderVaultAddr
    ) external;

    function processP2PCreateWrappedTokenForERC721s(
        address tokenCreator,
        DataTypesPeerToPeer.WrappedERC721TokenInfo[] calldata tokensToBeWrapped,
        bytes calldata mysoTokenManagerData
    ) external;

    function processP2PCreateWrappedTokenForERC20s(
        address tokenCreator,
        DataTypesPeerToPeer.WrappedERC20TokenInfo[] calldata tokensToBeWrapped,
        bytes calldata mysoTokenManagerData
    ) external;

    function processP2PoolDeposit(
        address fundingPool,
        address depositor,
        uint256 depositAmount,
        uint256 depositLockupDuration,
        uint256 transferFee
    ) external;

    function processP2PoolSubscribe(
        address fundingPool,
        address subscriber,
        address loanProposal,
        uint256 subscriptionAmount,
        uint256 subscriptionLockupDuration,
        uint256 totalSubscriptions,
        DataTypesPeerToPool.LoanTerms calldata loanTerms
    ) external;

    function processP2PoolLoanFinalization(
        address loanProposal,
        address fundingPool,
        address arranger,
        address borrower,
        uint256 grossLoanAmount,
        bytes calldata mysoTokenManagerData
    ) external;

    function processP2PoolCreateLoanProposal(
        address fundingPool,
        address proposalCreator,
        address collToken,
        uint256 arrangerFee,
        uint256 numLoanProposals
    ) external;
}