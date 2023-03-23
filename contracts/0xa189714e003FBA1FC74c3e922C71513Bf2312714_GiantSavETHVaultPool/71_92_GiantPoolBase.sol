pragma solidity ^0.8.18;

// SPDX-License-Identifier: BUSL-1.1

import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { LSDNFactory } from "./LSDNFactory.sol";
import { GiantLP } from "./GiantLP.sol";
import { LPToken } from "./LPToken.sol";
import { ITransferHookProcessor } from "../interfaces/ITransferHookProcessor.sol";
import { ETHTransferHelper } from "../transfer/ETHTransferHelper.sol";

abstract contract GiantPoolBase is ITransferHookProcessor, ReentrancyGuardUpgradeable, ETHTransferHelper {

    using EnumerableSet for EnumerableSet.UintSet;

    error BelowMinimum();
    error InvalidAmount();
    error InvalidWithdrawal();
    error ComeBackLater();
    error BLSKeyStaked();
    error BLSKeyNotStaked();
    error ErrorWithdrawing();
    error OnlyManager();
    error InvalidCaller();
    error InvalidBalance();
    error NotEnoughIdleETH();
    error InvalidTransfer();
    error InvalidJump();
    error InvalidExistingPosition();
    error NoRecycledETH();
    error NoFundingInSelectedBatch();
    error BatchAllocated();
    error UnableToDeleteRecycledBatch();
    error NoFullBatchAvailable();

    /// @notice Emitted when an account deposits Ether into the giant pool
    event ETHDeposited(address indexed sender, uint256 amount);

    /// @notice Emitted when giant LP is burnt to recover ETH
    event LPBurnedForETH(address indexed sender, uint256 amount);

    /// @notice Emitted when a deposit associates a depositor with a ticket for withdrawal
    event WithdrawalBatchAssociatedWithUser(address indexed user, uint256 indexed batchId);

    /// @notice Emitted when user updates their staked position
    event WithdrawalBatchUpdated(address indexed user, uint256 indexed batchId, uint256 newAmount);

    /// @notice Emitted when a withdrawal batch associated with a depositor is removed
    event WithdrawalBatchRemovedFromUser(address indexed user, uint256 indexed batchId);

    /// @notice Emitted when a withdrawal batch is associated with a BLS pub key
    event WithdrawalBatchAssociatedWithBLSKey(bytes key, uint256 indexed batchId);

    /// @notice Emitted when a withdrawal batch is disassociated with a BLS pub key
    event WithdrawalBatchDisassociatedWithBLSKey(bytes key, uint256 indexed batchId);

    /// @notice Emitted when a user is jumping a deposit queue because another user withdrew
    event QueueJumped(address indexed user, uint256 indexed targetPosition, uint256 indexed existingPosition, uint256 amount);

    /// @notice Minimum amount of Ether that can be deposited into the contract
    uint256 public constant MIN_STAKING_AMOUNT = 0.001 ether;

    /// @notice Size of funding offered per BLS public key
    uint256 public batchSize;

    /// @notice Total amount of ETH sat idle ready for either withdrawal or depositing into a liquid staking network
    uint256 public idleETH;

    /// @notice Historical amount of ETH received by all depositors
    uint256 public totalETHFromLPs;

    /// @notice LP token representing all ETH deposited and any ETH converted into savETH vault LP tokens from any liquid staking network
    GiantLP public lpTokenETH;

    /// @notice Address of the liquid staking derivative factory that provides a source of truth on individual networks that can be funded
    LSDNFactory public liquidStakingDerivativeFactory;

    /// @notice Number of batches of 24 ETH that have been deposited to the open pool
    uint256 public depositBatchCount;

    /// @notice Number of batches that have been deployed to a liquid staking network
    uint256 public stakedBatchCount;

    /// @notice Based on a user deposit, all the historical batch positions later used for claiming
    mapping(address => EnumerableSet.UintSet) internal setOfAssociatedDepositBatches;

    /// @notice Whether the giant pool funded the ETH for staking
    mapping(bytes => bool) internal isBLSPubKeyFundedByGiantPool;

    /// @notice For a given BLS key, allocated withdrawal batch
    mapping(bytes => uint256) public allocatedWithdrawalBatchForBlsPubKey;

    /// @notice For a given withdrawal batch, allocated BLS key
    mapping(uint256 => bytes) public allocatedBlsPubKeyForWithdrawalBatch;

    /// @notice Given a user and batch ID, total ETH contributed
    mapping(address => mapping(uint256 => uint256)) public totalETHFundedPerBatch;

    /// @notice Whenever a deposit batch ID is released by a user withdrawing, we recycle the batch ID so the gaps are filled by future depositors
    EnumerableSet.UintSet internal setOfRecycledDepositBatches;

    /// @notice For a given batch ID that has been recycled, how much ETH new depositors can fund in recycled batches
    mapping(uint256 => uint256) public ethRecycledFromBatch;

    /// @notice Track any staked batches that are recycled
    EnumerableSet.UintSet internal setOfRecycledStakedBatches;

    modifier whenContractNotPaused() {
        _assertContractNotPaused();
        _;
    }

    /// @notice Add ETH to the ETH LP pool at a rate of 1:1. LPs can always pull out at same rate.
    function depositETH(uint256 _amount) external payable nonReentrant whenContractNotPaused {
        if (_amount < MIN_STAKING_AMOUNT) revert InvalidAmount();
        if (_amount % MIN_STAKING_AMOUNT != 0) revert InvalidAmount();
        if (msg.value != _amount) revert InvalidAmount();

        // The ETH capital has not yet been deployed to a liquid staking network
        idleETH += msg.value;
        totalETHFromLPs += msg.value;

        // Mint giant LP at ratio of 1:1
        lpTokenETH.mint(msg.sender, msg.value);

        // If anything extra needs to be done
        _afterDepositETH(msg.value);

        emit ETHDeposited(msg.sender, msg.value);
    }

    /// @notice Withdraw ETH but only from withdrawal batches that have not been staked yet
    /// @param _amount of LP tokens user is burning in exchange for same amount of ETH
    function withdrawETH(
        uint256 _amount
    ) external nonReentrant whenContractNotPaused {
        if (_amount == 0) revert InvalidAmount();
        if (lpTokenETH.balanceOf(msg.sender) < _amount) revert InvalidBalance();
        if (idleETH < _amount) revert NotEnoughIdleETH();

        // Revert early if user is not part of any batches
        uint256 totalNumOfBatches = setOfAssociatedDepositBatches[msg.sender].length();
        if (totalNumOfBatches == 0) revert InvalidWithdrawal();

        // Check how new the lpTokenETH liquidity of msg.sender
        if (lpTokenETH.lastInteractedTimestamp(msg.sender) + 45 minutes > block.timestamp) revert ComeBackLater();

        // Send the ETH
        _withdrawETH(_amount);

        // Update associated batch IDs for msg.sender
        // Withdraw ETH from the batch added last unless it is staked in which case user must redeem dETH
        uint256 ethLeftToWithdraw = _amount;
        for (uint256 i = totalNumOfBatches; i > 0; --i) {
            uint256 batchAtIndex = setOfAssociatedDepositBatches[msg.sender].at(i - 1);

            if (allocatedBlsPubKeyForWithdrawalBatch[batchAtIndex].length != 0) {
                continue;
            }

            uint256 ethFromBatch = totalETHFundedPerBatch[msg.sender][batchAtIndex];
            uint256 amountToRecycle = ethLeftToWithdraw >= ethFromBatch ? ethFromBatch : ethLeftToWithdraw;
            if (ethLeftToWithdraw >= ethFromBatch) {
                ethLeftToWithdraw -= amountToRecycle;
            } else {
                ethLeftToWithdraw = 0;
            }

            _reduceUserAmountFundedInBatch(batchAtIndex, msg.sender, amountToRecycle);

            // Recycle any batches that are less than the current deposit count so that we can fill gaps with future depositors
            if (batchAtIndex < depositBatchCount) {
                setOfRecycledDepositBatches.add(batchAtIndex);
                ethRecycledFromBatch[batchAtIndex] += amountToRecycle;
            }

            // Break out of the loop when we have matched the withdrawal amounts over batches
            if (ethLeftToWithdraw == 0) break;
        }

        // If we get out of the loop and the amount left to withdraw is not zero then there was not enough withdrawable ETH to match the withdrawal amount
        if (ethLeftToWithdraw != 0) revert ErrorWithdrawing();
    }

    /// @notice Allow liquid staking managers to notify the giant pool about derivatives minted for a key
    function onMintDerivatives(bytes calldata _blsPublicKey) external {
        if (!liquidStakingDerivativeFactory.isLiquidStakingManager(msg.sender)) revert OnlyManager();
        _onMintDerivatives(_blsPublicKey);
    }

    /// @notice Total amount of ETH an LP can withdraw on the basis of whether the ETH has been used in staking
    function withdrawableAmountOfETH(address _user) external view returns (uint256) {
        uint256 withdrawableAmount;

        uint256 _stakedBatchCount = stakedBatchCount; // Cache

        // If the user does not have an allocated batch, the withdrawable amount will return zero
        uint256 totalNumOfBatches = setOfAssociatedDepositBatches[_user].length();
        for (uint256 i = totalNumOfBatches; i > 0; --i) {
            uint256 batchAtIndex = setOfAssociatedDepositBatches[_user].at(i - 1);

            if (allocatedBlsPubKeyForWithdrawalBatch[batchAtIndex].length == 0) {
                withdrawableAmount += totalETHFundedPerBatch[_user][batchAtIndex];
            }
        }

        return withdrawableAmount;
    }

    /// @notice Get the total number of withdrawal tickets allocated to an address
    function getSetOfAssociatedDepositBatchesSize(address _user) external view returns (uint256) {
        return setOfAssociatedDepositBatches[_user].length();
    }

    /// @notice Get the withdrawal ticket batch ID at an index
    function getAssociatedDepositBatchIDAtIndex(address _user, uint256 _index) external view returns (uint256) {
        return setOfAssociatedDepositBatches[_user].at(_index);
    }

    /// @notice Get total number of recycled deposit batches
    function getRecycledDepositBatchesSize() external view returns (uint256) {
        return setOfRecycledDepositBatches.length();
    }

    /// @notice Get batch ID at a specific index for recycled deposit batches
    function getRecycledDepositBatchIDAtIndex(uint256 _index) external view returns (uint256) {
        return setOfRecycledDepositBatches.at(_index);
    }

    /// @notice Get total number of recycled staked batches
    function getRecycledStakedBatchesSize() external view returns (uint256) {
        return setOfRecycledStakedBatches.length();
    }

    /// @notice Get batch ID at a specific index for recycled staked batches
    function getRecycledStakedBatchIDAtIndex(uint256 _index) external view returns (uint256) {
        return setOfRecycledStakedBatches.at(_index);
    }

    /// @notice Allow giant LP token to notify pool about transfers so the claimed amounts can be processed
    function afterTokenTransfer(address _from, address _to, uint256 _amount) external {
        if (msg.sender != address(lpTokenETH)) revert InvalidCaller();
        if (_from != address(0) && _to != address(0)) {
            EnumerableSet.UintSet storage setOfAssociatedDepositBatchesForFrom = setOfAssociatedDepositBatches[_from];
            uint256 amountLeftToTransfer = _amount;

            // Transfer redemption rights of batches to the recipient address
            // They may already have the rights to some batches but they will gain a larger share afterwards
            uint256 numOfBatchesFromAddress = setOfAssociatedDepositBatchesForFrom.length();
            for (uint256 i = numOfBatchesFromAddress; i > 0; --i) {
                // Duplicates are avoided due to use of enumerable set
                uint256 batchId = setOfAssociatedDepositBatchesForFrom.at(i - 1);
                uint256 totalETHFunded = totalETHFundedPerBatch[_from][batchId];
                if (amountLeftToTransfer >= totalETHFunded) {
                    // Clean up the state for the 'from' account
                    _reduceUserAmountFundedInBatch(batchId, _from, totalETHFunded);

                    // Adjust how much is left to transfer
                    amountLeftToTransfer -= totalETHFunded;

                    // Add _to user to the batch
                    _addUserToBatch(batchId, _to, totalETHFunded);
                } else {
                    // Adjust the _from user total funded
                    _reduceUserAmountFundedInBatch(batchId, _from, amountLeftToTransfer);

                    // Add _to user to the batch
                    _addUserToBatch(batchId, _to, amountLeftToTransfer);

                    // There will no longer be any amount left to transfer
                    amountLeftToTransfer = 0;
                }

                // We can leave the loop once the required batches have been given to recipient
                if (amountLeftToTransfer == 0) break;
            }

            if (amountLeftToTransfer != 0) revert InvalidTransfer();
        }
    }

    /// @notice If another giant pool user withdraws ETH freeing up an earlier space in the queue, allow them to jump some of their funding there
    /// @param _targetPosition Batch ID of the target batch user wants their funding associated
    /// @param _existingPosition Batch ID of the existing batch user is transferring their funding from
    /// @param _user Address of the user that has funded giant pool allowing others to help jump the queue
    function jumpTheQueue(uint256 _targetPosition, uint256 _existingPosition, address _user) external {
        // Make sure that the target is less than existing - forcing only one direction.
        // Existing cannot be more than the deposit batch count
        if (_targetPosition > _existingPosition) revert InvalidJump();
        if (_existingPosition > depositBatchCount) revert InvalidExistingPosition();

        // Check that the target has ETH recycled due to withdrawal
        uint256 ethRecycled = ethRecycledFromBatch[_targetPosition];
        if (ethRecycled == 0) revert NoRecycledETH();

        // Check that the user has funding in existing batch and neither existing or target batch has been allocated
        uint256 totalExistingFunding = totalETHFundedPerBatch[_user][_existingPosition];
        if (totalExistingFunding == 0) revert NoFundingInSelectedBatch();
        if (allocatedBlsPubKeyForWithdrawalBatch[_targetPosition].length != 0) revert BatchAllocated();
        if (allocatedBlsPubKeyForWithdrawalBatch[_existingPosition].length != 0) revert BatchAllocated();

        // Calculate how much can jump from existing to target
        uint256 amountThatCanJump = totalExistingFunding > ethRecycled ? ethRecycled : totalExistingFunding;

        // Adjust how much ETH from withdrawals is recycled, removing batch if it hits zero
        ethRecycledFromBatch[_targetPosition] -= amountThatCanJump;
        if (ethRecycledFromBatch[_targetPosition] == 0) {
            if (!setOfRecycledDepositBatches.remove(_targetPosition)) revert UnableToDeleteRecycledBatch();
        }

        // If users existing position is less than deposit count, treat it as recycled
        if (_existingPosition < depositBatchCount) {
            ethRecycledFromBatch[_existingPosition] += amountThatCanJump;
            setOfRecycledDepositBatches.add(_existingPosition);
        }

        // Reduce funding from existing position and add user funded amount to new batch
        _reduceUserAmountFundedInBatch(_existingPosition, _user, amountThatCanJump);
        _addUserToBatch(_targetPosition, _user, amountThatCanJump);

        emit QueueJumped(_user, _targetPosition, _existingPosition, amountThatCanJump);
    }

    /// @dev Business logic for managing withdrawal of ETH
    function _withdrawETH(uint256 _amount) internal {
        // Burn giant tokens
        lpTokenETH.burn(msg.sender, _amount);

        // Adjust idle ETH
        idleETH -= _amount;
        totalETHFromLPs -= _amount;

        // Send ETH to the recipient
        _transferETH(msg.sender, _amount);

        emit LPBurnedForETH(msg.sender, _amount);
    }

    /// @dev Allow an inheriting contract to have a hook for performing operations after depositing ETH
    function _afterDepositETH(uint256 _totalDeposited) internal virtual {
        uint256 totalToFundFromNewBatches = _totalDeposited;

        while (setOfRecycledDepositBatches.length() > 0) {
            uint256 batchId = setOfRecycledDepositBatches.at(0);
            uint256 ethRecycled = ethRecycledFromBatch[batchId];
            uint256 amountToAssociateWithBatch = ethRecycled >= totalToFundFromNewBatches ? totalToFundFromNewBatches : ethRecycled;

            totalToFundFromNewBatches -= amountToAssociateWithBatch;
            ethRecycledFromBatch[batchId] -= amountToAssociateWithBatch;
            if (ethRecycledFromBatch[batchId] == 0) {
                setOfRecycledDepositBatches.remove(batchId);
            }

            _addUserToBatch(batchId, msg.sender, amountToAssociateWithBatch);

            if (totalToFundFromNewBatches == 0) return;
        }

        uint256 currentBatchNum = depositBatchCount;
        uint256 newComputedBatchNum = totalETHFromLPs / batchSize;
        uint256 numOfBatchesFunded = newComputedBatchNum - currentBatchNum;

        if (numOfBatchesFunded == 0) {
            _addUserToBatch(currentBatchNum, msg.sender, totalToFundFromNewBatches);
        } else {
            uint256 ethBeforeDeposit = totalETHFromLPs - totalToFundFromNewBatches;
            uint256 ethLeftToAllocate = totalToFundFromNewBatches;

            // User can withdraw from multiple batches later
            uint256 ethContributedToThisBatch = batchSize - (ethBeforeDeposit % batchSize);
            for (uint256 i = currentBatchNum; i <= newComputedBatchNum; ++i) {
                _addUserToBatch(i, msg.sender, ethContributedToThisBatch);

                ethLeftToAllocate -= ethContributedToThisBatch;
                if (ethLeftToAllocate >= batchSize) {
                    ethContributedToThisBatch = batchSize;
                } else if (ethLeftToAllocate > 0) {
                    ethContributedToThisBatch = ethLeftToAllocate;
                } else {
                    break;
                }
            }

            // Move the deposit batch count forward
            depositBatchCount = newComputedBatchNum;
        }
    }

    /// @dev Re-usable logic for adding a user to a batch given an amount of batch funding
    function _addUserToBatch(uint256 _batchIndex, address _user, uint256 _amount) internal {
        totalETHFundedPerBatch[_user][_batchIndex] += _amount;
        if (setOfAssociatedDepositBatches[_user].add(_batchIndex)) {
            emit WithdrawalBatchAssociatedWithUser(_user, _batchIndex);
        } else {
            emit WithdrawalBatchUpdated(_user, _batchIndex, totalETHFundedPerBatch[_user][_batchIndex]);
        }
    }

    /// @dev Re-usable logic for reducing amount of user funding for a given batch
    function _reduceUserAmountFundedInBatch(uint256 _batchIndex, address _user, uint256 _amount) internal {
        totalETHFundedPerBatch[_user][_batchIndex] -= _amount;
        if (totalETHFundedPerBatch[_user][_batchIndex] == 0) {
            // Remove the batch from the user and if it succeeds emit an event
            if (setOfAssociatedDepositBatches[_user].remove(_batchIndex)) {
                emit WithdrawalBatchRemovedFromUser(_user, _batchIndex);
            }
        } else {
            emit WithdrawalBatchUpdated(_user, _batchIndex, totalETHFundedPerBatch[_user][_batchIndex]);
        }
    }

    /// @dev Allow liquid staking managers to notify the giant pool about ETH sent to the deposit contract for a key
    function _onStake(bytes calldata _blsPublicKey) internal virtual {
        if (isBLSPubKeyFundedByGiantPool[_blsPublicKey]) revert BLSKeyStaked();

        uint256 numOfRecycledStakedBatches = setOfRecycledStakedBatches.length();
        for (uint256 i; i < numOfRecycledStakedBatches; ++i) {
            uint256 batchToAllocate = setOfRecycledStakedBatches.at(i);
            if (ethRecycledFromBatch[batchToAllocate] == 0) {
                _allocateStakingCountToBlsKey(_blsPublicKey, batchToAllocate);
                setOfRecycledStakedBatches.remove(batchToAllocate);
                // Return out the function since we found a recycled batch to allocate
                return;
            }
        }

        // There were no recycled batches to allocate so we find a new one
        while (stakedBatchCount < depositBatchCount) {
            bool allocated;
            if (ethRecycledFromBatch[stakedBatchCount] == 0) {
                // Allocate batch to BLS key
                _allocateStakingCountToBlsKey(_blsPublicKey, stakedBatchCount);
                allocated = true;
            } else {
                // If we need to skip because the batch is not full, then put it in recycled bucket
                setOfRecycledStakedBatches.add(stakedBatchCount);
            }

            // increment staked count post allocation
            stakedBatchCount++;

            // If we allocated a staked batch count, we can leave this method
            if (allocated) return;
        }

        revert NoFullBatchAvailable();
    }

    /// @dev Allocate a staking count to a BLS public key for later rewards queue
    function _allocateStakingCountToBlsKey(bytes calldata _blsPublicKey, uint256 _count) internal {
        // Allocate redemption path for all LPs with the same deposit count
        allocatedWithdrawalBatchForBlsPubKey[_blsPublicKey] = _count;
        allocatedBlsPubKeyForWithdrawalBatch[_count] = _blsPublicKey;

        // Log the allocation
        emit WithdrawalBatchAssociatedWithBLSKey(_blsPublicKey, _count);
    }

    /// @dev When bringing ETH back to giant pool, free up a staked batch count
    function _onBringBackETHToGiantPool(bytes memory _blsPublicKey) internal virtual {
        uint256 allocatedBatch = allocatedWithdrawalBatchForBlsPubKey[_blsPublicKey];
        if (!isBLSPubKeyFundedByGiantPool[_blsPublicKey]) revert BLSKeyNotStaked();

        setOfRecycledStakedBatches.add(allocatedBatch);

        delete allocatedWithdrawalBatchForBlsPubKey[_blsPublicKey];
        delete allocatedBlsPubKeyForWithdrawalBatch[allocatedBatch];

        emit WithdrawalBatchDisassociatedWithBLSKey(_blsPublicKey, allocatedBatch);
    }

    /// @notice Allow liquid staking managers to notify the giant pool about derivatives minted for a key
    function _onMintDerivatives(bytes calldata _blsPublicKey) internal virtual {}

    /// @notice Allow inheriting contract to specify checks for whether contract is paused
    function _assertContractNotPaused() internal virtual {}
}