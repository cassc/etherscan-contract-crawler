// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/access/Ownable.sol";
import "../libraries/utils/ReentrancyGuard.sol";
import "../libraries/utils/Pausable.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/Address.sol";

/**
 * @title FalconPool
 * @notice Distribute exchange profits among FLN holders.
 */
contract FalconPool is ReentrancyGuard, Pausable, Ownable {
    //---------- Libraries ----------//
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    //---------- Contracts ----------//
    IERC20 public immutable FLN; // Falcon token contract.

    //---------- Variables ----------//
    uint256 public constant startAt = 1671750000; // Thu Dec 22 2022 23:00:00 GMT+0000.
    uint256 public constant minStake = 1 ether; // Minimal amount to stake.
    uint256 public constant minDuration = 15 minutes; // Minimal duration of stake.
    uint256 public totalHolders; // Total wallets in pool.
    uint256 public totalDistributed; // Total BNB distributed to holders.
    uint256 public totalStaked; // Total balance in stake.
    uint256 private pointsXtoken; // Shared points per token.
    uint256 private unclaimedTokens; // Tokens not claimed.
    uint256 private processedTokens; // Store the processed tokens.
    uint256 private initialBLock; // Initial block for calculate rewards per block.
    uint256 private lastBlock; // Last block distribution for calculate rewards per block.

    //---------- Storage -----------//
    struct Wallet {
        // Tokens amount staked.
        uint256 stakedBal;
        // Date in timestamp of the stake started.
        uint256 startTime;
        // shared points.
        uint256 tokenPoints;
        // pending rewards.
        uint256 pendingTokenbal;
    }

    mapping(address => Wallet) private stakeHolders; // Struct map of wallets in pool.

    //---------- Events -----------//
    event Deposit(uint256 amount, uint256 totalStaked);
    event Withdrawn(address indexed payee, uint256 amount);
    event AddedPoints(address indexed wallet, uint256 amount);
    event RemovedPoints(address indexed wallet, uint256 amount);
    event WalletMigrated(address indexed oldWallet, address indexed newWallet);

    //---------- Constructor ----------//
    constructor(address fln_) public {
        FLN = IERC20(fln_);
        initialBLock = block.number;
        lastBlock = block.number;
    }

    //----------- Internal Functions -----------//
    /**
     * @notice Check the reward amount.
     * @param wallet_ Address of the wallet to check.
     * @return Amount of reward.
     */
    function _getRewards(address wallet_) internal view returns (uint256) {
        uint256 newTokenPoints = pointsXtoken.sub(
            stakeHolders[wallet_].tokenPoints
        );
        return (stakeHolders[wallet_].stakedBal.mul(newTokenPoints)).div(10e18);
    }

    /**
     * @dev Process pending rewards from a wallet.
     * @param wallet_ address of the wallet to be processed.
     */
    function _processRewards(address wallet_) internal virtual {
        uint256 rewards = _getRewards(wallet_);
        if (rewards > 0) {
            unclaimedTokens = unclaimedTokens.sub(rewards);
            processedTokens = processedTokens.add(rewards);
            stakeHolders[wallet_].tokenPoints = pointsXtoken;
            stakeHolders[wallet_].pendingTokenbal = stakeHolders[wallet_]
                .pendingTokenbal
                .add(rewards);
        }
    }

    /**
     * @dev Withdraw pending rewards from a wallet.
     * @param _wallet address of the wallet to withdraw.
     */
    function _harvest(address payable _wallet) internal virtual {
        _processRewards(_wallet);
        uint256 amount = stakeHolders[_wallet].pendingTokenbal;
        if (amount > 0) {
            stakeHolders[_wallet].pendingTokenbal = 0;
            processedTokens = processedTokens.sub(amount);
            _wallet.sendValue(amount);
            emit Withdrawn(_wallet, amount);
        }
    }

    /**
     * @dev Initialize a wallet joined with the current participation points.
     * @param wallet_ address of the wallet to initialize.
     */
    function _initWalletPoints(address wallet_) internal virtual {
        Wallet storage w = stakeHolders[wallet_];
        w.tokenPoints = pointsXtoken;
    }

    /**
     * @dev Add a wallet to stake for the first time.
     * @param wallet_ address of the wallet to add.
     * @param amount_ amount to add.
     */
    function _initStake(address wallet_, uint256 amount_) internal virtual {
        FLN.safeTransferFrom(wallet_, address(this), amount_);
        _initWalletPoints(wallet_);
        stakeHolders[wallet_].startTime = block.timestamp;
        stakeHolders[wallet_].stakedBal = amount_;
        totalStaked = totalStaked.add(amount_);
        totalHolders = totalHolders.add(1);
    }

    /**
     * @dev Add more tokens to stake from an existing wallet.
     * @param wallet_ address of the wallet.
     * @param amount_ amount to add.
     */
    function _addStake(address wallet_, uint256 amount_) internal virtual {
        _processRewards(wallet_);
        FLN.safeTransferFrom(wallet_, address(this), amount_);
        stakeHolders[wallet_].startTime = block.timestamp;
        stakeHolders[wallet_].stakedBal = stakeHolders[wallet_].stakedBal.add(
            amount_
        );
        totalStaked = totalStaked.add(amount_);
    }

    //----------- External Functions -----------//
    /**
     * @dev Disallows direct send by setting a default function without the `payable` flag.
     */
    fallback() external {}

    /**
     * @dev Deposit BNB.
     */
    function deposit() external payable nonReentrant {
        uint256 amount = msg.value;
        require(totalStaked > 0 && amount >= 1000000, "Invalid deposit");
        pointsXtoken = pointsXtoken.add(amount.mul(10e18).div(totalStaked));
        unclaimedTokens = unclaimedTokens.add(amount);
        totalDistributed = totalDistributed.add(amount);
        lastBlock = block.number;
        emit Deposit(amount, totalStaked);
    }

    /**
     * @notice Check if a wallet address is in stake.
     * @return Boolean if in stake or not.
     */
    function isInPool(address wallet_) public view returns (bool) {
        return stakeHolders[wallet_].stakedBal > 0;
    }

    /**
     * @notice Check amount of BNB per block for APY calculation.
     * @return uint256 amount of BNB per block.
     */
    function getRewardsXblock() public view returns (uint256) {
        if (initialBLock == lastBlock) return 0;
        uint256 elapsedBlocks = lastBlock.sub(initialBLock);
        return totalDistributed.div(elapsedBlocks);
    }

    /**
     * @dev Check the reward amount plus the processed balance.
     * @param wallet_ Address of the wallet to check.
     * @return Amount of reward plus the processed for that token.
     */
    function getPendingBal(address wallet_) public view returns (uint256) {
        uint256 newTokenPoints = pointsXtoken.sub(
            stakeHolders[wallet_].tokenPoints
        );
        uint256 pending = stakeHolders[wallet_].pendingTokenbal;
        return
            (stakeHolders[wallet_].stakedBal.mul(newTokenPoints))
                .div(10e18)
                .add(pending);
    }

    /**
     * @notice Check the info of stake for a wallet.
     * @param wallet_ Address of the wallet to check.
     * @return stakedBal amount of tokens staked.
     * @return startTime date in timestamp of the stake started.
     * @return rewards amount of rewards plus the processed.
     */
    function getWalletInfo(address wallet_)
        external
        view
        returns (
            uint256 stakedBal,
            uint256 startTime,
            uint256 rewards
        )
    {
        Wallet storage w = stakeHolders[wallet_];
        return (w.stakedBal, w.startTime, getPendingBal(wallet_));
    }

    /**
     * @notice Stake tokens to receive rewards.
     * @param amount_ Amount of tokens to deposit.
     */
    function stake(uint256 amount_) external whenNotPaused nonReentrant {
        require(startAt <= block.timestamp, "Too soon");
        require(amount_ >= minStake, "Amount too low");
        if (isInPool(_msgSender())) {
            _addStake(_msgSender(), amount_);
        } else {
            _initStake(_msgSender(), amount_);
        }
        emit AddedPoints(_msgSender(), amount_);
    }

    /**
     * @notice Withdraw rewards.
     */
    function harvest() external nonReentrant {
        require(isInPool(_msgSender()), "Not in pool");
        _harvest(_msgSender());
    }

    /**
     * @notice Withdraw tokens from pool.
     */
    function withdrawn(uint256 _amount) external nonReentrant {
        address payable account = _msgSender();
        uint256 amount = _amount;
        require(isInPool(account), "Not in pool");
        require(amount > 0, "Zero amount");
        require(
            stakeHolders[account].startTime.add(minDuration) <= block.timestamp,
            "Too soon"
        );
        _harvest(account);
        uint256 stakedBal = stakeHolders[account].stakedBal;
        bool unStake = amount >= stakedBal;
        amount = unStake ? stakedBal : amount;
        if (unStake) {
            delete stakeHolders[account];
            totalHolders = totalHolders.sub(1);
        } else {
            stakeHolders[account].stakedBal = stakeHolders[account]
                .stakedBal
                .sub(amount);
            require(
                stakeHolders[account].stakedBal >= minStake,
                "Current stake too low"
            );
        }
        FLN.safeTransfer(account, amount);
        totalStaked = totalStaked.sub(amount);
        emit RemovedPoints(account, amount);
    }

    /**
     * @notice Withdraw tokens from pool without rewards.
     */
    function emergencyWithdrawn() external whenPaused nonReentrant {
        address payable account = _msgSender();
        require(isInPool(account), "Not in pool");
        uint256 stakedBal = stakeHolders[account].stakedBal;
        delete stakeHolders[account];
        totalHolders = totalHolders.sub(1);
        FLN.safeTransfer(account, stakedBal);
        totalStaked = totalStaked.sub(stakedBal);
        emit RemovedPoints(account, stakedBal);
    }

    /**
     * @notice Get invalid tokens and send to Governor.
     * @param token_ address of token to send.
     */
    function getInvalidTokens(address to_, address token_) external onlyOwner {
        require(to_ != address(0x0) && token_ != address(0x0), "Zero address");
        require(token_ != address(FLN), "Invalid token");
        uint256 balance = IERC20(token_).balanceOf(address(this));
        IERC20(token_).transfer(to_, balance);
    }

    /**
     * @notice Function for pause and unpause the contract.
     */
    function togglePause() external onlyOwner {
        paused() ? _unpause() : _pause();
    }
}