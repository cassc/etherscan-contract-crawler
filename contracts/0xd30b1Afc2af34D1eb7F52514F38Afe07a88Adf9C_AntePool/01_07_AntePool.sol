// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/IAnteTest.sol";
import "./libraries/IterableSet.sol";
import "./libraries/FullMath.sol";
import "./interfaces/IAntePool.sol";

/// @title Ante V0.5 Ante Pool smart contract
/// @notice Deploys an Ante Pool and connects with the Ante Test, manages pools and interactions with users
contract AntePool is IAntePool {
    using SafeMath for uint256;
    using FullMath for uint256;
    using Address for address;
    using IterableAddressSetUtils for IterableAddressSetUtils.IterableAddressSet;

    /// @notice Info related to a single user
    struct UserInfo {
        // How much ETH this user deposited.
        uint256 startAmount;
        // How much decay this side of the pool accrued between (0, this user's
        // entry block), stored as a multiplier expressed as an 18-decimal
        // mantissa. For example, if this side of the pool accrued a decay of
        // 20% during this time period, we'd store 1.2e18 (staking side) or
        // 0.8e18 (challenger side).
        uint256 startDecayMultiplier;
    }

    /// @notice Info related to one side of the pool
    struct PoolSideInfo {
        mapping(address => UserInfo) userInfo;
        // Number of users on this side of the pool.
        uint256 numUsers;
        // Amount staked across all users on this side of the pool, as of
        // `lastUpdateBlock`.`
        uint256 totalAmount;
        // How much decay this side of the pool accrued between (0,
        // lastUpdateBlock), stored as a multiplier expressed as an 18-decimal
        // mantissa. For example, if this side of the pool accrued a decay of
        // 20% during this time period, we'd store 1.2e18 (staking side) or
        // 0.8e18 (challenger side).
        uint256 decayMultiplier;
    }

    /// @notice Info related to eligible challengers
    struct ChallengerEligibilityInfo {
        // Used when test fails to determine which challengers should receive payout
        // i.e., those which haven't staked within 12 blocks prior to test failure
        mapping(address => uint256) lastStakedBlock;
        uint256 eligibleAmount;
    }

    /// @notice Info related to stakers who are currently withdrawing
    struct StakerWithdrawInfo {
        mapping(address => UserUnstakeInfo) userUnstakeInfo;
        uint256 totalAmount;
    }

    /// @notice Info related to a single withdrawing user
    struct UserUnstakeInfo {
        uint256 lastUnstakeTimestamp;
        uint256 amount;
    }

    /// @inheritdoc IAntePool
    IAnteTest public override anteTest;
    /// @inheritdoc IAntePool
    address public override factory;
    /// @inheritdoc IAntePool
    /// @dev pendingFailure set to true until pool is initialized to avoid
    /// people staking in uninitialized pools
    bool public override pendingFailure = true;
    /// @inheritdoc IAntePool
    uint256 public override numTimesVerified;
    /// @dev Percent of staked amount alloted for verifier bounty
    uint256 public constant VERIFIER_BOUNTY = 5;
    /// @inheritdoc IAntePool
    uint256 public override failedBlock;
    /// @inheritdoc IAntePool
    uint256 public override lastVerifiedBlock;
    /// @inheritdoc IAntePool
    address public override verifier;
    /// @inheritdoc IAntePool
    uint256 public override numPaidOut;
    /// @inheritdoc IAntePool
    uint256 public override totalPaidOut;

    /// @dev pool can only be initialized once
    bool internal _initialized = false;
    /// @dev Bounty amount, set when test fails
    uint256 internal _bounty;
    /// @dev Total staked value, after bounty is removed
    uint256 internal _remainingStake;

    /// @dev Amount of decay to charge each challengers ETH per block
    /// 100 gwei decay per block per ETH is ~20-25% decay per year
    uint256 public constant DECAY_RATE_PER_BLOCK = 100 gwei;

    /// @dev Number of blocks a challenger must be staking before they are
    /// eligible for paytout on test failure
    uint8 public constant CHALLENGER_BLOCK_DELAY = 12;

    /// @dev Minimum challenger stake is 0.01 ETH
    uint256 public constant MIN_CHALLENGER_STAKE = 1e16;

    /// @dev Time after initiating withdraw before staker can finally withdraw capital,
    /// starts when staker initiates the unstake action
    uint256 public constant UNSTAKE_DELAY = 24 hours;

    /// @dev convenience constant for 1 ether worth of wei
    uint256 private constant ONE = 1e18;

    /// @inheritdoc IAntePool
    PoolSideInfo public override stakingInfo;
    /// @inheritdoc IAntePool
    PoolSideInfo public override challengerInfo;
    /// @inheritdoc IAntePool
    ChallengerEligibilityInfo public override eligibilityInfo;
    /// @dev All addresses currently challenging the Ante Test
    IterableAddressSetUtils.IterableAddressSet private challengers;
    /// @inheritdoc IAntePool
    StakerWithdrawInfo public override withdrawInfo;

    /// @inheritdoc IAntePool
    uint256 public override lastUpdateBlock;

    /// @notice Modifier function to make sure test hasn't failed yet
    modifier testNotFailed() {
        _testNotFailed();
        _;
    }

    modifier notInitialized() {
        require(!_initialized, "ANTE: Pool already initialized");
        _;
    }

    /// @dev Ante Pools are deployed by Ante Pool Factory, and we store
    /// the address of the factory here
    constructor() {
        factory = msg.sender;
        stakingInfo.decayMultiplier = ONE;
        challengerInfo.decayMultiplier = ONE;
        lastUpdateBlock = block.number;
    }

    /// @inheritdoc IAntePool
    function initialize(IAnteTest _anteTest) external override notInitialized {
        require(msg.sender == factory, "ANTE: only factory can initialize AntePool");
        require(address(_anteTest).isContract(), "ANTE: AnteTest must be a smart contract");
        // Check that anteTest has checkTestPasses function and that it currently passes
        // place check here to minimize reentrancy risk - most external function calls are locked
        // while pendingFailure is true
        require(_anteTest.checkTestPasses(), "ANTE: AnteTest does not implement checkTestPasses or test fails");

        _initialized = true;
        pendingFailure = false;
        anteTest = _anteTest;
    }

    /*****************************************************
     * ================ USER INTERFACE ================= *
     *****************************************************/

    /// @inheritdoc IAntePool
    /// @dev Stake `msg.value` on the side given by `isChallenger`
    function stake(bool isChallenger) external payable override testNotFailed {
        uint256 amount = msg.value;
        require(amount > 0, "ANTE: Cannot stake zero");

        updateDecay();

        PoolSideInfo storage side;
        if (isChallenger) {
            require(amount >= MIN_CHALLENGER_STAKE, "ANTE: Challenger must stake more than 0.01 ETH");
            side = challengerInfo;

            // Record challenger info for future use
            // Challengers are not eligible for rewards if challenging within 12 block window of test failure
            challengers.insert(msg.sender);
            eligibilityInfo.lastStakedBlock[msg.sender] = block.number;
        } else {
            side = stakingInfo;
        }

        UserInfo storage user = side.userInfo[msg.sender];

        // Calculate how much the user already has staked, including the
        // effects of any previously accrued decay.
        //   prevAmount = startAmount * decayMultipiler / startDecayMultiplier
        //   newAmount = amount + prevAmount
        if (user.startAmount > 0) {
            user.startAmount = amount.add(_storedBalance(user, side));
        } else {
            user.startAmount = amount;
            side.numUsers = side.numUsers.add(1);
        }
        side.totalAmount = side.totalAmount.add(amount);

        // Reset the startDecayMultiplier for this user, since we've updated
        // the startAmount to include any already-accrued decay.
        user.startDecayMultiplier = side.decayMultiplier;

        emit Stake(msg.sender, amount, isChallenger);
    }

    /// @inheritdoc IAntePool
    /// @dev Unstake `amount` on the side given by `isChallenger`.
    function unstake(uint256 amount, bool isChallenger) external override testNotFailed {
        require(amount > 0, "ANTE: Cannot unstake 0.");

        updateDecay();

        PoolSideInfo storage side = isChallenger ? challengerInfo : stakingInfo;

        UserInfo storage user = side.userInfo[msg.sender];
        _unstake(amount, isChallenger, side, user);
    }

    /// @inheritdoc IAntePool
    function unstakeAll(bool isChallenger) external override testNotFailed {
        updateDecay();

        PoolSideInfo storage side = isChallenger ? challengerInfo : stakingInfo;

        UserInfo storage user = side.userInfo[msg.sender];

        uint256 amount = _storedBalance(user, side);
        require(amount > 0, "ANTE: Nothing to unstake");

        _unstake(amount, isChallenger, side, user);
    }

    /// @inheritdoc IAntePool
    function withdrawStake() external override testNotFailed {
        UserUnstakeInfo storage unstakeUser = withdrawInfo.userUnstakeInfo[msg.sender];

        require(
            unstakeUser.lastUnstakeTimestamp < block.timestamp - UNSTAKE_DELAY,
            "ANTE: must wait 24 hours to withdraw stake"
        );
        require(unstakeUser.amount > 0, "ANTE: Nothing to withdraw");

        uint256 amount = unstakeUser.amount;
        withdrawInfo.totalAmount = withdrawInfo.totalAmount.sub(amount);
        unstakeUser.amount = 0;

        _safeTransfer(msg.sender, amount);

        emit WithdrawStake(msg.sender, amount);
    }

    /// @inheritdoc IAntePool
    function cancelPendingWithdraw() external override testNotFailed {
        UserUnstakeInfo storage unstakeUser = withdrawInfo.userUnstakeInfo[msg.sender];

        require(unstakeUser.amount > 0, "ANTE: No pending withdraw balance");
        uint256 amount = unstakeUser.amount;
        unstakeUser.amount = 0;

        updateDecay();

        UserInfo storage user = stakingInfo.userInfo[msg.sender];
        if (user.startAmount > 0) {
            user.startAmount = amount.add(_storedBalance(user, stakingInfo));
        } else {
            user.startAmount = amount;
            stakingInfo.numUsers = stakingInfo.numUsers.add(1);
        }
        stakingInfo.totalAmount = stakingInfo.totalAmount.add(amount);
        user.startDecayMultiplier = stakingInfo.decayMultiplier;

        withdrawInfo.totalAmount = withdrawInfo.totalAmount.sub(amount);

        emit CancelWithdraw(msg.sender, amount);
    }

    /// @inheritdoc IAntePool
    function checkTest() external override testNotFailed {
        require(challengers.exists(msg.sender), "ANTE: Only challengers can checkTest");
        require(
            block.number.sub(eligibilityInfo.lastStakedBlock[msg.sender]) > CHALLENGER_BLOCK_DELAY,
            "ANTE: must wait 12 blocks after challenging to call checkTest"
        );

        numTimesVerified = numTimesVerified.add(1);
        lastVerifiedBlock = block.number;
        emit TestChecked(msg.sender);
        if (!_checkTestNoRevert()) {
            updateDecay();
            verifier = msg.sender;
            failedBlock = block.number;
            pendingFailure = true;

            _calculateChallengerEligibility();
            _bounty = getVerifierBounty();

            uint256 totalStake = stakingInfo.totalAmount.add(withdrawInfo.totalAmount);
            _remainingStake = totalStake.sub(_bounty);

            emit FailureOccurred(msg.sender);
        }
    }

    /// @inheritdoc IAntePool
    function claim() external override {
        require(pendingFailure, "ANTE: Test has not failed");

        UserInfo storage user = challengerInfo.userInfo[msg.sender];
        require(user.startAmount > 0, "ANTE: No Challenger Staking balance");

        uint256 amount = _calculateChallengerPayout(user, msg.sender);
        // Zero out the user so they can't claim again.
        user.startAmount = 0;

        numPaidOut = numPaidOut.add(1);
        totalPaidOut = totalPaidOut.add(amount);

        _safeTransfer(msg.sender, amount);
        emit ClaimPaid(msg.sender, amount);
    }

    /// @inheritdoc IAntePool
    function updateDecay() public override {
        (uint256 decayMultiplierThisUpdate, uint256 decayThisUpdate) = _computeDecay();

        lastUpdateBlock = block.number;

        if (decayThisUpdate == 0) return;

        uint256 totalStaked = stakingInfo.totalAmount;
        uint256 totalChallengerStaked = challengerInfo.totalAmount;

        // update totoal accrued decay amounts for challengers
        // decayMultiplier for challengers = decayMultiplier for challengers * decayMultiplierThisUpdate
        // totalChallengerStaked = totalChallengerStaked - decayThisUpdate
        challengerInfo.decayMultiplier = challengerInfo.decayMultiplier.mulDiv(decayMultiplierThisUpdate, ONE);
        challengerInfo.totalAmount = totalChallengerStaked.sub(decayThisUpdate);

        // Update the new accrued decay amounts for stakers.
        //   totalStaked_new = totalStaked_old + decayThisUpdate
        //   decayMultipilerThisUpdate = totalStaked_new / totalStaked_old
        //   decayMultiplier_staker = decayMultiplier_staker * decayMultiplierThisUpdate
        uint256 totalStakedNew = totalStaked.add(decayThisUpdate);

        stakingInfo.decayMultiplier = stakingInfo.decayMultiplier.mulDiv(totalStakedNew, totalStaked);
        stakingInfo.totalAmount = totalStakedNew;
    }

    /*****************************************************
     * ================ VIEW FUNCTIONS ================= *
     *****************************************************/

    /// @inheritdoc IAntePool
    function getTotalChallengerStaked() external view override returns (uint256) {
        return challengerInfo.totalAmount;
    }

    /// @inheritdoc IAntePool
    function getTotalStaked() external view override returns (uint256) {
        return stakingInfo.totalAmount;
    }

    /// @inheritdoc IAntePool
    function getTotalPendingWithdraw() external view override returns (uint256) {
        return withdrawInfo.totalAmount;
    }

    /// @inheritdoc IAntePool
    function getTotalChallengerEligibleBalance() external view override returns (uint256) {
        return eligibilityInfo.eligibleAmount;
    }

    /// @inheritdoc IAntePool
    function getChallengerPayout(address challenger) external view override returns (uint256) {
        UserInfo storage user = challengerInfo.userInfo[challenger];
        require(user.startAmount > 0, "ANTE: No Challenger Staking balance");

        // If called before test failure returns an estimate
        if (pendingFailure) {
            return _calculateChallengerPayout(user, challenger);
        } else {
            uint256 amount = _storedBalance(user, challengerInfo);
            uint256 bounty = getVerifierBounty();
            uint256 totalStake = stakingInfo.totalAmount.add(withdrawInfo.totalAmount);

            return amount.add(amount.mulDiv(totalStake.sub(bounty), challengerInfo.totalAmount));
        }
    }

    /// @inheritdoc IAntePool
    function getStoredBalance(address _user, bool isChallenger) external view override returns (uint256) {
        (uint256 decayMultiplierThisUpdate, uint256 decayThisUpdate) = _computeDecay();

        UserInfo storage user = isChallenger ? challengerInfo.userInfo[_user] : stakingInfo.userInfo[_user];

        if (user.startAmount == 0) return 0;

        require(user.startDecayMultiplier > 0, "ANTE: Invalid startDecayMultiplier");

        uint256 decayMultiplier;

        if (isChallenger) {
            decayMultiplier = challengerInfo.decayMultiplier.mul(decayMultiplierThisUpdate).div(1e18);
        } else {
            uint256 totalStaked = stakingInfo.totalAmount;
            uint256 totalStakedNew = totalStaked.add(decayThisUpdate);
            decayMultiplier = stakingInfo.decayMultiplier.mul(totalStakedNew).div(totalStaked);
        }

        return user.startAmount.mulDiv(decayMultiplier, user.startDecayMultiplier);
    }

    /// @inheritdoc IAntePool
    function getPendingWithdrawAmount(address _user) external view override returns (uint256) {
        return withdrawInfo.userUnstakeInfo[_user].amount;
    }

    /// @inheritdoc IAntePool
    function getPendingWithdrawAllowedTime(address _user) external view override returns (uint256) {
        UserUnstakeInfo storage user = withdrawInfo.userUnstakeInfo[_user];
        require(user.amount > 0, "ANTE: nothing to withdraw");

        return user.lastUnstakeTimestamp.add(UNSTAKE_DELAY);
    }

    /// @inheritdoc IAntePool
    function getCheckTestAllowedBlock(address _user) external view override returns (uint256) {
        return eligibilityInfo.lastStakedBlock[_user].add(CHALLENGER_BLOCK_DELAY);
    }

    /// @inheritdoc IAntePool
    function getUserStartAmount(address _user, bool isChallenger) external view override returns (uint256) {
        return isChallenger ? challengerInfo.userInfo[_user].startAmount : stakingInfo.userInfo[_user].startAmount;
    }

    /// @inheritdoc IAntePool
    function getVerifierBounty() public view override returns (uint256) {
        uint256 totalStake = stakingInfo.totalAmount.add(withdrawInfo.totalAmount);
        return totalStake.mul(VERIFIER_BOUNTY).div(100);
    }

    /*****************************************************
     * =============== INTERNAL HELPERS ================ *
     *****************************************************/

    /// @notice Internal function activating the unstaking action for staker or challengers
    /// @param amount Amount to be removed in wei
    /// @param isChallenger True if user is a challenger
    /// @param side Corresponding staker or challenger pool info
    /// @param user Info related to the user
    /// @dev If the user is a challenger the function the amount can be withdrawn
    /// immediately, if the user is a staker, the amount is moved to the withdraw
    /// info and then the 24 hour waiting period starts
    function _unstake(
        uint256 amount,
        bool isChallenger,
        PoolSideInfo storage side,
        UserInfo storage user
    ) internal {
        // Calculate how much the user has available to unstake, including the
        // effects of any previously accrued decay.
        //   prevAmount = startAmount * decayMultiplier / startDecayMultiplier
        uint256 prevAmount = _storedBalance(user, side);

        if (prevAmount == amount) {
            user.startAmount = 0;
            user.startDecayMultiplier = 0;
            side.numUsers = side.numUsers.sub(1);

            // Remove from set of existing challengers
            if (isChallenger) challengers.remove(msg.sender);
        } else {
            require(amount <= prevAmount, "ANTE: Withdraw request exceeds balance.");
            user.startAmount = prevAmount.sub(amount);
            // Reset the startDecayMultiplier for this user, since we've updated
            // the startAmount to include any already-accrued decay.
            user.startDecayMultiplier = side.decayMultiplier;
        }
        side.totalAmount = side.totalAmount.sub(amount);

        if (isChallenger) _safeTransfer(msg.sender, amount);
        else {
            // Just initiate the withdraw if staker
            UserUnstakeInfo storage unstakeUser = withdrawInfo.userUnstakeInfo[msg.sender];
            unstakeUser.lastUnstakeTimestamp = block.timestamp;
            unstakeUser.amount = unstakeUser.amount.add(amount);

            withdrawInfo.totalAmount = withdrawInfo.totalAmount.add(amount);
        }

        emit Unstake(msg.sender, amount, isChallenger);
    }

    /// @notice Computes the decay differences for staker and challenger pools
    /// @dev Function shared by getStoredBalance view function and internal
    /// decay computation
    /// @return decayMultiplierThisUpdate multiplier factor for this decay change
    /// @return decayThisUpdate amount of challenger value that's decayed in wei
    function _computeDecay() internal view returns (uint256 decayMultiplierThisUpdate, uint256 decayThisUpdate) {
        decayThisUpdate = 0;
        decayMultiplierThisUpdate = ONE;

        if (block.number <= lastUpdateBlock) {
            return (decayMultiplierThisUpdate, decayThisUpdate);
        }
        // Stop charging decay if the test already failed.
        if (pendingFailure) {
            return (decayMultiplierThisUpdate, decayThisUpdate);
        }
        // If we have no stakers or challengers, don't charge any decay.
        uint256 totalStaked = stakingInfo.totalAmount;
        uint256 totalChallengerStaked = challengerInfo.totalAmount;
        if (totalStaked == 0 || totalChallengerStaked == 0) {
            return (decayMultiplierThisUpdate, decayThisUpdate);
        }

        uint256 numBlocks = block.number.sub(lastUpdateBlock);

        // The rest of the function updates the new accrued decay amounts
        //   decayRateThisUpdate = DECAY_RATE_PER_BLOCK * numBlocks
        //   decayMultiplierThisUpdate = 1 - decayRateThisUpdate
        //   decayThisUpdate = totalChallengerStaked * decayRateThisUpdate
        uint256 decayRateThisUpdate = DECAY_RATE_PER_BLOCK.mul(numBlocks);

        // Failsafe to avoid underflow when calculating decayMultiplierThisUpdate
        if (decayRateThisUpdate >= ONE) {
            decayMultiplierThisUpdate = 0;
            decayThisUpdate = totalChallengerStaked;
        } else {
            decayMultiplierThisUpdate = ONE.sub(decayRateThisUpdate);
            decayThisUpdate = totalChallengerStaked.mulDiv(decayRateThisUpdate, ONE);
        }
    }

    /// @notice Calculates total amount of challenger capital eligible for payout.
    /// @dev Any challenger which stakes within 12 blocks prior to test failure
    /// will not get a payout but will be able to withdraw their capital
    /// (minus decay)
    function _calculateChallengerEligibility() internal {
        uint256 cutoffBlock = failedBlock.sub(CHALLENGER_BLOCK_DELAY);
        for (uint256 i = 0; i < challengers.addresses.length; i++) {
            address challenger = challengers.addresses[i];
            if (eligibilityInfo.lastStakedBlock[challenger] < cutoffBlock) {
                eligibilityInfo.eligibleAmount = eligibilityInfo.eligibleAmount.add(
                    _storedBalance(challengerInfo.userInfo[challenger], challengerInfo)
                );
            }
        }
    }

    /// @notice Checks the connected Ante Test, also returns false if checkTestPasses reverts
    /// @return passes bool if the Ante Test passed
    function _checkTestNoRevert() internal returns (bool) {
        try anteTest.checkTestPasses() returns (bool passes) {
            return passes;
        } catch {
            return false;
        }
    }

    /// @notice Calculates individual challenger payout
    /// @param user UserInfo for specified challenger
    /// @param challenger Address of challenger
    /// @dev This is only called after a test is failed, so it's calculated payouts
    /// are no longer estimates
    /// @return Payout amount for challenger in wei
    function _calculateChallengerPayout(UserInfo storage user, address challenger) internal view returns (uint256) {
        // Calculate this user's challenging balance.
        uint256 amount = _storedBalance(user, challengerInfo);
        // Calculate how much of the staking pool this user gets, and add that
        // to the user's challenging balance.
        if (eligibilityInfo.lastStakedBlock[challenger] < failedBlock.sub(CHALLENGER_BLOCK_DELAY)) {
            amount = amount.add(amount.mulDiv(_remainingStake, eligibilityInfo.eligibleAmount));
        }

        return challenger == verifier ? amount.add(_bounty) : amount;
    }

    /// @notice Get the stored balance held by user, including accrued decay
    /// @param user UserInfo of specified user
    /// @param side PoolSideInfo of where the user is located, either staker or challenger side
    /// @dev This includes accrued decay up to `lastUpdateBlock`
    /// @return Balance of the user in wei
    function _storedBalance(UserInfo storage user, PoolSideInfo storage side) internal view returns (uint256) {
        if (user.startAmount == 0) return 0;

        require(user.startDecayMultiplier > 0, "ANTE: Invalid startDecayMultiplier");
        return user.startAmount.mulDiv(side.decayMultiplier, user.startDecayMultiplier);
    }

    /// @notice Transfer function for moving funds
    /// @param to Address to transfer funds to
    /// @param amount Amount to be transferred in wei
    /// @dev Safe transfer function, just in case a rounding error causes the
    /// pool to not have enough ETH
    function _safeTransfer(address payable to, uint256 amount) internal {
        to.transfer(_min(amount, address(this).balance));
    }

    /// @notice Returns the minimum of 2 parameters
    /// @param a Value A
    /// @param b Value B
    /// @return Lower of a or b
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @notice Checks if the test has not failed yet
    function _testNotFailed() internal {
        require(!pendingFailure, "ANTE: Test already failed.");
    }
}