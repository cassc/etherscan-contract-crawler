// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../lib/AddressUtil.sol";
import "../../lib/EIP712.sol";
import "../../lib/ERC20SafeTransfer.sol";
import "../../lib/MathUint.sol";
import "../../lib/ReentrancyGuard.sol";
import "../../thirdparty/proxies/OwnedUpgradabilityProxy.sol";
import "../iface/IAgentRegistry.sol";
import "../iface/IExchangeV3.sol";
import "../iface/IBlockVerifier.sol";
import "./libexchange/ExchangeAdmins.sol";
import "./libexchange/ExchangeBalances.sol";
import "./libexchange/ExchangeBlocks.sol";
import "./libexchange/ExchangeDeposits.sol";
import "./libexchange/ExchangeGenesis.sol";
import "./libexchange/ExchangeMode.sol";
import "./libexchange/ExchangeTokens.sol";
import "./libexchange/ExchangeWithdrawals.sol";

/// @title An Implementation of IExchangeV3.
/// @dev This contract supports upgradability proxy, therefore its constructor
///      must do NOTHING.
/// @author Brecht Devos - <[email protected]>
/// @author Daniel Wang  - <[email protected]>
contract ExchangeV3 is IExchangeV3, ReentrancyGuard
{
    using AddressUtil           for address;
    using ERC20SafeTransfer     for address;
    using MathUint              for uint;
    using ExchangeAdmins        for ExchangeData.State;
    using ExchangeBalances      for ExchangeData.State;
    using ExchangeBlocks        for ExchangeData.State;
    using ExchangeDeposits      for ExchangeData.State;
    using ExchangeGenesis       for ExchangeData.State;
    using ExchangeMode          for ExchangeData.State;
    using ExchangeTokens        for ExchangeData.State;
    using ExchangeWithdrawals   for ExchangeData.State;

    ExchangeData.State public state;
    bool public allowOnchainTransferFrom = false;

    modifier onlyWhenUninitialized()
    {
        require(
            address(state.loopring) == address(0) && state.merkleRoot == bytes32(0),
            "INITIALIZED"
        );
        _;
    }

    modifier onlyFromUserOrAgent(address from)
    {
        require(isUserOrAgent(from), "UNAUTHORIZED");
        _;
    }

    /// @dev The constructor must do NOTHING to support proxy.
    constructor() {}

    function version()
        public
        pure
        returns (string memory)
    {
        return "0.1.0";
    }

    function domainSeparator()
        external
        view
        returns (bytes32)
    {
        return state.DOMAIN_SEPARATOR;
    }

    // -- Initialization --
    function initialize(
        address _loopring,
        address _owner,
        bytes32 _genesisMerkleRoot,
        bytes32 _genesisMerkleAssetRoot
        )
        external
        override
        nonReentrant
        onlyWhenUninitialized
    {
        require(address(0) != _owner, "ZERO_ADDRESS");
        owner = _owner;

        state.initializeGenesisBlock(
            _loopring,
            _genesisMerkleRoot,
            _genesisMerkleAssetRoot,
            EIP712.hash(EIP712.Domain("DeGate Protocol", version(), address(this)))
        );
    }

    function setDepositContract(address _depositContract)
        external
        override
        nonReentrant
        onlyOwner
    {
        require(_depositContract != address(0), "ZERO_ADDRESS");
        // Only used for initialization
        require(state.depositContract == IDepositContract(0), "ALREADY_SET");
        state.depositContract = IDepositContract(_depositContract);

        emit DepositContractUpdate(_depositContract);
    }

    function getDepositContract()
        external
        override
        view
        returns (IDepositContract)
    {
        return state.depositContract;
    }

    function withdrawExchangeFees(
        address token,
        address recipient
        )
        external
        override
        nonReentrant
        onlyOwner
    {
        require(recipient != address(0), "INVALID_ADDRESS");

        if (token == address(0)) {
            uint amount = address(this).balance;
            recipient.sendETHAndVerify(amount, gasleft());
        } else {
            uint amount = ERC20(token).balanceOf(address(this));
            token.safeTransferAndVerify(recipient, amount);
        }

        emit WithdrawExchangeFees(token, recipient);
    }

    function setDepositParams(
        uint256 freeDepositMax,
        uint256 freeDepositRemained,
        uint256 freeSlotPerBlock,
        uint256 depositFee
        )
        external
        override
        nonReentrant
        onlyOwner
    {
        state.setDepositParams(
            freeDepositMax,
            freeDepositRemained,
            freeSlotPerBlock,
            depositFee
        );

        emit DepositParamsUpdate(freeDepositMax, freeDepositRemained, freeSlotPerBlock, depositFee);
    }

    function isUserOrAgent(address from)
        public
        view
        returns (bool)
    {
         return from == msg.sender ||
            state.agentRegistry != IAgentRegistry(address(0)) &&
            state.agentRegistry.isAgent(from, msg.sender);
    }

    // -- Constants --
    function getConstants()
        external
        override
        pure
        returns(ExchangeData.Constants memory)
    {
        return ExchangeData.Constants(
            uint(ExchangeData.SNARK_SCALAR_FIELD),
            uint(ExchangeData.MAX_OPEN_FORCED_REQUESTS),
            uint(ExchangeData.MAX_AGE_FORCED_REQUEST_UNTIL_WITHDRAW_MODE),
            uint(ExchangeData.TIMESTAMP_HALF_WINDOW_SIZE_IN_SECONDS),
            uint(ExchangeData.MAX_NUM_ACCOUNTS),
            uint(ExchangeData.MAX_NUM_TOKENS),
            uint(ExchangeData.MIN_AGE_PROTOCOL_FEES_UNTIL_UPDATED),
            uint(ExchangeData.MIN_TIME_IN_SHUTDOWN),
            uint(ExchangeData.TX_DATA_AVAILABILITY_SIZE),
            uint(ExchangeData.MAX_AGE_DEPOSIT_UNTIL_WITHDRAWABLE_UPPERBOUND),
            uint(ExchangeData.MAX_FORCED_WITHDRAWAL_FEE),
            uint(ExchangeData.DEFAULT_PROTOCOL_FEE_BIPS)
        );
    }

    // -- Mode --
    function isInWithdrawalMode()
        external
        override
        view
        returns (bool)
    {
        return state.isInWithdrawalMode();
    }

    function isShutdown()
        external
        override
        view
        returns (bool)
    {
        return state.isShutdown();
    }

    // -- Tokens --

    function registerToken(
        address tokenAddress
        )
        external
        override
        nonReentrant
        returns (uint32)
    {
        return state.registerToken(tokenAddress, msg.sender == owner);
    }

    function getTokenID(
        address tokenAddress
        )
        external
        override
        view
        returns (uint32)
    {
        return state.getTokenID(tokenAddress);
    }

    function getTokenAddress(
        uint32 tokenID
        )
        external
        override
        view
        returns (address)
    {
        return state.getTokenAddress(tokenID);
    }

    // -- Stakes --
    function getExchangeStake()
        external
        override
        view
        returns (uint)
    {
        return state.loopring.getExchangeStake(address(this));
    }

    function withdrawExchangeStake(
        address recipient
        )
        external
        override
        nonReentrant
        onlyOwner
        returns (uint)
    {
        return state.withdrawExchangeStake(recipient);
    }

    function getProtocolFeeLastWithdrawnTime(
        address tokenAddress
        )
        external
        override
        view
        returns (uint)
    {
        return state.protocolFeeLastWithdrawnTime[tokenAddress];
    }

    function burnExchangeStake()
        external
        override
        nonReentrant
    {
        // Allow burning the complete exchange stake when the exchange gets into withdrawal mode
        if (state.isInWithdrawalMode()) {
            // Burn the complete stake of the exchange
            uint stake = state.loopring.getExchangeStake(address(this));
            state.loopring.burnExchangeStake(stake);
        }
    }

    // -- Blocks --
    function getMerkleRoot()
        external
        override
        view
        returns (bytes32)
    {
        return state.merkleRoot;
    }

    // -- Blocks --
    function getMerkleAssetRoot()
        external
        override
        view
        returns (bytes32)
    {
        return state.merkleAssetRoot;
    }

    function getBlockHeight()
        external
        override
        view
        returns (uint)
    {
        return state.numBlocks;
    }

    function getBlockInfo(uint blockIdx)
        external
        override
        view
        returns (ExchangeData.BlockInfo memory)
    {
        return state.blocks[blockIdx];
    }

    function submitBlocks(ExchangeData.Block[] calldata blocks)
        external
        override
        nonReentrant
        onlyOwner
    {
        state.submitBlocks(blocks);
    }

    function getNumAvailableForcedSlots()
        external
        override
        view
        returns (uint)
    {
        return state.getNumAvailableForcedSlots();
    }

    // -- Deposits --

    function deposit(
        address from,
        address to,
        address tokenAddress,
        uint248  amount,
        bytes   calldata extraData
        )
        external
        payable
        override
        nonReentrant
        onlyFromUserOrAgent(from)
    {
        state.deposit(from, to, tokenAddress, amount, extraData);
    }

    function getPendingDepositAmount(
        address from,
        address tokenAddress
        )
        external
        override
        view
        returns (uint248)
    {
        uint32 tokenID = state.getTokenID(tokenAddress);
        return state.pendingDeposits[from][tokenID].amount;
    }

    // -- Withdrawals --

    function forceWithdraw(
        address from,
        address token,
        uint32  accountID
        )
        external
        override
        nonReentrant
        payable
        onlyFromUserOrAgent(from)
    {
        state.forceWithdraw(from, token, accountID);
    }

    function isForcedWithdrawalPending(
        uint32  accountID,
        address token
        )
        external
        override
        view
        returns (bool)
    {
        uint32 tokenID = state.getTokenID(token);
        return state.pendingForcedWithdrawals[accountID][tokenID].timestamp != 0;
    }

    // We still alow anyone to withdraw these funds for the account owner
    function withdrawFromMerkleTree(
        ExchangeData.MerkleProof calldata merkleProof
        )
        external
        override
        nonReentrant
    {
        state.withdrawFromMerkleTree(merkleProof);
    }

    function isWithdrawnInWithdrawalMode(
        uint32  accountID,
        address token
        )
        external
        override
        view
        returns (bool)
    {
        uint32 tokenID = state.getTokenID(token);
        return state.withdrawnInWithdrawMode[accountID][tokenID];
    }

    function withdrawFromDepositRequest(
        address from,
        address token
        )
        external
        override
        nonReentrant
    {
        state.withdrawFromDepositRequest(
            from,
            token
        );
    }

    function withdrawFromApprovedWithdrawals(
        address[] calldata owners,
        address[] calldata tokens
        )
        external
        override
        nonReentrant
    {
        state.withdrawFromApprovedWithdrawals(
            owners,
            tokens
        );
    }

    function getAmountWithdrawable(
        address from,
        address token
        )
        external
        override
        view
        returns (uint)
    {
        uint32 tokenID = state.getTokenID(token);
        return state.amountWithdrawable[from][tokenID];
    }

    function notifyForcedRequestTooOld(
        uint32  accountID,
        address token
        )
        external
        override
        nonReentrant
    {
        uint32 tokenID = state.getTokenID(token);
        ExchangeData.ForcedWithdrawal storage withdrawal = state.pendingForcedWithdrawals[accountID][tokenID];
        require(withdrawal.timestamp != 0, "WITHDRAWAL_NOT_TOO_OLD");

        // Check if the withdrawal has indeed exceeded the time limit
        require(block.timestamp >= withdrawal.timestamp + ExchangeData.MAX_AGE_FORCED_REQUEST_UNTIL_WITHDRAW_MODE, "WITHDRAWAL_NOT_TOO_OLD");

        // Enter withdrawal mode
        state.modeTime.withdrawalModeStartTime = block.timestamp;

        emit WithdrawalModeActivated(state.modeTime.withdrawalModeStartTime);
    }

    function setWithdrawalRecipient(
        address from,
        address to,
        address token,
        uint248  amount,
        uint32  storageID,
        address newRecipient
        )
        external
        override
        nonReentrant
        onlyFromUserOrAgent(from)
    {
        require(newRecipient != address(0), "INVALID_DATA");
        uint32 tokenID = state.getTokenID(token);
        require(state.withdrawalRecipient[from][to][tokenID][amount][storageID] == address(0), "CANNOT_OVERRIDE_RECIPIENT_ADDRESS");
        state.withdrawalRecipient[from][to][tokenID][amount][storageID] = newRecipient;

        emit WithdrawalRecipientUpdate(from, to, token, amount, storageID, newRecipient);
    }

    function getWithdrawalRecipient(
        address from,
        address to,
        address token,
        uint248  amount,
        uint32  storageID
        )
        external
        override
        view
        returns (address)
    {
        uint32 tokenID = state.getTokenID(token);
        return state.withdrawalRecipient[from][to][tokenID][amount][storageID];
    }

    function onchainTransferFrom(
        address from,
        address to,
        address token,
        uint    amount
        )
        external
        override
        nonReentrant
        onlyFromUserOrAgent(from)
    {
        require(allowOnchainTransferFrom, "NOT_ALLOWED");
        state.depositContract.transfer(from, to, token, amount);
    }

    function approveTransaction(
        address from,
        bytes32 transactionHash
        )
        external
        override
        nonReentrant
        onlyFromUserOrAgent(from)
    {
        state.approvedTx[from][transactionHash] = true;
        emit TransactionApproved(from, transactionHash);
    }

    function approveTransactions(
        address[] calldata owners,
        bytes32[] calldata transactionHashes
        )
        external
        override
        nonReentrant
    {
        require(owners.length == transactionHashes.length, "INVALID_DATA");
        require(state.agentRegistry.isAgent(owners, msg.sender), "UNAUTHORIZED");
        for (uint i = 0; i < owners.length; i++) {
            state.approvedTx[owners[i]][transactionHashes[i]] = true;
        }
        emit TransactionsApproved(owners, transactionHashes);
    }

    function isTransactionApproved(
        address from,
        bytes32 transactionHash
        )
        external
        override
        view
        returns (bool)
    {
        return state.approvedTx[from][transactionHash];
    }

    function getDomainSeparator()
        external
        override
        view
        returns (bytes32)
    {
        return state.DOMAIN_SEPARATOR;
    }

    // -- Admins --
    function setMaxAgeDepositUntilWithdrawable(
        uint32 newValue
        )
        external
        override
        nonReentrant
        onlyOwner
        returns (uint32)
    {
        return state.setMaxAgeDepositUntilWithdrawable(newValue);
    }

    function getMaxAgeDepositUntilWithdrawable()
        external
        override
        view
        returns (uint32)
    {
        return state.maxAgeDepositUntilWithdrawable;
    }

    function shutdown()
        external
        override
        nonReentrant
        onlyOwner
        returns (bool success)
    {
        require(!state.isInWithdrawalMode(), "INVALID_MODE");
        require(!state.isShutdown(), "ALREADY_SHUTDOWN");
        state.modeTime.shutdownModeStartTime = block.timestamp;
        emit Shutdown(state.modeTime.shutdownModeStartTime);
        return true;
    }

    function getProtocolFeeValues()
        external
        override
        view
        returns (
            uint32 syncedAt,
            uint16 protocolFeeBips,
            uint16 previousProtocolFeeBips,
            uint32 executeTimeOfNextProtocolFeeBips,
            uint16 nextProtocolFeeBips
        )
    {
        syncedAt = state.protocolFeeData.syncedAt;
        protocolFeeBips = state.protocolFeeData.protocolFeeBips;
        previousProtocolFeeBips = state.protocolFeeData.previousProtocolFeeBips;
        executeTimeOfNextProtocolFeeBips = state.protocolFeeData.executeTimeOfNextProtocolFeeBips;
        nextProtocolFeeBips = state.protocolFeeData.nextProtocolFeeBips;
    }

    function setAllowOnchainTransferFrom(bool value)
        external
        nonReentrant
        onlyOwner
    {
        require(allowOnchainTransferFrom != value, "SAME_VALUE");
        allowOnchainTransferFrom = value;

        emit AllowOnchainTransferFrom(value);
    }

    function getUnconfirmedBalance(address token)
        external
        override
        view
        returns(uint256)
    {
        uint32 tokenId = state.getTokenID(token);

        uint256 unconfirmedBalance = 0;

        if (tokenId == 0) {
            unconfirmedBalance = address(state.depositContract).balance.sub(state.tokenIdToDepositBalance[tokenId]);
        } else {
            unconfirmedBalance = ERC20(token).balanceOf(address(state.depositContract)).sub(state.tokenIdToDepositBalance[tokenId]);
        }
        return unconfirmedBalance;
    }

    function getFreeDepositRemained()
        external
        override
        view
        returns(uint256)
    {
        return state.depositState.freeDepositRemained;
    }

    function getDepositBalance(address token)
        external
        override
        view
        returns(uint248)
    {
        uint32 tokenId = state.getTokenID(token);

        return state.tokenIdToDepositBalance[tokenId];
    }

}