// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";

/// @notice Distributes rewards to LP providers.
/// @author Nation3 (https://github.com/nation3/app/blob/main/contracts/src/distributors/BoostedLiquidityDistributor.sol).
/// @dev Inspired by Rari-Capital rewards distributor (https://github.com/Rari-Capital/rari-governance-contracts/blob/master/contracts/RariGovernanceTokenUniswapDistributor.sol).
/// @dev Implemented boosted rewards mechanics from Curve Finance (https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/gauges/LiquidityGauge.vy)
contract BoostedLiquidityDistributor is Initializable, Ownable {
    /*///////////////////////////////////////////////////////////////
                               LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using SafeTransferLib for ERC20;

    /*///////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidStartBlock();
    error InvalidEndBlock();
    error InvalidRewardsAmount();
    error InsufficientDepositBalance();
    error InsufficientRewardsBalance();
    error KickNotAllowed();

    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event RewardsSet(uint256 amount, uint256 startBlock, uint256 endBlock);
    event Claim(address indexed user, uint256 rewards);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event UpdatedBalances(address account, uint256 balance, uint256 totalBalance);

    /*///////////////////////////////////////////////////////////////
                        INMUTABLES / CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev % of the user deposited tokens that counts for working balance without boost
    uint256 internal constant BOOSTLESS_PRODUCTION = 40; // %
    /// @dev Used to correct precision errors on divisions.
    uint256 internal constant PRECISION = 1e30;

    /*///////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The token rewarded to LP providers.
    ERC20 public rewardsToken;
    /// @notice The LP token accepted to deposit by the contract.
    ERC20 public lpToken;
    /// @notice The token used to boost rewards.
    ERC20 public boostToken;

    /// @notice First block to distribute rewards.
    uint256 public startBlock;
    /// @notice Last block to distribute rewards.
    uint256 public endBlock;
    /// @notice Total LP tokens deposited by users.
    uint256 public totalDeposit;
    /// @notice Total balance of the contract after boosts.
    uint256 public totalBalance;
    /// @notice Total rewards beeing distributed.
    uint256 public totalRewards;
    /// @notice Total rewards already distributed to users.
    uint256 public distributedRewards;

    /// @dev Rewards per block on current rewards period.
    /// @dev Only changes on total rewards update.
    /// @dev Precision correction will be applied.
    uint256 internal _blockRewards;
    /// @dev Rewards per LP deposited token at last distribution.
    uint256 internal _rewardsRate;
    /// @dev Last block in which rewards have been distributed.
    uint256 internal _lastDistributedBlock;

    /// @dev Amount of LP tokens deposited by user.
    mapping(address => uint256) public userDeposit;
    /// @dev Balance of user deposit after boost
    mapping(address => uint256) public userBalance;

    /// @dev Rewards per LP token deposited at last user deposit.
    mapping(address => uint256) internal _userRatedRewards;
    /// @dev Distributed rewards to the user at last distribution.
    mapping(address => uint256) internal _userDistributedRewards;
    /// @dev Rewards claimed by user.
    mapping(address => uint256) internal _userClaimedRewards;

    /*///////////////////////////////////////////////////////////////
                             INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    /// @dev Sets both rewards, LP & boost token.
    /// @param _rewardsToken The contract of the rewards token.
    /// @param _lpToken The contract of the liquidity pool tokens.
    /// @param _boostToken The contract of boosting power balance.
    function initialize(
        ERC20 _rewardsToken,
        ERC20 _lpToken,
        address _boostToken
    ) external initializer {
        rewardsToken = _rewardsToken;
        lpToken = _lpToken;
        boostToken = ERC20(_boostToken);
    }

    /*///////////////////////////////////////////////////////////////
                              ADMIN ACTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Set rewards amount & rewards period duration, can be used to update rewards destribution anytime in the future.
    /// @param amount The amount of reward tokens to set as rewards, it expects this amount to be already transferred to the contract.
    /// @param _startBlock Initial block of the rewards distribution.
    /// @param _endBlock Final block of the rewards distribution.
    /// @dev If the rewardsToken contract has not been verified before this could lead to a reentrancy attack
    function setRewards(
        uint256 amount,
        uint256 _startBlock,
        uint256 _endBlock
    ) external virtual onlyOwner {
        if (_startBlock < block.number) revert InvalidStartBlock();
        if (_endBlock <= _startBlock) revert InvalidEndBlock();

        // Distribute possible pending rewards
        _updateRewardsdistribution();

        uint256 _distributedRewards = distributedRewards; // Gas savings
        if (amount <= _distributedRewards) revert InvalidRewardsAmount();
        if (amount - distributedRewards > rewardsToken.balanceOf(address(this))) revert InsufficientRewardsBalance();

        // Set / reset variables
        totalRewards = amount;
        startBlock = _startBlock;
        endBlock = _endBlock;
        // Compute rewards that must be distributed each block, precision correction applied.
        _blockRewards = ((amount - _distributedRewards) * PRECISION) / (_endBlock - _startBlock);

        emit RewardsSet(amount, _startBlock, _endBlock);
    }

    /// @notice Allow the owner to withdraw any ERC20 sent to the contract.
    /// @param token Token to withdraw.
    /// @param to Recipient address of the tokens.
    function recoverTokens(ERC20 token, address to) external virtual onlyOwner returns (uint256 amount) {
        amount = token.balanceOf(address(this));
        if (token == lpToken) {
            amount = amount - totalDeposit;
        } else if (token == rewardsToken) {
            amount = amount - totalRewards;
        }

        token.safeTransfer(to, amount);
    }

    /*///////////////////////////////////////////////////////////////
                                USER ACTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the quantity of unclaimed rewards earned by `account`.
    /// @param account The account of deposited LP tokens.
    /// @return The quantity of unclaimed rewards tokens.
    function getUnclaimedRewards(address account) external view virtual returns (uint256) {
        return _userDistributedRewards[account] - _userClaimedRewards[account];
    }

    /// @notice Kick an account for abusing the boost.
    /// @param account The account to update balances.
    /// @dev Only if their boost power expired.
    function kick(address account) external virtual {
        uint256 _userDeposit = userDeposit[account];
        if (userBalance[account] <= (_userDeposit * BOOSTLESS_PRODUCTION) / 100) revert KickNotAllowed();
        if (boostToken.balanceOf(account) > 0) revert KickNotAllowed();

        _distributeRewards(account);
        _updateBalances(account, _userDeposit, totalDeposit);
    }

    /// @notice Deposits `amount` of LP tokens from sender to this contract.
    /// @param amount The amount ot LP tokens to deposit.
    function deposit(uint256 amount) external virtual {
        // Transfer LP token from sender
        lpToken.safeTransferFrom(msg.sender, address(this), amount);
        uint256 _userDeposit = userDeposit[msg.sender];

        if (block.number > startBlock) {
            if (_userDeposit > 0) {
                // Distribute rewards until this point and update snapshot of rewards per LP Token
                _distributeRewards(msg.sender);
            } else {
                // On first deposit update distribution and set initial user snapshot of rewards per LP Token
                _updateRewardsdistribution();
                _userRatedRewards[msg.sender] = _rewardsRate;
            }
        }

        // Add to staking balance
        _userDeposit = _userDeposit + amount;
        userDeposit[msg.sender] = _userDeposit;
        totalDeposit = totalDeposit + amount;

        _updateBalances(msg.sender, _userDeposit, totalDeposit);

        emit Deposit(msg.sender, amount);
    }

    /// @notice Withdraws `amount` of LP tokens from this contract to sender.
    /// @param amount The amount of LP tokens to withdraw.
    function withdraw(uint256 amount) external virtual {
        uint256 _userDeposit = userDeposit[msg.sender];

        if (amount > _userDeposit) revert InsufficientDepositBalance();
        if (block.number > startBlock) _distributeRewards(msg.sender);

        // Substract from staking balance
        _userDeposit = _userDeposit - amount;
        userDeposit[msg.sender] = _userDeposit;
        totalDeposit = totalDeposit - amount;

        _updateBalances(msg.sender, _userDeposit, totalDeposit);

        // Transfer out to sender
        lpToken.safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }

    /// @notice Claims all of `msg.sender` unclaimed rewards.
    /// @return The quantity of rewards tokens claimed.
    function claimRewards() external virtual returns (uint256) {
        // Distribute rewards to account
        if (block.number > startBlock) _distributeRewards(msg.sender);

        // Get unclaimed rewards
        uint256 unclaimedRewards = _userDistributedRewards[msg.sender] - _userClaimedRewards[msg.sender];
        if (unclaimedRewards <= 0) revert InsufficientRewardsBalance();

        // Register claimed rewards and transfer out
        _userClaimedRewards[msg.sender] = _userClaimedRewards[msg.sender] + unclaimedRewards;

        _updateBalances(msg.sender, userDeposit[msg.sender], totalDeposit);

        rewardsToken.safeTransfer(msg.sender, unclaimedRewards);

        emit Claim(msg.sender, unclaimedRewards);

        return unclaimedRewards;
    }

    /// @notice Withdraw all LP tokens and unclaimed rewards to sender.
    /// @return withdrawAmount The staking amount drained.
    /// @return unclaimedRewards The quantity of rewards tokens claimed.
    function withdrawAndClaim() external virtual returns (uint256 withdrawAmount, uint256 unclaimedRewards) {
        // Distribute rewards to account
        if (block.number > startBlock) _distributeRewards(msg.sender);

        withdrawAmount = userDeposit[msg.sender];
        unclaimedRewards = _userDistributedRewards[msg.sender] - _userClaimedRewards[msg.sender];

        // Drain account staking and update claimed rewards
        userDeposit[msg.sender] = 0;
        totalDeposit = totalDeposit - withdrawAmount;
        _userClaimedRewards[msg.sender] = _userClaimedRewards[msg.sender] + unclaimedRewards;

        _updateBalances(msg.sender, 0, totalDeposit);

        // Transfer out LP tokens & rewards
        lpToken.safeTransfer(msg.sender, withdrawAmount);
        rewardsToken.safeTransfer(msg.sender, unclaimedRewards);

        emit Withdraw(msg.sender, withdrawAmount);
        emit Claim(msg.sender, unclaimedRewards);
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL DISTRIBUTION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Update user balance & total balance after boosts.
    /// @param account The LP token depositor whose balance is being updated.
    /// @param _userDeposit LP tokens deposited by the user to use as base balance.
    /// @param _totalDeposit Total LP tokens deposited in the contract.
    /// @dev If the boostToken contract hasn't been verified before this could lead to a reentrancy attack.
    function _updateBalances(
        address account,
        uint256 _userDeposit,
        uint256 _totalDeposit
    ) internal virtual {
        uint256 userPower = boostToken.balanceOf(account);
        uint256 totalPower = boostToken.totalSupply();

        // Calculate user balance after boost
        // min((userDeposit * 0.4) + (totalDeposit * userVotingPower / totalVotingPower * 0.6), (userDeposit * 0.4))
        uint256 workingBalance = (_userDeposit * BOOSTLESS_PRODUCTION) / 100;
        if (totalPower > 0) {
            workingBalance += (_totalDeposit * userPower * (100 - BOOSTLESS_PRODUCTION)) / (totalPower * 100);
        }
        workingBalance = Math.min(_userDeposit, workingBalance);

        // Update boosted balances
        uint256 lastUserBalance = userBalance[account];
        userBalance[account] = workingBalance;
        totalBalance = totalBalance + workingBalance - lastUserBalance;

        emit UpdatedBalances(account, workingBalance, totalBalance);
    }

    /// @dev Distributes all undistributed rewards earned by `account`.
    /// @dev Do not reverts if there is no rewards to distribute.
    /// @param account The LP Token depositor whose rewards are to be distributed.
    /// @return The quantity of rewards distributed.
    function _distributeRewards(address account) internal virtual returns (uint256) {
        uint256 _userBalance = userBalance[account];
        if (_userBalance <= 0) return 0;

        _updateRewardsdistribution();

        // Compute undistributed rewards from the delta in rewardsRate since the user deposited
        uint256 undistributedRewards = (_userBalance * (_rewardsRate - _userRatedRewards[account])) / PRECISION;
        if (undistributedRewards <= 0) return 0;

        _userRatedRewards[account] = _rewardsRate;
        _userDistributedRewards[account] = _userDistributedRewards[account] + undistributedRewards;

        return undistributedRewards;
    }

    /// @dev Updates rewards distribution values.
    /// Distributes rewards in all blocks, including empty staking ones.
    function _updateRewardsdistribution() internal virtual {
        if (totalRewards <= 0) return;
        if (endBlock <= _lastDistributedBlock) return;
        if (_lastDistributedBlock < startBlock) _lastDistributedBlock = startBlock;

        uint256 blocksToDistribute;
        if (block.number <= endBlock) {
            blocksToDistribute = block.number - _lastDistributedBlock;
        } else {
            blocksToDistribute = endBlock - _lastDistributedBlock;
        }

        uint256 rewardsToDistribute = _blockRewards * blocksToDistribute;

        if (rewardsToDistribute <= 0) return;

        _lastDistributedBlock = block.number;

        // Update rewards per LP token only if there are deposited tokens
        if (totalBalance > 0) {
            distributedRewards = distributedRewards + rewardsToDistribute / PRECISION;
            _rewardsRate = _rewardsRate + rewardsToDistribute / totalBalance;
        }
    }
}