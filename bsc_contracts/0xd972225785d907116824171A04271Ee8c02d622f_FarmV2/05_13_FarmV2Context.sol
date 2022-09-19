// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract FarmV2Context is ReentrancyGuard, Ownable {
    error InsufficientBalance();
    error TransferFailed();
    error PoolIsNotEmpty();
    error PoolIsNotStarted();
    error InvalidAmount();

    struct Configuration {
        uint256 apr;
        uint256 duration;
        bool isLocked;
        uint256 maxDeposit;
        uint256 rewardsRate;
        uint256 startAt;
        IERC20Metadata rewardsToken;
        IERC20Metadata stakeToken;
    }

    struct Deposit {
        uint256 amount;
        uint256 claimed;
        uint256 harvested;
        uint256 time;
        uint256 lastWithdrawAt;
        bool isEnded;
    }

    uint256 internal constant YEAR = 365 days;

    Configuration internal _config;

    uint256 internal _totalStaked;
    uint256 internal _totalHarvested;
    uint256 internal _totalWithdrawed;
    uint256 internal _totalClaimed;

    mapping(address => uint256) internal _balances;
    mapping(address => Deposit[]) internal _deposits;

    /**
     * @dev Returns the total deposits struct of the account.
     */
    function getDeposits(address account) external view virtual returns (Deposit[] memory) {
        return _deposits[account];
    }

    /**
     * @dev Returns the current APR of this pool.
     */
    function apr() public view virtual returns (uint256) {
        return _config.apr;
    }

    /**
     * @dev Returns the current staked token of the account.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Returns the number of decimals used to simulator float number.
     */
    function decimals() public pure virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev Returns the pool duration.
     *
     * The duration is used for lock the staked tokens if enabled
     * and calculator the earned tokens.
     */
    function duration() public view virtual returns (uint256) {
        return _config.duration;
    }

    /**
     * @dev Determines if the staked tokens will be locked.
     */
    function isLocked() public view virtual returns (bool) {
        return _config.isLocked;
    }

    /**
     * @dev Returns balance of the rewards pool.
     */
    function rewardsPool() public view virtual returns (uint256 balance) {
        balance = rewardsTokenBalance();

        if (rewardsToken() == stakeToken()) {
            unchecked {
                uint256 staked = totalStaked();

                if (balance < staked) {
                    return 0;
                }

                balance -= staked;
            }
        }
    }

    /**
     * @dev Returns the current rewards rate.
     */
    function rewardsRate() public view virtual returns (uint256) {
        return _config.rewardsRate;
    }

    /**
     * @dev Returns the rewards token address.
     */
    function rewardsToken() public view virtual returns (IERC20Metadata) {
        return _config.rewardsToken;
    }

    /**
     * @dev Returns the stake token address.
     */
    function stakeToken() public view virtual returns (IERC20Metadata) {
        return _config.stakeToken;
    }

    /**
     * @dev Returns the pool start time.
     */
    function startAt() public view virtual returns (uint256) {
        return _config.startAt;
    }

    /**
     * @dev Returns the total staked tokens.
     */
    function totalStaked() public view virtual returns (uint256) {
        return _totalStaked;
    }

    /**
     * @dev Determines if the current pool is started.
     */
    function isStarted() internal view virtual returns (bool) {
        return block.timestamp >= startAt(); // solhint-disable-line not-rely-on-time
    }

    /**
     * @dev Returns the maximum depositable amount per account.
     */
    function maxDepositPerAccount() internal view virtual returns (uint256) {
        return _config.maxDeposit;
    }

    /**
     * @dev Returns the rewards token balance of current contract.
     */
    function rewardsTokenBalance() internal view virtual returns (uint256) {
        return rewardsToken().balanceOf(address(this));
    }

    /**
     * @dev Returns the stake token balance of current contract.
     */
    function stakeTokenBalance() internal view virtual returns (uint256) {
        return stakeToken().balanceOf(address(this));
    }
}