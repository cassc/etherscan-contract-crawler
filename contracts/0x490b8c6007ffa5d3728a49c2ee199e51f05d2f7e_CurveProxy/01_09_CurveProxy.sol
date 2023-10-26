// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "Address.sol";
import "SafeERC20.sol";
import "IGaugeController.sol";
import "ILiquidityGauge.sol";
import "PrismaOwnable.sol";

interface IVotingEscrow {
    function create_lock(uint256 amount, uint256 unlock_time) external;

    function increase_amount(uint256 amount) external;

    function increase_unlock_time(uint256 unlock_time) external;
}

interface IMinter {
    function mint(address gauge) external;
}

interface IFeeDistributor {
    function claim() external returns (uint256);

    function token() external view returns (address);
}

interface IAragon {
    function vote(uint256 _voteData, bool _supports, bool _executesIfDecided) external;
}

/**
    @title Prisma Curve Proxy
    @notice Locks CRV in Curve's `VotingEscrow` and interacts with various Curve
            contracts that require / provide benefit from the locked CRV position.
    @dev This contract cannot operate without approval in Curve's VotingEscrow
         smart wallet whitelist. See the Curve documentation for more info:
         https://docs.curve.fi/curve_dao/VotingEscrow/#smart-wallet-whitelist
 */
