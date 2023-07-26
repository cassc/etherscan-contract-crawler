// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../../libraries/ScaledMath.sol";
import "../../interfaces/tokenomics/ITORUSLockerV2.sol";
import "../../interfaces/tokenomics/ITORUSToken.sol";
import "../../interfaces/tokenomics/ITORUSVoteLocker.sol";
import "../../interfaces/IController.sol";

contract TORUSLockerV2 is ITORUSLockerV2, Ownable {
    using SafeERC20 for ITORUSToken;
    using SafeERC20 for IERC20;
    using ScaledMath for uint256;
    using ScaledMath for uint128;
    using MerkleProof for MerkleProof.Proof;

    uint128 internal constant _MIN_LOCK_TIME = 120 days;
    uint128 internal constant _MAX_LOCK_TIME = 240 days;
    uint128 internal constant _GRACE_PERIOD = 28 days;
    uint128 internal constant _MIN_BOOST = 1e18;
    uint128 internal constant _MAX_BOOST = 1.5e18;
    uint128 internal constant _KICK_PENALTY = 1e17;
    uint256 internal constant _MAX_KICK_PENALTY_AMOUNT = 1000e18;

    ITORUSToken public immutable torusToken;

    // Boost data
    mapping(address => uint256) public lockedBalance;
    mapping(address => uint256) public lockedBoosted;
    mapping(address => VoteLock[]) public voteLocks;
    mapping(address => uint256) internal _airdroppedBoost;
    mapping(address => bool) public override claimedAirdrop;
    uint64 internal _nextId;
    uint256 public totalLocked;
    uint256 public totalBoosted;
    bool public isShutdown;

    // Fee data
    IERC20 public immutable crv;
    IERC20 public immutable cvx;
    uint256 public accruedFeesIntegralCrv;
    uint256 public accruedFeesIntegralCvx;
    mapping(address => uint256) public perAccountAccruedCrv;
    mapping(address => uint256) public perAccountFeesCrv;
    mapping(address => uint256) public perAccountAccruedCvx;
    mapping(address => uint256) public perAccountFeesCvx;

    address public immutable treasury;
    IController public immutable controller;

    constructor(
        address _controller,
        address _torusToken,
        address _treasury,
        address _crv,
        address _cvx
    ) Ownable() {
        controller = IController(_controller);
        torusToken = ITORUSToken(_torusToken);
        treasury = _treasury;
        crv = IERC20(_crv);
        cvx = IERC20(_cvx);
    }

    function lock(uint256 amount, uint64 lockTime) external override {
        lock(amount, lockTime, false);
    }

    /// @notice Lock an amount of TORUS for vlTORUS.
    /// @param amount Amount of TORUS to lock.
    /// @param lockTime Duration of the lock.
    /// @param relock_ `True` if this is a relock of an existing lock.
    function lock(
        uint256 amount,
        uint64 lockTime,
        bool relock_
    ) public override {
        lockFor(amount, lockTime, relock_, msg.sender);
    }

    /// @notice Lock an amount of TORUS for vlTORUS.
    /// @param amount Amount of TORUS to lock.
    /// @param lockTime Duration of the lock.
    /// @param relock_ `True` if this is a relock of all existing locks.
    /// @param account The account to receive the vlTORUS.
    function lockFor(
        uint256 amount,
        uint64 lockTime,
        bool relock_,
        address account
    ) public override {
        require(!isShutdown, "locker suspended");
        require((_MIN_LOCK_TIME <= lockTime) && (lockTime <= _MAX_LOCK_TIME), "lock time invalid");
        require(!relock_ || msg.sender == account, "relock only for self");
        _feeCheckpoint(account);
        torusToken.safeTransferFrom(msg.sender, address(this), amount);

        uint128 boost = computeBoost(lockTime);
        uint64 unlockTime = uint64(block.timestamp) + lockTime;
        uint256 boostedAmount;

        if (relock_) {
            uint256 length = voteLocks[account].length;
            for (uint256 i; i < length; i++) {
                require(
                    voteLocks[account][i].unlockTime < unlockTime,
                    "cannot move the unlock time up"
                );
            }
            delete voteLocks[account];
            totalBoosted -= lockedBoosted[account];
            lockedBoosted[account] = 0;
            _addVoteLock(account, lockedBalance[account] + amount, unlockTime, boost);
            boostedAmount = (lockedBalance[account] + amount).mulDown(uint256(boost));
        } else {
            _addVoteLock(account, amount, unlockTime, boost);
            boostedAmount = amount.mulDown(boost);
        }
        totalLocked += amount;
        totalBoosted += boostedAmount;
        lockedBalance[account] += amount;
        lockedBoosted[account] += boostedAmount;
        emit Locked(account, amount, unlockTime, relock_);
    }

    /// @notice Process all expired locks of msg.sender and withdraw unlocked TORUS.
    function executeAvailableUnlocks() external override returns (uint256) {
        return executeAvailableUnlocksFor(msg.sender);
    }

    /// @notice Process all expired locks of msg.sender and withdraw unlocked TORUS to `dst`.
    function executeAvailableUnlocksFor(address dst) public override returns (uint256) {
        require(dst != address(0), "invalid destination");
        _feeCheckpoint(msg.sender);
        uint256 sumUnlockable;
        uint256 sumBoosted;
        VoteLock[] storage _pending = voteLocks[msg.sender];
        uint256 i = _pending.length;
        while (i > 0) {
            i = i - 1;

            if (isShutdown || _pending[i].unlockTime <= block.timestamp) {
                sumUnlockable += _pending[i].amount;
                sumBoosted += _pending[i].amount.mulDown(_pending[i].boost);
                _pending[i] = _pending[_pending.length - 1];
                _pending.pop();
            }
        }
        totalLocked -= sumUnlockable;
        totalBoosted -= sumBoosted;
        lockedBalance[msg.sender] -= sumUnlockable;
        lockedBoosted[msg.sender] -= sumBoosted;
        torusToken.safeTransfer(dst, sumUnlockable);
        emit UnlockExecuted(msg.sender, sumUnlockable);
        return sumUnlockable;
    }

    /// @notice Process specified locks of msg.sender and withdraw unlocked TORUS to `dst`.
    /// @param dst Destination address to receive unlocked TORUS.
    /// @param lockIds Array of lock IDs to process.
    /// @return unlocked Amount of TORUS unlocked.
    function executeUnlocks(address dst, uint64[] calldata lockIds)
        public
        override
        returns (uint256)
    {
        _feeCheckpoint(msg.sender);
        uint256 sumUnlockable;
        uint256 sumBoosted;
        VoteLock[] storage _pending = voteLocks[msg.sender];
        for (uint256 idIndex; idIndex < lockIds.length; idIndex++) {
            uint256 index = _getLockIndexById(msg.sender, lockIds[idIndex]);
            require(
                isShutdown || _pending[index].unlockTime <= block.timestamp,
                "lock not expired"
            );
            sumUnlockable += _pending[index].amount;
            sumBoosted += _pending[index].amount.mulDown(_pending[index].boost);
            _pending[index] = _pending[_pending.length - 1];
            _pending.pop();
        }
        totalLocked -= sumUnlockable;
        totalBoosted -= sumBoosted;
        lockedBalance[msg.sender] -= sumUnlockable;
        lockedBoosted[msg.sender] -= sumBoosted;
        torusToken.safeTransfer(dst, sumUnlockable);
        emit UnlockExecuted(msg.sender, sumUnlockable);
        return sumUnlockable;
    }

    /// @notice Get unlocked TORUS balance for an address
    /// @param user Address to get unlocked TORUS balance for
    /// @return Unlocked TORUS balance
    function unlockableBalance(address user) public view override returns (uint256) {
        uint256 sumUnlockable = 0;
        VoteLock[] storage _pending = voteLocks[user];
        uint256 length = _pending.length;
        for (uint256 i; i < length; i++) {
            if (_pending[i].unlockTime <= uint128(block.timestamp)) {
                sumUnlockable += _pending[i].amount;
            }
        }
        return sumUnlockable;
    }

    /// @notice Get unlocked boosted TORUS balance for an address
    /// @param user Address to get unlocked boosted TORUS balance for
    /// @return Unlocked boosted TORUS balance
    function unlockableBalanceBoosted(address user) public view override returns (uint256) {
        uint256 sumUnlockable = 0;
        VoteLock[] storage _pending = voteLocks[user];
        uint256 length = _pending.length;
        for (uint256 i; i < length; i++) {
            if (_pending[i].unlockTime <= uint128(block.timestamp)) {
                sumUnlockable += _pending[i].amount.mulDown(_pending[i].boost);
            }
        }
        return sumUnlockable;
    }

    function shutDown() external override onlyOwner {
        require(!isShutdown, "locker already suspended");
        isShutdown = true;
        emit Shutdown();
    }

    function recoverToken(address token) external override {
        require(
            token != address(torusToken) && token != address(crv) && token != address(cvx),
            "cannot withdraw token"
        );
        IERC20 _token = IERC20(token);
        _token.safeTransfer(treasury, _token.balanceOf(address(this)));
        emit TokenRecovered(token);
    }

    /// @notice Relock a specific lock
    /// @dev Users locking TORUS can create multiple locks therefore individual locks can be relocked separately.
    /// @param lockId Id of the lock to relock.
    /// @param lockTime Duration for which the locks's TORUS amount should be relocked for.
    function relock(uint64 lockId, uint64 lockTime) external override {
        require(!isShutdown, "locker suspended");
        require((_MIN_LOCK_TIME <= lockTime) && (lockTime <= _MAX_LOCK_TIME), "lock time invalid");
        _feeCheckpoint(msg.sender);
        _relock(lockId, lockTime);
    }

    /// @notice Relock specified locks
    /// @param lockIds Ids of the locks to relock.
    /// @param lockTime Duration for which the locks's TORUS amount should be relocked for.
    function relockMultiple(uint64[] calldata lockIds, uint64 lockTime) external override {
        require(!isShutdown, "locker suspended");
        require((_MIN_LOCK_TIME <= lockTime) && (lockTime <= _MAX_LOCK_TIME), "lock time invalid");
        _feeCheckpoint(msg.sender);
        for (uint256 i; i < lockIds.length; i++) {
            _relock(lockIds[i], lockTime);
        }
    }

    function _relock(uint64 lockId, uint64 lockTime) internal {
        uint256 lockIndex = _getLockIndexById(msg.sender, lockId);

        uint128 boost = computeBoost(lockTime);

        uint64 unlockTime = uint64(block.timestamp) + lockTime;

        VoteLock[] storage locks = voteLocks[msg.sender];
        require(locks[lockIndex].unlockTime < unlockTime, "cannot move the unlock time up");
        uint256 amount = locks[lockIndex].amount;
        uint256 previousBoostedAmount = locks[lockIndex].amount.mulDown(locks[lockIndex].boost);
        locks[lockIndex] = locks[locks.length - 1];
        locks.pop();

        _addVoteLock(msg.sender, amount, unlockTime, boost);
        uint256 boostedAmount = amount.mulDown(boost);

        totalBoosted = totalBoosted + boostedAmount - previousBoostedAmount;
        lockedBoosted[msg.sender] =
            lockedBoosted[msg.sender] +
            boostedAmount -
            previousBoostedAmount;

        emit Relocked(msg.sender, amount);
    }

    function relock(uint64 lockTime) external override {
        require(!isShutdown, "locker suspended");
        require((_MIN_LOCK_TIME <= lockTime) && (lockTime <= _MAX_LOCK_TIME), "lock time invalid");
        _feeCheckpoint(msg.sender);

        uint128 boost = computeBoost(lockTime);

        uint64 unlockTime = uint64(block.timestamp) + lockTime;

        uint256 length = voteLocks[msg.sender].length;
        for (uint256 i; i < length; i++) {
            require(
                voteLocks[msg.sender][i].unlockTime < unlockTime,
                "cannot move the unlock time up"
            );
        }
        delete voteLocks[msg.sender];
        totalBoosted -= lockedBoosted[msg.sender];
        lockedBoosted[msg.sender] = 0;
        _addVoteLock(msg.sender, lockedBalance[msg.sender], unlockTime, boost);
        uint256 boostedAmount = lockedBalance[msg.sender].mulDown(uint256(boost));
        totalBoosted += boostedAmount;
        lockedBoosted[msg.sender] += boostedAmount;
        emit Relocked(msg.sender, lockedBalance[msg.sender]);
    }

    /// @notice Kick an expired lock
    function kick(address user, uint64 lockId) external override {
        uint256 lockIndex = _getLockIndexById(user, lockId);
        VoteLock[] storage _pending = voteLocks[user];
        require(
            _pending[lockIndex].unlockTime + _GRACE_PERIOD <= uint128(block.timestamp),
            "cannot kick this lock"
        );
        _feeCheckpoint(user);
        uint256 amount = _pending[lockIndex].amount;
        totalLocked -= amount;
        totalBoosted -= amount.mulDown(_pending[lockIndex].boost);
        lockedBalance[user] -= amount;
        lockedBoosted[user] -= amount.mulDown(_pending[lockIndex].boost);
        uint256 kickPenalty = amount.mulDown(_KICK_PENALTY);
        if (kickPenalty > _MAX_KICK_PENALTY_AMOUNT) {
            kickPenalty = _MAX_KICK_PENALTY_AMOUNT;
        }
        torusToken.safeTransfer(user, amount - kickPenalty);
        torusToken.safeTransfer(msg.sender, kickPenalty);
        emit KickExecuted(user, msg.sender, amount);
        _pending[lockIndex] = _pending[_pending.length - 1];
        _pending.pop();
    }

    function receiveFees(uint256 amountCrv, uint256 amountCvx) external override {
        crv.safeTransferFrom(msg.sender, address(this), amountCrv);
        cvx.safeTransferFrom(msg.sender, address(this), amountCvx);
        accruedFeesIntegralCrv += amountCrv.divDown(totalBoosted);
        accruedFeesIntegralCvx += amountCvx.divDown(totalBoosted);
        emit FeesReceived(msg.sender, amountCrv, amountCvx);
    }

    function claimFees() external override returns (uint256 crvAmount, uint256 cvxAmount) {
        _feeCheckpoint(msg.sender);
        crvAmount = perAccountFeesCrv[msg.sender];
        cvxAmount = perAccountFeesCvx[msg.sender];
        crv.safeTransfer(msg.sender, crvAmount);
        cvx.safeTransfer(msg.sender, cvxAmount);
        perAccountFeesCrv[msg.sender] = 0;
        perAccountFeesCvx[msg.sender] = 0;
        emit FeesClaimed(msg.sender, crvAmount, cvxAmount);
    }

    function claimableFees(address account)
        external
        view
        override
        returns (uint256 claimableCrv, uint256 claimableCvx)
    {
        uint256 boost_ = lockedBoosted[account];
        claimableCrv =
            perAccountFeesCrv[account] +
            boost_.mulDown(accruedFeesIntegralCrv - perAccountAccruedCrv[account]);
        claimableCvx =
            perAccountFeesCvx[account] +
            boost_.mulDown(accruedFeesIntegralCvx - perAccountAccruedCvx[account]);
    }

    function balanceOf(address user) external view override returns (uint256) {
        return totalVoteBoost(user);
    }

    function _feeCheckpoint(address account) internal {
        uint256 boost_ = lockedBoosted[account];
        perAccountFeesCrv[account] += boost_.mulDown(
            accruedFeesIntegralCrv - perAccountAccruedCrv[account]
        );
        perAccountAccruedCrv[account] = accruedFeesIntegralCrv;
        perAccountFeesCvx[account] += boost_.mulDown(
            accruedFeesIntegralCvx - perAccountAccruedCvx[account]
        );
        perAccountAccruedCvx[account] = accruedFeesIntegralCvx;
    }

    function computeBoost(uint128 lockTime) public pure override returns (uint128) {
        return ((_MAX_BOOST - _MIN_BOOST).mulDownUint128(
            (lockTime - _MIN_LOCK_TIME).divDownUint128(_MAX_LOCK_TIME - _MIN_LOCK_TIME)
        ) + _MIN_BOOST);
    }

    function totalVoteBoost(address account) public view override returns (uint256) {
        return totalRewardsBoost(account).mulDown(controller.lpTokenStaker().getBoost(account));
    }

    function totalRewardsBoost(address account) public view override returns (uint256) {
        return
            lockedBoosted[account] -
            unlockableBalanceBoosted(account);
    }

    function userLocks(address account) external view override returns (VoteLock[] memory) {
        return voteLocks[account];
    }

    function _getLockIndexById(address user, uint64 id) internal view returns (uint256) {
        uint256 length_ = voteLocks[user].length;
        for (uint256 i; i < length_; i++) {
            if (voteLocks[user][i].id == id) {
                return i;
            }
        }
        revert("lock doesn't exist");
    }

    function _addVoteLock(
        address user,
        uint256 amount,
        uint64 unlockTime,
        uint128 boost
    ) internal {
        uint64 id = _nextId;
        voteLocks[user].push(VoteLock(amount, unlockTime, boost, id));
        _nextId = id + 1;
    }
}