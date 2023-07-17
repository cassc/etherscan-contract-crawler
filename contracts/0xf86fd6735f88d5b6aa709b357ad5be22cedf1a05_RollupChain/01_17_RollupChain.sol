// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/* Internal Imports */
import {DataTypes as dt} from "./libraries/DataTypes.sol";
import "./TransitionDisputer.sol";
import "./Registry.sol";
import "./strategies/interfaces/IStrategy.sol";
import "./libraries/MerkleTree.sol";
import "./libraries/Transitions.sol";
import "./interfaces/IWETH.sol";

contract RollupChain is Ownable, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* Fields */
    // The state transition disputer
    TransitionDisputer transitionDisputer;
    // Asset and strategy registry
    Registry registry;

    // All the blocks (prepared and/or executed).
    dt.Block[] public blocks;
    uint256 public countExecuted = 0;

    // Track pending deposits roundtrip status across L1->L2->L1.
    // Each deposit record ID is a count++ (i.e. it's a queue).
    // - L1 deposit() creates it in "pending" status
    // - commitBlock() moves it to "done" status
    // - fraudulent block moves it back to "pending" status
    // - executeBlock() deletes it
    enum PendingDepositStatus {Pending, Done}
    struct PendingDeposit {
        bytes32 dhash; // keccak256(abi.encodePacked(account, assetId, amount))
        uint64 blockId; // rollup block; "pending": baseline of censorship, "done": block holding L2 transition
        PendingDepositStatus status;
    }
    mapping(uint256 => PendingDeposit) public pendingDeposits;
    uint256 public pendingDepositsExecuteHead; // moves up inside blockExecute() -- lowest
    uint256 public pendingDepositsCommitHead; // moves up inside blockCommit() -- intermediate
    uint256 public pendingDepositsTail; // moves up inside L1 deposit() -- highest

    // Track pending withdraws arriving from L2 then done on L1 across 2 phases.
    // A separate mapping is used for each phase:
    // (1) pendingWithdrawCommits: commitBlock() --> executeBlock(), per blockId
    // (2) pendingWithdraws: executeBlock() --> L1-withdraw, per user account address
    //
    // - commitBlock() creates pendingWithdrawCommits entries for the blockId.
    // - executeBlock() aggregates them into per-account pendingWithdraws entries and
    //   deletes the pendingWithdrawCommits entries.
    // - fraudulent block deletes the pendingWithdrawCommits during the blockId rollback.
    // - L1 withdraw() gives the funds and deletes the account's pendingWithdraws entries.
    struct PendingWithdrawCommit {
        address account;
        uint32 assetId;
        uint256 amount;
    }
    mapping(uint256 => PendingWithdrawCommit[]) public pendingWithdrawCommits;

    // Mapping of account => assetId => pendingWithdrawAmount
    mapping(address => mapping(uint32 => uint256)) public pendingWithdraws;

    // Track pending L1-to-L2 balance sync roundtrip across L1->L2->L1.
    // Each balance sync record ID is a count++ (i.e. it's a queue).
    // - L1-to-L2 Balance Sync creates in "pending" status
    // - commitBlock() moves it to "done" status
    // - fraudulent block moves it back to "pending" status
    // - executeBlock() deletes it
    enum PendingBalanceSyncStatus {Pending, Done}
    struct PendingBalanceSync {
        bytes32 bhash; // keccak256(abi.encodePacked(strategyId, delta))
        uint64 blockId; // rollup block; "pending": baseline of censorship, "done": block holding L2 transition
        PendingBalanceSyncStatus status;
    }
    mapping(uint256 => PendingBalanceSync) public pendingBalanceSyncs;
    uint256 public pendingBalanceSyncsExecuteHead; // moves up inside blockExecute() -- lowest
    uint256 public pendingBalanceSyncsCommitHead; // moves up inside blockCommit() -- intermediate
    uint256 public pendingBalanceSyncsTail; // moves up inside L1 Balance Sync -- highest

    // Track the asset balances of strategies to compute deltas after syncBalance() calls.
    mapping(uint32 => uint256) public strategyAssetBalances;

    // per-asset (total deposit - total withdrawal) amount
    mapping(address => uint256) public netDeposits;
    // per-asset (total deposit - total withdrawal) limit
    mapping(address => uint256) public netDepositLimits;

    uint256 public blockChallengePeriod; // delay (in # of ETH blocks) to challenge a rollup block
    uint256 public maxPriorityTxDelay; // delay (in # of rollup blocks) to reflect an L1-initiated tx in a rollup block

    address public operator;

    /* Events */
    event RollupBlockCommitted(uint256 blockId);
    event RollupBlockExecuted(uint256 blockId);
    event RollupBlockReverted(uint256 blockId, string reason);
    event BalanceSync(uint32 strategyId, int256 delta, uint256 syncId);
    event AssetDeposited(address account, uint32 assetId, uint256 amount, uint256 depositId);
    event AssetWithdrawn(address account, uint32 assetId, uint256 amount);
    event OperatorChanged(address previousOperator, address newOperator);

    constructor(
        uint256 _blockChallengePeriod,
        uint256 _maxPriorityTxDelay,
        address _transitionDisputerAddress,
        address _registryAddress,
        address _operator
    ) {
        blockChallengePeriod = _blockChallengePeriod;
        maxPriorityTxDelay = _maxPriorityTxDelay;
        transitionDisputer = TransitionDisputer(_transitionDisputerAddress);
        registry = Registry(_registryAddress);
        operator = _operator;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "caller is not operator");
        _;
    }

    fallback() external payable {}

    receive() external payable {}

    /**********************
     * External Functions *
     **********************/

    /**
     * @notice Deposits ERC20 asset.
     *
     * @param _asset The asset address;
     * @param _amount The amount;
     */
    function deposit(address _asset, uint256 _amount) external whenNotPaused {
        _deposit(_asset, _amount);
        IERC20(_asset).safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @notice Deposits ETH.
     *
     * @param _amount The amount;
     * @param _weth The address for WETH.
     */
    function depositETH(address _weth, uint256 _amount) external payable whenNotPaused {
        require(msg.value == _amount, "ETH amount mismatch");
        _deposit(_weth, _amount);
        IWETH(_weth).deposit{value: _amount}();
    }

    /**
     * @notice Executes pending withdraw of an asset to an account.
     *
     * @param _account The destination account.
     * @param _asset The asset address;
     */
    function withdraw(address _account, address _asset) external whenNotPaused {
        uint256 amount = _withdraw(_account, _asset);
        IERC20(_asset).safeTransfer(_account, amount);
    }

    /**
     * @notice Executes pending withdraw of ETH to an account.
     *
     * @param _account The destination account.
     * @param _weth The address for WETH.
     */
    function withdrawETH(address _account, address _weth) external whenNotPaused {
        uint256 amount = _withdraw(_account, _weth);
        IWETH(_weth).withdraw(amount);
        (bool sent, ) = _account.call{value: amount}("");
        require(sent, "Failed to withdraw ETH");
    }

    /**
     * @notice Submit a prepared batch as a new rollup block.
     *
     * @param _blockId Rollup block id
     * @param _transitions List of layer-2 transitions
     */
    function commitBlock(uint256 _blockId, bytes[] calldata _transitions) external whenNotPaused onlyOperator {
        require(_blockId == blocks.length, "Wrong block ID");

        bytes32[] memory leafs = new bytes32[](_transitions.length);
        for (uint256 i = 0; i < _transitions.length; i++) {
            leafs[i] = keccak256(_transitions[i]);
        }
        bytes32 root = MerkleTree.getMerkleRoot(leafs);

        // Loop over transition and handle these cases:
        // 1- deposit: update the pending deposit record
        // 2- withdraw: create a pending withdraw-commit record
        // 3- commitment sync: fill the "intents" array for future executeBlock()
        // 4- balance sync: update the pending balance sync record

        uint256[] memory intentIndexes = new uint256[](_transitions.length);
        uint32 numIntents = 0;

        for (uint256 i = 0; i < _transitions.length; i++) {
            uint8 transitionType = Transitions.extractTransitionType(_transitions[i]);
            if (
                transitionType == Transitions.TRANSITION_TYPE_COMMIT ||
                transitionType == Transitions.TRANSITION_TYPE_UNCOMMIT
            ) {
                continue;
            } else if (transitionType == Transitions.TRANSITION_TYPE_SYNC_COMMITMENT) {
                intentIndexes[numIntents++] = i;
            } else if (transitionType == Transitions.TRANSITION_TYPE_DEPOSIT) {
                // Update the pending deposit record.
                dt.DepositTransition memory dp = Transitions.decodeDepositTransition(_transitions[i]);
                uint256 depositId = pendingDepositsCommitHead;
                require(depositId < pendingDepositsTail, "invalid deposit transition, no pending deposits");

                PendingDeposit memory pend = pendingDeposits[depositId];
                bytes32 dhash = keccak256(abi.encodePacked(dp.account, dp.assetId, dp.amount));
                require(pend.dhash == dhash, "invalid deposit transition, mismatch or wrong ordering");

                pendingDeposits[depositId].status = PendingDepositStatus.Done;
                pendingDeposits[depositId].blockId = uint64(_blockId); // "done": block holding the transition
                pendingDepositsCommitHead++;
            } else if (transitionType == Transitions.TRANSITION_TYPE_WITHDRAW) {
                // Append the pending withdraw-commit record for this blockId.
                dt.WithdrawTransition memory wd = Transitions.decodeWithdrawTransition(_transitions[i]);
                pendingWithdrawCommits[_blockId].push(
                    PendingWithdrawCommit({account: wd.account, assetId: wd.assetId, amount: wd.amount})
                );
            } else if (transitionType == Transitions.TRANSITION_TYPE_SYNC_BALANCE) {
                // Update the pending balance sync record.
                dt.BalanceSyncTransition memory bs = Transitions.decodeBalanceSyncTransition(_transitions[i]);
                uint256 syncId = pendingBalanceSyncsCommitHead;
                require(syncId < pendingBalanceSyncsTail, "invalid balance sync transition, no pending balance syncs");

                PendingBalanceSync memory pend = pendingBalanceSyncs[syncId];
                bytes32 bhash = keccak256(abi.encodePacked(bs.strategyId, bs.newAssetDelta));
                require(pend.bhash == bhash, "invalid balance sync transition, mismatch or wrong ordering");

                pendingBalanceSyncs[syncId].status = PendingBalanceSyncStatus.Done;
                pendingBalanceSyncs[syncId].blockId = uint64(_blockId); // "done": block holding the transition
                pendingBalanceSyncsCommitHead++;
            }
        }

        // Compute the intent hash.
        bytes32 intentHash = bytes32(0);
        if (numIntents > 0) {
            bytes32[] memory intents = new bytes32[](numIntents);
            for (uint256 i = 0; i < numIntents; i++) {
                intents[i] = keccak256(_transitions[intentIndexes[i]]);
            }
            intentHash = keccak256(abi.encodePacked(intents));
        }

        dt.Block memory rollupBlock =
            dt.Block({
                rootHash: root,
                intentHash: intentHash,
                blockTime: uint128(block.number),
                blockSize: uint128(_transitions.length)
            });
        blocks.push(rollupBlock);

        emit RollupBlockCommitted(_blockId);
    }

    /**
     * @notice Execute a rollup block after it passes the challenge period.
     * @dev Note: only the "intent" transitions (commitment sync) are given to executeBlock() instead of
     * re-sending the whole rollup block. This includes the case of a rollup block with zero intents.
     *
     * @param _intents List of CommitmentSync transitions of the rollup block
     */
    function executeBlock(bytes[] calldata _intents) external whenNotPaused {
        uint256 blockId = countExecuted;
        require(blockId < blocks.length, "No blocks pending execution");
        require(blocks[blockId].blockTime + blockChallengePeriod < block.number, "Block still in challenge period");

        // Validate the input intent transitions.
        bytes32 intentHash = bytes32(0);
        if (_intents.length > 0) {
            bytes32[] memory hashes = new bytes32[](_intents.length);
            for (uint256 i = 0; i < _intents.length; i++) {
                hashes[i] = keccak256(_intents[i]);
            }

            intentHash = keccak256(abi.encodePacked(hashes));
        }

        require(intentHash == blocks[blockId].intentHash, "Invalid block intent transitions");

        // Decode the intent transitions and execute the strategy updates.
        for (uint256 i = 0; i < _intents.length; i++) {
            dt.CommitmentSyncTransition memory cs = Transitions.decodeCommitmentSyncTransition(_intents[i]);

            address stAddr = registry.strategyIndexToAddress(cs.strategyId);
            require(stAddr != address(0), "Unknown strategy ID");
            IStrategy strategy = IStrategy(stAddr);

            if (cs.pendingCommitAmount > cs.pendingUncommitAmount) {
                uint256 commitAmount = cs.pendingCommitAmount.sub(cs.pendingUncommitAmount);
                IERC20(strategy.getAssetAddress()).safeIncreaseAllowance(stAddr, commitAmount);
                strategy.aggregateCommit(commitAmount);
                strategyAssetBalances[cs.strategyId] = strategyAssetBalances[cs.strategyId].add(commitAmount);
            } else if (cs.pendingCommitAmount < cs.pendingUncommitAmount) {
                uint256 uncommitAmount = cs.pendingUncommitAmount.sub(cs.pendingCommitAmount);
                strategy.aggregateUncommit(uncommitAmount);
                strategyAssetBalances[cs.strategyId] = strategyAssetBalances[cs.strategyId].sub(uncommitAmount);
            }
        }

        countExecuted++;

        // Delete pending deposit records finalized by this block.
        while (pendingDepositsExecuteHead < pendingDepositsCommitHead) {
            PendingDeposit memory pend = pendingDeposits[pendingDepositsExecuteHead];
            if (pend.status != PendingDepositStatus.Done || pend.blockId > blockId) {
                break;
            }
            delete pendingDeposits[pendingDepositsExecuteHead];
            pendingDepositsExecuteHead++;
        }

        // Aggregate the pending withdraw-commit records for this blockId into the final
        // pending withdraw records per account (for later L1 withdraw), and delete them.
        for (uint256 i = 0; i < pendingWithdrawCommits[blockId].length; i++) {
            PendingWithdrawCommit memory pwc = pendingWithdrawCommits[blockId][i];

            // Find and increment this account's assetId total amount
            pendingWithdraws[pwc.account][pwc.assetId] += pwc.amount;
        }

        delete pendingWithdrawCommits[blockId];

        // Delete pending balance sync records finalized by this block.
        while (pendingBalanceSyncsExecuteHead < pendingBalanceSyncsCommitHead) {
            PendingBalanceSync memory pend = pendingBalanceSyncs[pendingBalanceSyncsExecuteHead];
            if (pend.status != PendingBalanceSyncStatus.Done || pend.blockId > blockId) {
                break;
            }
            delete pendingBalanceSyncs[pendingBalanceSyncsExecuteHead];
            pendingBalanceSyncsExecuteHead++;
        }

        emit RollupBlockExecuted(blockId);
    }

    /**
     * @notice Sync the latest L1 strategy asset balance to L2
     * @dev L2 operator will submit BalanceSync transition based on the emitted event
     *
     * @param _strategyId Strategy id
     */
    function syncBalance(uint32 _strategyId) external whenNotPaused onlyOperator {
        address stAddr = registry.strategyIndexToAddress(_strategyId);
        require(stAddr != address(0), "Unknown strategy ID");

        uint256 newBalance = IStrategy(stAddr).syncBalance();
        uint256 oldBalance = strategyAssetBalances[_strategyId];
        int256 delta;
        if (newBalance >= oldBalance) {
            delta = int256(newBalance.sub(oldBalance));
        } else {
            delta = -int256(oldBalance.sub(newBalance));
        }
        strategyAssetBalances[_strategyId] = newBalance;

        // Add a pending balance sync record.
        uint256 syncId = pendingBalanceSyncsTail++;
        bytes32 bhash = keccak256(abi.encodePacked(_strategyId, delta));
        pendingBalanceSyncs[syncId] = PendingBalanceSync({
            bhash: bhash,
            blockId: uint64(blocks.length), // "pending": baseline of censorship delay
            status: PendingBalanceSyncStatus.Pending
        });

        emit BalanceSync(_strategyId, delta, syncId);
    }

    /**
     * @notice Dispute a transition in a block.
     * @dev Provide the transition proofs of the previous (valid) transition
     * and the disputed transition, the account proof, and the strategy proof. Both the account proof and
     * strategy proof are always needed even if the disputed transition only updates the account or only
     * updates the strategy because the transition stateRoot = hash(accountStateRoot, strategyStateRoot).
     * If the transition is invalid, prune the chain from that invalid block.
     *
     * @param _prevTransitionProof The inclusion proof of the transition immediately before the fraudulent transition.
     * @param _invalidTransitionProof The inclusion proof of the fraudulent transition.
     * @param _accountProof The inclusion proof of the account involved.
     * @param _strategyProof The inclusion proof of the strategy involved.
     */
    function disputeTransition(
        dt.TransitionProof calldata _prevTransitionProof,
        dt.TransitionProof calldata _invalidTransitionProof,
        dt.AccountProof calldata _accountProof,
        dt.StrategyProof calldata _strategyProof
    ) external {
        uint256 invalidTransitionBlockId = _invalidTransitionProof.blockId;
        dt.Block memory invalidTransitionBlock = blocks[invalidTransitionBlockId];
        require(
            invalidTransitionBlock.blockTime + blockChallengePeriod > block.number,
            "Block challenge period is over"
        );

        bool success;
        bytes memory returnData;
        (success, returnData) = address(transitionDisputer).call(
            abi.encodeWithSelector(
                transitionDisputer.disputeTransition.selector,
                _prevTransitionProof,
                _invalidTransitionProof,
                _accountProof,
                _strategyProof,
                blocks[_prevTransitionProof.blockId],
                invalidTransitionBlock,
                registry
            )
        );

        if (success) {
            string memory reason = abi.decode((returnData), (string));
            _revertBlock(invalidTransitionBlockId, reason);
        } else {
            revert("Failed to dispute");
        }
    }

    /**
     * @notice Dispute if operator failed to reflect an L1-initiated priority tx
     * in a rollup block within the maxPriorityTxDelay
     */
    function disputePriorityTxDelay() external {
        uint256 currentBlockId = getCurrentBlockId();

        if (pendingDepositsCommitHead < pendingDepositsTail) {
            if (currentBlockId.sub(pendingDeposits[pendingDepositsCommitHead].blockId) > maxPriorityTxDelay) {
                _pause();
                return;
            }
        }

        if (pendingBalanceSyncsCommitHead < pendingBalanceSyncsTail) {
            if (currentBlockId.sub(pendingBalanceSyncs[pendingBalanceSyncsCommitHead].blockId) > maxPriorityTxDelay) {
                _pause();
                return;
            }
        }
        revert("Not exceed max priority tx delay");
    }

    /**
     * @notice Called by the owner to pause contract
     * @dev emergency use only
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Called by the owner to unpause contract
     * @dev emergency use only
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Owner drains one type of tokens when the contract is paused
     * @dev emergency use only
     *
     * @param _asset drained asset address
     * @param _amount drained asset amount
     */
    function drainToken(address _asset, uint256 _amount) external whenPaused onlyOwner {
        IERC20(_asset).safeTransfer(msg.sender, _amount);
    }

    /**
     * @notice Owner drains ETH when the contract is paused
     * @dev This is for emergency situations.
     *
     * @param _amount drained ETH amount
     */
    function drainETH(uint256 _amount) external whenPaused onlyOwner {
        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to drain ETH");
    }

    /**
     * @notice Called by the owner to set blockChallengePeriod
     * @param _blockChallengePeriod delay (in # of ETH blocks) to challenge a rollup block
     */
    function setBlockChallengePeriod(uint256 _blockChallengePeriod) external onlyOwner {
        blockChallengePeriod = _blockChallengePeriod;
    }

    /**
     * @notice Called by the owner to set maxPriorityTxDelay
     * @param _maxPriorityTxDelay delay (in # of rollup blocks) to reflect an L1-initiated tx in a rollup block
     */
    function setMaxPriorityTxDelay(uint256 _maxPriorityTxDelay) external onlyOwner {
        maxPriorityTxDelay = _maxPriorityTxDelay;
    }

    /**
     * @notice Called by the owner to set operator account address
     * @param _operator operator's ETH address
     */
    function setOperator(address _operator) external onlyOwner {
        emit OperatorChanged(operator, _operator);
        operator = _operator;
    }

    /**
     * @notice Called by the owner to set net deposit limit
     * @param _asset asset token address
     * @param _limit asset net deposit limit amount
     */
    function setNetDepositLimit(address _asset, uint256 _limit) external onlyOwner {
        uint32 assetId = registry.assetAddressToIndex(_asset);
        require(assetId != 0, "Unknown asset");
        netDepositLimits[_asset] = _limit;
    }

    /**
     * @notice Get current rollup block id
     * @return current rollup block id
     */
    function getCurrentBlockId() public view returns (uint256) {
        return blocks.length - 1;
    }

    /*********************
     * Private Functions *
     *********************/

    /**
     * @notice internal deposit processing without actual token transfer.
     *
     * @param _asset The asset token address.
     * @param _amount The asset token amount.
     */
    function _deposit(address _asset, uint256 _amount) private {
        address account = msg.sender;
        uint32 assetId = registry.assetAddressToIndex(_asset);

        require(assetId != 0, "Unknown asset");

        uint256 netDeposit = netDeposits[_asset].add(_amount);
        require(netDeposit <= netDepositLimits[_asset], "net deposit exceeds limit");
        netDeposits[_asset] = netDeposit;

        // Add a pending deposit record.
        uint256 depositId = pendingDepositsTail++;
        bytes32 dhash = keccak256(abi.encodePacked(account, assetId, _amount));
        pendingDeposits[depositId] = PendingDeposit({
            dhash: dhash,
            blockId: uint64(blocks.length), // "pending": baseline of censorship delay
            status: PendingDepositStatus.Pending
        });

        emit AssetDeposited(account, assetId, _amount, depositId);
    }

    /**
     * @notice internal withdrawal processing without actual token transfer.
     *
     * @param _account The destination account.
     * @param _asset The asset token address.
     * @return amount to withdraw
     */
    function _withdraw(address _account, address _asset) private returns (uint256) {
        uint32 assetId = registry.assetAddressToIndex(_asset);
        require(assetId > 0, "Asset not registered");

        uint256 amount = pendingWithdraws[_account][assetId];
        require(amount > 0, "Nothing to withdraw");

        if (netDeposits[_asset] < amount) {
            netDeposits[_asset] = 0;
        } else {
            netDeposits[_asset] = netDeposits[_asset].sub(amount);
        }
        pendingWithdraws[_account][assetId] = 0;

        emit AssetWithdrawn(_account, assetId, amount);
        return amount;
    }

    /**
     * @notice Revert rollup block on dispute success
     *
     * @param _blockId Rollup block id
     * @param _reason Revert reason
     */
    function _revertBlock(uint256 _blockId, string memory _reason) private {
        // pause contract
        _pause();

        // revert blocks and pending states
        while (blocks.length > _blockId) {
            pendingWithdrawCommits[blocks.length - 1];
            blocks.pop();
        }
        bool first;
        for (uint256 i = pendingDepositsExecuteHead; i < pendingDepositsTail; i++) {
            if (pendingDeposits[i].blockId >= _blockId) {
                if (!first) {
                    pendingDepositsCommitHead = i;
                    first = true;
                }
                pendingDeposits[i].blockId = uint64(_blockId);
                pendingDeposits[i].status = PendingDepositStatus.Pending;
            }
        }
        first = false;
        for (uint256 i = pendingBalanceSyncsExecuteHead; i < pendingBalanceSyncsTail; i++) {
            if (pendingBalanceSyncs[i].blockId >= _blockId) {
                if (!first) {
                    pendingBalanceSyncsCommitHead = i;
                    first = true;
                }
                pendingBalanceSyncs[i].blockId = uint64(_blockId);
                pendingBalanceSyncs[i].status = PendingBalanceSyncStatus.Pending;
            }
        }

        emit RollupBlockReverted(_blockId, _reason);
    }
}