contract CurveProxy is PrismaOwnable {
    using Address for address;
    using SafeERC20 for IERC20;

    event CrvFeePctSet(uint256 feePct);

    IERC20 public immutable CRV;
    IGaugeController public immutable gaugeController;
    IMinter public immutable minter;
    IVotingEscrow public immutable votingEscrow;
    IFeeDistributor public immutable feeDistributor;
    IERC20 public immutable feeToken;

    uint256 constant WEEK = 604800;
    uint256 constant MAX_LOCK_DURATION = 4 * 365 * 86400; // 4 years

    uint64 public crvFeePct; // fee as a pct out of 10000
    uint64 public unlockTime;

    // the vote manager is approved to call voting-related functions
    // these functions are also callable directly by the owner
    address public voteManager;

    // the deposit manager is approved to call all gauge-related functionality
    // and can permit other contracts to access the same functions on a per-gauge basis
    address public depositManager;

    // permission for contracts which can call gauge-related functionality for a single gauge
    mapping(address caller => address gauge) public perGaugeApproval;

    // permission for callers which can execute arbitrary calls via this contract's `execute` function
    mapping(address caller => mapping(address target => mapping(bytes4 selector => bool))) executePermissions;

    struct GaugeWeightVote {
        address gauge;
        uint256 weight;
    }

    struct TokenBalance {
        IERC20 token;
        uint256 amount;
    }

    constructor(
        address _prismaCore,
        IERC20 _CRV,
        IGaugeController _gaugeController,
        IMinter _minter,
        IVotingEscrow _votingEscrow,
        IFeeDistributor _feeDistributor
    ) PrismaOwnable(_prismaCore) {
        CRV = _CRV;
        gaugeController = _gaugeController;
        minter = _minter;
        votingEscrow = _votingEscrow;
        feeDistributor = _feeDistributor;
        feeToken = IERC20(_feeDistributor.token());

        CRV.approve(address(votingEscrow), type(uint256).max);
    }

    modifier ownerOrVoteManager() {
        require(msg.sender == voteManager || msg.sender == owner(), "Only owner or vote manager");
        _;
    }

    modifier onlyDepositManager() {
        require(msg.sender == depositManager, "Only deposit manager");
        _;
    }

    modifier onlyApprovedGauge(address gauge) {
        require(perGaugeApproval[msg.sender] == gauge || msg.sender == depositManager, "Not approved for gauge");
        _;
    }

    /**
        @notice Grant or revoke permission for `caller` to call one or more
                functions on `target` via this contract.
     */
    function setExecutePermissions(
        address caller,
        address target,
        bytes4[] memory selectors,
        bool permitted
    ) external onlyOwner returns (bool) {
        mapping(bytes4 => bool) storage _executePermission = executePermissions[caller][target];
        for (uint256 i = 0; i < selectors.length; i++) {
            _executePermission[selectors[i]] = permitted;
        }
        return true;
    }

    /**
        @notice Set the fee percent taken on all CRV earned through this contract
        @dev CRV earned as fees is periodically added to the contract's locked position
     */
    function setCrvFeePct(uint64 _feePct) external onlyOwner returns (bool) {
        require(_feePct <= 10000, "Invalid setting");
        crvFeePct = _feePct;
        emit CrvFeePctSet(_feePct);
        return true;
    }

    function setVoteManager(address _voteManager) external onlyOwner returns (bool) {
        voteManager = _voteManager;

        return true;
    }

    function setDepositManager(address _depositManager) external onlyOwner returns (bool) {
        depositManager = _depositManager;

        return true;
    }

    function setPerGaugeApproval(address caller, address gauge) external onlyDepositManager returns (bool) {
        perGaugeApproval[caller] = gauge;

        return true;
    }

    /**
        @notice Claim pending 3CRV fees earned from the veCRV balance
                and transfer the fees onward to the fee receiver
        @dev This method is intentionally left unguarded
     */
    function claimFees() external returns (uint256) {
        feeDistributor.claim();
        uint256 amount = feeToken.balanceOf(address(this));

        feeToken.transfer(PRISMA_CORE.feeReceiver(), amount);

        return amount;
    }

    /**
        @notice Lock any CRV balance within the contract, and extend
                the unlock time to the maximum possible
        @dev This method is intentionally left unguarded
     */
    function lockCRV() external returns (bool) {
        uint256 maxUnlock = ((block.timestamp / WEEK) * WEEK) + MAX_LOCK_DURATION;
        uint256 amount = CRV.balanceOf(address(this));

        _updateLock(amount, unlockTime, maxUnlock);

        return true;
    }

    /**
        @notice Mint CRV rewards earned for a specific gauge
        @dev Once per week, also locks any CRV balance within the contract and extends the lock duration
        @param gauge Address of the gauge to mint CRV for
        @param receiver Address to send the minted CRV to
        @return uint256 Amount of CRV send to the receiver (after the fee)
     */
    function mintCRV(address gauge, address receiver) external onlyApprovedGauge(gauge) returns (uint256) {
        uint256 initial = CRV.balanceOf(address(this));
        minter.mint(gauge);
        uint256 amount = CRV.balanceOf(address(this)) - initial;

        // apply fee prior to transfer
        uint256 fee = (amount * crvFeePct) / 10000;
        amount -= fee;

        CRV.transfer(receiver, amount);

        // lock and extend if needed
        uint256 unlock = unlockTime;
        uint256 maxUnlock = ((block.timestamp / WEEK) * WEEK) + MAX_LOCK_DURATION;
        if (unlock < maxUnlock) {
            _updateLock(initial + fee, unlock, maxUnlock);
        }

        return amount;
    }

    /**
        @notice Submit one or more gauge weight votes
     */
    function voteForGaugeWeights(GaugeWeightVote[] calldata votes) external ownerOrVoteManager returns (bool) {
        for (uint256 i = 0; i < votes.length; i++) {
            gaugeController.vote_for_gauge_weights(votes[i].gauge, votes[i].weight);
        }

        return true;
    }

    /**
        @notice Submit a vote within the Curve DAO
     */
    function voteInCurveDao(IAragon aragon, uint256 id, bool support) external ownerOrVoteManager returns (bool) {
        aragon.vote(id, support, false);

        return true;
    }

    /**
        @notice Approve a 3rd-party caller to deposit into a specific gauge
        @dev Only required for some older Curve gauges
     */
    function approveGaugeDeposit(address gauge, address depositor) external onlyApprovedGauge(gauge) returns (bool) {
        ILiquidityGauge(gauge).set_approve_deposit(depositor, true);

        return true;
    }

    /**
        @notice Set the default receiver for extra rewards on a specific gauge
        @dev Only works on some gauge versions
     */
    function setGaugeRewardsReceiver(address gauge, address receiver) external onlyApprovedGauge(gauge) returns (bool) {
        ILiquidityGauge(gauge).set_rewards_receiver(receiver);

        return true;
    }

    /**
        @notice Withdraw LP tokens from a gauge
        @param gauge Address of the gauge to withdraw from
        @param lpToken Address of the LP token we are withdrawing from the gauge.
                       The contract trusts the caller to supply the correct address.
        @param amount Amount of LP tokens to withdraw
        @param receiver Address to send the LP token to
     */
    function withdrawFromGauge(
        address gauge,
        IERC20 lpToken,
        uint256 amount,
        address receiver
    ) external onlyApprovedGauge(gauge) returns (bool) {
        ILiquidityGauge(gauge).withdraw(amount);
        lpToken.transfer(receiver, amount);

        return true;
    }

    /**
        @notice Transfer arbitrary token balances out of this contract
        @dev Necessary for handling extra rewards on older gauge types
     */
    function transferTokens(
        address receiver,
        TokenBalance[] calldata balances
    ) external onlyDepositManager returns (bool) {
        for (uint256 i = 0; i < balances.length; i++) {
            balances[i].token.safeTransfer(receiver, balances[i].amount);
        }

        return true;
    }

    /**
        @notice Execute an arbitrary function call using this contract
        @dev Callable via the owner, or if explicit permission is given
             to the caller for this target and function selector
     */
    function execute(address target, bytes calldata data) external returns (bytes memory) {
        if (msg.sender != owner()) {
            bytes4 selector = bytes4(data[:4]);
            require(executePermissions[msg.sender][target][selector], "Not permitted");
        }
        return target.functionCall(data);
    }

    function _updateLock(uint256 amount, uint256 unlock, uint256 maxUnlock) internal {
        if (amount > 0) {
            if (unlock == 0) {
                votingEscrow.create_lock(amount, maxUnlock);
                unlockTime = uint64(maxUnlock);
                return;
            }
            votingEscrow.increase_amount(amount);
        }
        if (unlock < maxUnlock) {
            votingEscrow.increase_unlock_time(maxUnlock);
            unlockTime = uint64(maxUnlock);
        }
    }
}