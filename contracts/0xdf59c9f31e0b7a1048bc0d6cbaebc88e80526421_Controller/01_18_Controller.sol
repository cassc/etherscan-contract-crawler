// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./mocks/MockToken.sol";
import "./Pool.sol";
import "./RewardToken.sol";
import "./ChadsToken.sol";
// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Controller is ReentrancyGuard {
    using SafeERC20 for Pool;
    using SafeERC20 for IERC20;
    using SafeERC20 for RewardToken;
    using SafeERC20 for ChadsToken;

    RewardToken public rewardToken;
    ChadsToken public depositToken;

    Pool public poolA;
    Pool public poolB;

    Pool public winningPool;
    Pool public losingPool;

    // addresses not allowed to stake:
    mapping(address => bool) public blacklist;

    // the current epoch:
    uint256 public epoch;

    // an mapping to check if the user has already claimed the reward
    mapping(uint => mapping(address => bool)) public claimedEpoch;

    enum Phase {
        Cooldown,
        Staking,
        Claim,
        Swap,
        Trade
    }

    Phase public currentPhase = Phase.Cooldown;

    // timestamp when the current phase started
    uint public currentPhaseStart;

    // used for internal calculations to avoid precision loss:
    uint internal constant PRECISION = 10_000;

    // map of contract admins:
    mapping(address => bool) public admins;

    // the amount of reward tokens to be distributed in the current epoch:
    uint256 public rewardAmount;

    error InvalidPool();
    error InsufficientBalance(uint256 userBalance, uint256 amount);
    error NotStakedInLoosingPool();
    error NoRewardToSwap();
    error NotStakedInWinningPool();
    error AlreadyClaimed();
    error ClaimPeriodEnded();
    error ClaimPeriodNotEnded();
    error SwapPeriodEnded();
    error InsufficientRewardBalance();
    error StakingPeriodNotEnded();
    error InsufficientReward(uint256 tokenAmountSent, uint256 rewardNeededAmount);
    error InsufficientApproval(uint256 allowanceAvailable, uint256 amount);
    error PhaseAlreadyStarted();
    error NoStakers(uint256 winners, uint256 loosers);
    error WithdrawPendingReward();
    error NowAllowedToRecoverThisToken();
    error Blacklisted();
    error InvalidPhase(Phase current, Phase expected);
    error EtherNotAccepted();
    error InvalidRewardAmount();
    error AlreadyStakedInOtherPool();
    error OnlyAdmin();

    event CurrentPhase(Phase phase);
    event Deposit(address indexed user, address indexed pool, uint256 amount);
    event RewardDeposited(
        uint users,
        uint256 rewardDeposited
    );
    event RewardClaimed(address indexed user, uint256 rewardClaimed);
    event RewardSentToLoser(
        address indexed from,
        address indexed to,
        uint256 rewardSent
    );
    event RewardSwapped(
        address indexed user,
        uint256 userStakedBalance,
        uint256 userRewardBalance,
        uint256 rewardAmount
    );

    event Withdraw(address indexed user, uint balanceA, uint balanceB);

    event RewardAmount(uint256 amount);

    event SetBlacklistStatus(address indexed user, bool status);

    event SetAdmin(address indexed admin, bool status);

    /**
     * @dev Constructor function for the Controller contract.
     * @param _admin The address of the admin of the contract.
     * @param _router The address of the router contract.
     */
    constructor( address _admin, address _router ) {

        admins[_admin] = true;
        admins[msg.sender] = true;

        emit SetAdmin(_admin, true);
        emit SetAdmin(msg.sender, true);

        // Create a new ChadsToken contract
        depositToken = new ChadsToken(_admin, _router, "CZvsSEK", "REGULATEIT");

        // Create a new RewardToken contract and allow transfers to this contract
        rewardToken = new RewardToken();
        rewardToken.allowTransfer(address(this), true);

        // Create two new Pool contracts for Alpha Pool A and Alpha Pool B
        poolA = new Pool(payable(depositToken), "Pool A", "Pool-A");
        poolB = new Pool(payable(depositToken), "Pool B", "Pool-B");

        // allow to call views:
        winningPool = poolA;
        losingPool = poolB;

        // set default phase to cooldown, so admin can start Stake phase later:
        currentPhase = Phase.Cooldown;

    }

    fallback() external payable {
        revert EtherNotAccepted();
    }

    receive() external payable {
        revert EtherNotAccepted();
    }

    modifier onlyPhase(Phase phase) {
        if (currentPhase != phase) {
            revert InvalidPhase(currentPhase, phase);
        }
        _;
    }

    modifier onlyAdmin() {
        if(!admins[msg.sender])
            revert OnlyAdmin();
        _;
    }

    function setAdmin(address _minter, bool _status) external onlyAdmin {
        admins[_minter] = _status;
        emit SetAdmin(_minter, _status);
    }

    modifier isBlacklisted() {
        if (blacklist[msg.sender] == true)
            revert Blacklisted();
        _;
    }

    function recover(address tokenAddress) external onlyAdmin {
        if (
            tokenAddress == address(poolA) ||
            tokenAddress == address(poolB) ||
            tokenAddress == address(rewardToken)
        ) revert NowAllowedToRecoverThisToken();
        IERC20 token = IERC20(tokenAddress);
        token.transfer(
            msg.sender,
            token.balanceOf(address(this))
        );
    }

    function recoverFromPool(Pool pool, address tokenAddress) external onlyAdmin {
        pool.recover(tokenAddress, msg.sender);
    }

    function recoverFromRewardToken(address tokenAddress) external onlyAdmin {
        rewardToken.recover(tokenAddress, msg.sender);
    }

    /**
     * @dev Sets the current phase of the contract.
     * Only the contract owner can call this function.
     * @param phase The new phase to set.
     */
    function _setPhase(Phase phase) internal {
        /// Check that the new phase is different from the current phase
        if (phase == currentPhase) revert PhaseAlreadyStarted();

        // Update the current phase

        if (phase == Phase.Cooldown) {
            // during cooldown we disable deposits and enable withdraws,

            // this allow users to exit on any emergency:
            poolA.setDepositEnabled(false);
            poolB.setDepositEnabled(false);

            poolA.setWithdrawStatus(true);
            poolB.setWithdrawStatus(true);

        }else if (phase == Phase.Staking) {
            // during staking we enable deposits and disable withdraws:

            // set the epoch:
            ++epoch;

            poolA.setDepositEnabled(true);
            poolB.setDepositEnabled(true);

            poolA.setWithdrawStatus(false);
            poolB.setWithdrawStatus(false);

        } else if (phase == Phase.Trade) {
            // during trade we disable deposits and withdraws:

            poolA.setDepositEnabled(false);
            poolB.setDepositEnabled(false);

            winningPool.setWithdrawStatus(true);
            losingPool.setWithdrawStatus(true);

        }
        currentPhaseStart = block.timestamp;
        currentPhase = phase;
        emit CurrentPhase(currentPhase);
    }

    // 1 - People stake $PSYFLOP in pool A and pool B and staking is frozen by admin.
    function adminStartStakingPhase() external onlyAdmin {
        _setPhase(Phase.Staking);
    }

    function adminRestartProcess() external onlyAdmin onlyPhase(Phase.Trade) {
        _setPhase(Phase.Staking);
    }

    // 2 - Pools accept deposit up to 24 hours after staking phase is started.
    function stakeInPoolA(uint256 amount) external nonReentrant {
        _stakesInPool(poolA, amount);
    }

    function stakeInPoolB(uint256 amount) external nonReentrant {
        _stakesInPool(poolB, amount);
    }

    function stake(Pool pool, uint256 amount) external nonReentrant {
        _stakesInPool(pool, amount);
    }

    function _stakesInPool(Pool pool, uint256 amount) internal isBlacklisted onlyPhase(Phase.Staking) {
        // insure that the pool is valid
        if (pool != poolA && pool != poolB) revert InvalidPool();

        // check if user already have deposit in the other pool:
        Pool otherPool = pool == poolA ? poolB : poolA;
        if( otherPool.balanceOf(msg.sender) > 0 )
            revert AlreadyStakedInOtherPool();

        // insure that the user has enough balance
        uint256 userBalance = depositToken.balanceOf(msg.sender);
        if (userBalance < amount)
            revert InsufficientBalance(userBalance, amount);

        // insure that the user has approved the controller to transfer the amount
        uint256 allowance = depositToken.allowance(msg.sender, address(this));
        if (allowance < amount) revert InsufficientApproval(allowance, amount);

        // transfer the amount from the user to the controller
        uint256 _before = depositToken.balanceOf(address(this));
        depositToken.safeTransferFrom(msg.sender, address(this), amount);
        uint256 _after = depositToken.balanceOf(address(this));
        amount = _after - _before; // Additional check for deflationary tokens

        // approve the pool to transfer the amount from controller
        depositToken.approve(address(pool), amount);

        // deposit the amount in the pool
        pool.deposit(msg.sender, amount);

        emit Deposit(msg.sender, address(pool), amount);
    }

    // At Claim phase, we choose the winner and mint the RWD to be claimed.
    function adminChooseWinnerAndStartClaim(uint256 _rewardAmount) external onlyAdmin onlyPhase(Phase.Staking) {

        if (_rewardAmount < 1 ether) {
            // just to be safe during the mint share calculation:
            revert InvalidRewardAmount();
        }

        rewardAmount = _rewardAmount;

        // simple random number generation, as this is only callable by owner wallet, it reasonable safe:
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender)));
        if (random % 2 == 0) {
            winningPool = poolA;
        } else {
            winningPool = poolB;
        }
        losingPool = winningPool == poolA ? poolB : poolA;

        if (winningPool.usersLength() == 0 || losingPool.usersLength() == 0) {
            // prevent starting claim phase without sufficient stakers in the pools:
            revert NoStakers(
                winningPool.usersLength(),
                losingPool.usersLength()
            );
        }

        // mint the reward tokens to the controller to be distributed to winners:
        rewardToken.mint(address(this), _rewardAmount);

        // we only change phase in the end to set correct pool info:
        _setPhase(Phase.Claim);

        emit RewardDeposited(
            winningPool.usersLength(),
            _rewardAmount
        );
    }

    // return the amount of claimable reward:
    function claimable(address user) public view returns (uint256) {
        if (currentPhase != Phase.Claim) return 0;
        if (winningPool.balanceOf(user) == 0) return 0;
        if (claimedEpoch[epoch][user] == true) return 0;

        uint256 userStakedBalance = winningPool.balanceOf(user);
        uint256 winningSupply = winningPool.totalSupply();
        uint256 reward = ((userStakedBalance * rewardAmount) / winningSupply);

        return reward;
    }
    // 4 - Pool A and pool B stay untouched. If winner A, winner A addresses get to claim 100000 $X tokens.
    function claim() external nonReentrant onlyPhase(Phase.Claim) {

        // ensure that the user has staked in the winning pool

        if (winningPool.balanceOf(msg.sender) == 0)
            revert NotStakedInWinningPool();

        // prevent double claiming by checking the epoch:
        if( claimedEpoch[epoch][msg.sender] == true)
            revert AlreadyClaimed();

        // calculate user share:
        uint256 reward = claimable(msg.sender);

        if (reward == 0)
            revert InsufficientRewardBalance();

        // transfer reward to user
        rewardToken.safeTransfer(msg.sender, reward);

        // set current epoch as claimed:
        claimedEpoch[epoch][msg.sender] = true;

        emit RewardClaimed(msg.sender, reward);
    }

    // 6 - Team B addresses get to claim 100000 $Y tokens.
    function sendAllRewardToLoser(address to) external nonReentrant {
        _sendRewardToLoser(rewardToken.balanceOf(msg.sender), to);
    }

    function sendRewardFromWinnerToLoser(uint256 amount, address to) external nonReentrant {
        _sendRewardToLoser(amount, to);
    }

    function _sendRewardToLoser(uint256 amount, address to) internal onlyPhase(Phase.Claim) {

        // ensure that the user has enough balance
        if (rewardToken.balanceOf(msg.sender) == 0)
            revert InsufficientRewardBalance();

        // ensure that the user has staked in the winning pool
        if (losingPool.balanceOf(to) == 0) revert NotStakedInLoosingPool();

        // send the reward from the winner to the looser
        rewardToken.otcTransfer(msg.sender, to, amount);

        emit RewardSentToLoser(msg.sender, to, amount);
    }

    function adminStartTradePhase( uint _rewardAmount) external onlyAdmin onlyPhase(Phase.Claim) {

        if (_rewardAmount < 1 ether) {
            // just to be safe during the mint share calculation:
            revert InvalidRewardAmount();
        }

        // check approval to transfer reward to this contract:
        uint256 allowance = depositToken.allowance(msg.sender, address(this));
        if (allowance < _rewardAmount)
            revert InsufficientApproval(allowance, _rewardAmount);

        // transfer the reward to this contract:
        depositToken.safeTransferFrom(msg.sender, address(this), _rewardAmount);

        _setPhase(Phase.Trade);
    }

    function swapRewardToToken() external nonReentrant onlyPhase(Phase.Trade) {

        // ensure that the user has staked in the losing pool, this prevent
        // user transferring the reward to another address:
        if (rewardToken.balanceOf(msg.sender) == 0)
            revert InsufficientRewardBalance();

        uint256 userStakedBalance = losingPool.balanceOf(msg.sender);

        uint256 userRewardBalance = rewardToken.balanceOf(msg.sender); // 666.60 $RWD

        uint256 totalRewards = rewardToken.totalSupply(); // 1000

        uint256 availableRewards = depositToken.balanceOf(address(this)); // 2000

        if (userRewardBalance == 0)
            revert NoRewardToSwap();

        // // Player_A_1 can claim 700/1000 * 2000 = 1400 $PSYFLOP
        uint256 _rewardAmount = (((userRewardBalance*PRECISION)/totalRewards)*availableRewards/PRECISION);

        depositToken.safeTransfer(msg.sender, _rewardAmount);

        // burn the X token from user:
        rewardToken.burn(msg.sender, userRewardBalance);

        emit RewardSwapped(
            msg.sender,
            userStakedBalance,
            userRewardBalance,
            _rewardAmount
        );
    }

    function withdraw() external nonReentrant onlyPhase(Phase.Trade) {
        uint balanceA = poolA.balanceOf(msg.sender);
        uint balanceB = poolB.balanceOf(msg.sender);
        if (balanceA > 0) {
            poolA.withdrawFromController(msg.sender);
        }
        if (balanceB > 0) {
            poolB.withdrawFromController(msg.sender);
        }
        emit Withdraw(msg.sender, balanceA, balanceB);
    }

    // set Cooldown, use to stop the contract:
    function adminSetCooldownPhase() external onlyAdmin {
        _setPhase(Phase.Cooldown);
    }

    // prevent a certain address to deposit:
    function adminSetBlacklist(address user, bool status) external onlyAdmin {
        blacklist[user] = status;
        emit SetBlacklistStatus(user, status);
    }

    // VIEWS
    // return total of users that staked in both pools:
    function getTotalStakedUsers() external view returns (uint256 poolAUsers, uint256 poolBUsers) {
        return (poolA.usersLength(), poolB.usersLength());
    }

    // return the total amount of token staked in both pools:
    function getTotalStaked() external view returns (uint256 poolAStaked, uint256 poolBStaked) {
        return (poolA.totalSupply(), poolB.totalSupply());
    }

    // return the amount of user token and reward tokens:
    function getUserBalance(address user) external view returns (uint256 poolABalance, uint256 poolBBalance, uint256 rewardBalance) {
        return (
            poolA.balanceOf(user),
            poolB.balanceOf(user),
            rewardToken.balanceOf(user)
        );
    }

    // return the amount of reward token that user can claim:
    function getUserPendingReward(address user) external view returns (uint256) {
        return rewardToken.balanceOf(user);
    }

    // return info about winner and looser pool that user staked in:
    function getUserPoolInfo(address user)
    external view returns (Pool.PoolInfo memory winner, Pool.PoolInfo memory looser) {
        if (winningPool.balanceOf(user) > 0) {
            winner = winningPool.getPoolInfo(user);
            looser = losingPool.getPoolInfo(user);
        } else {
            winner = losingPool.getPoolInfo(user);
            looser = winningPool.getPoolInfo(user);
        }
    }

    // get current phase:
    function getPhase() external view returns (Phase phase, uint startedIn) {
        return (currentPhase, currentPhaseStart);
    }

}