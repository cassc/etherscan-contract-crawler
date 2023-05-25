// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Pausable} from '@openzeppelin/contracts/security/Pausable.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {IERC20, SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import {IUniswapV2Router02} from './IUniswapV2Router02.sol';
import {FeeSharingSystem} from './FeeSharingSystem.sol';

/**
 * @title X2Y2Compounder
 * @notice It sells WETH to X2Y2 using Uniswap V2.
 * @dev Prime shares represent the number of shares in the FeeSharingSystem. When not specified, shares represent secondary shares in this contract.
 */
contract X2Y2Compounder is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Maximum buffer between 2 harvests (in blocks)
    uint256 public constant MAXIMUM_HARVEST_BUFFER_BLOCKS = 6500;

    // FeeSharingSystem (handles the distribution of WETH for X2Y2 stakers)
    FeeSharingSystem public immutable feeSharingSystem;

    // Uniswap V2
    IUniswapV2Router02 public immutable uniswapRouter;

    // Minimum deposit in X2Y2 (it is derived from the FeeSharingSystem)
    uint256 public immutable MINIMUM_DEPOSIT_X2Y2;

    // Token Address
    IERC20 public immutable x2y2Token;

    // Reward token (WETH)
    IERC20 public immutable rewardToken;

    // Whether harvest and WETH selling is triggered automatically at user action
    bool public canHarvest;

    // Buffer between two harvests (in blocks)
    uint256 public harvestBufferBlocks;

    // Last user action block
    uint256 public lastHarvestBlock;

    // Maximum price of X2Y2 (in WETH) multiplied 1e18 (e.g., 0.0004 ETH --> 4e14)
    uint256 public maxPriceX2Y2InWETH;

    // Threshold amount (in rewardToken)
    uint256 public thresholdAmount;

    // Total number of shares outstanding
    uint256 public totalShares;

    // Keeps track of number of user shares
    mapping(address => uint256) public userInfo;

    event ConversionToX2Y2(uint256 amountSold, uint256 amountReceived);
    event Deposit(address indexed user, uint256 amount);
    event FailedConversion();
    event HarvestStart();
    event HarvestStop();
    event NewHarvestBufferBlocks(uint256 harvestBufferBlocks);
    event NewMaximumPriceX2Y2InWETH(uint256 value);
    event NewThresholdAmount(uint256 thresholdAmount);
    event Withdraw(address indexed user, uint256 amount);

    /**
     * @notice Constructor
     * @param _feeSharingSystem address of the fee sharing system contract
     * @param _uniswapRouter address of the Uniswap v3 router
     */
    constructor(FeeSharingSystem _feeSharingSystem, IUniswapV2Router02 _uniswapRouter) {
        feeSharingSystem = FeeSharingSystem(_feeSharingSystem);

        x2y2Token = IERC20(_feeSharingSystem.x2y2Token());
        rewardToken = IERC20(_feeSharingSystem.rewardToken());

        uniswapRouter = _uniswapRouter;

        x2y2Token.approve(address(_feeSharingSystem), type(uint256).max);
        rewardToken.approve(address(_uniswapRouter), type(uint256).max);

        MINIMUM_DEPOSIT_X2Y2 = FeeSharingSystem(_feeSharingSystem).PRECISION_FACTOR();
    }

    /**
     * @notice Deposit X2Y2 tokens
     * @param amount amount to deposit (in X2Y2)
     * @dev There is a limit of 1 X2Y2 per deposit to prevent potential manipulation of the shares
     */
    function deposit(uint256 amount) external nonReentrant whenNotPaused {
        require(amount >= MINIMUM_DEPOSIT_X2Y2, 'Deposit: Amount must be >= 1 X2Y2');

        if (
            block.number > (lastHarvestBlock + harvestBufferBlocks) &&
            canHarvest &&
            totalShares != 0
        ) {
            _harvestAndSellAndCompound();
        }

        // Transfer X2Y2 tokens to this address
        x2y2Token.safeTransferFrom(msg.sender, address(this), amount);

        // Fetch the total number of X2Y2 staked by this contract
        uint256 totalAmountStaked = feeSharingSystem.calculateSharesValueInX2Y2(address(this));

        uint256 currentShares = totalShares == 0
            ? amount
            : (amount * totalShares) / totalAmountStaked;
        require(currentShares != 0, 'Deposit: Fail');

        // Adjust number of shares for user/total
        userInfo[msg.sender] += currentShares;
        totalShares += currentShares;

        // Deposit to FeeSharingSystem contract
        feeSharingSystem.deposit(amount, false);

        emit Deposit(msg.sender, amount);
    }

    /**
     * @notice Redeem shares for X2Y2 tokens
     * @param shares number of shares to redeem
     */
    function withdraw(uint256 shares) external nonReentrant {
        require(
            (shares > 0) && (shares <= userInfo[msg.sender]),
            'Withdraw: Shares equal to 0 or larger than user shares'
        );

        _withdraw(shares);
    }

    /**
     * @notice Withdraw all shares of sender
     */
    function withdrawAll() external nonReentrant {
        require(userInfo[msg.sender] > 0, 'Withdraw: Shares equal to 0');

        _withdraw(userInfo[msg.sender]);
    }

    /**
     * @notice Harvest pending WETH, sell them to X2Y2, and deposit X2Y2 (if possible)
     * @dev Only callable by owner.
     */
    function harvestAndSellAndCompound() external nonReentrant onlyOwner {
        require(totalShares != 0, 'Harvest: No share');
        require(block.number != lastHarvestBlock, 'Harvest: Already done');

        _harvestAndSellAndCompound();
    }

    /**
     * @notice Adjust allowance if necessary
     * @dev Only callable by owner.
     */
    function checkAndAdjustX2Y2TokenAllowanceIfRequired() external onlyOwner {
        x2y2Token.approve(address(feeSharingSystem), type(uint256).max);
    }

    /**
     * @notice Adjust allowance if necessary
     * @dev Only callable by owner.
     */
    function checkAndAdjustRewardTokenAllowanceIfRequired() external onlyOwner {
        rewardToken.approve(address(uniswapRouter), type(uint256).max);
    }

    /**
     * @notice Update harvest buffer block
     * @param _newHarvestBufferBlocks buffer in blocks between two harvest operations
     * @dev Only callable by owner.
     */
    function updateHarvestBufferBlocks(uint256 _newHarvestBufferBlocks) external onlyOwner {
        require(
            _newHarvestBufferBlocks <= MAXIMUM_HARVEST_BUFFER_BLOCKS,
            'Owner: Must be below MAXIMUM_HARVEST_BUFFER_BLOCKS'
        );
        harvestBufferBlocks = _newHarvestBufferBlocks;

        emit NewHarvestBufferBlocks(_newHarvestBufferBlocks);
    }

    /**
     * @notice Start automatic harvest/selling transactions
     * @dev Only callable by owner
     */
    function startHarvest() external onlyOwner {
        canHarvest = true;

        emit HarvestStart();
    }

    /**
     * @notice Stop automatic harvest transactions
     * @dev Only callable by owner
     */
    function stopHarvest() external onlyOwner {
        canHarvest = false;

        emit HarvestStop();
    }

    /**
     * @notice Update maximum price of X2Y2 in WETH
     * @param _newMaxPriceX2Y2InWETH new maximum price of X2Y2 in WETH times 1e18
     * @dev Only callable by owner
     */
    function updateMaxPriceOfX2Y2InWETH(uint256 _newMaxPriceX2Y2InWETH) external onlyOwner {
        maxPriceX2Y2InWETH = _newMaxPriceX2Y2InWETH;

        emit NewMaximumPriceX2Y2InWETH(_newMaxPriceX2Y2InWETH);
    }

    /**
     * @notice Adjust threshold amount for periodic Uniswap v3 WETH --> X2Y2 conversion
     * @param _newThresholdAmount new threshold amount (in WETH)
     * @dev Only callable by owner
     */
    function updateThresholdAmount(uint256 _newThresholdAmount) external onlyOwner {
        thresholdAmount = _newThresholdAmount;

        emit NewThresholdAmount(_newThresholdAmount);
    }

    /**
     * @notice Pause
     * @dev Only callable by owner
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @notice Unpause
     * @dev Only callable by owner
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @notice Calculate price of one share (in X2Y2 token)
     * Share price is expressed times 1e18
     */
    function calculateSharePriceInX2Y2() external view returns (uint256) {
        uint256 totalAmountStakedWithAggregator = feeSharingSystem.calculateSharesValueInX2Y2(
            address(this)
        );

        return
            totalShares == 0
                ? MINIMUM_DEPOSIT_X2Y2
                : (totalAmountStakedWithAggregator * MINIMUM_DEPOSIT_X2Y2) / (totalShares);
    }

    /**
     * @notice Calculate price of one share (in prime share)
     * Share price is expressed times 1e18
     */
    function calculateSharePriceInPrimeShare() external view returns (uint256) {
        (uint256 totalNumberPrimeShares, , ) = feeSharingSystem.userInfo(address(this));

        return
            totalShares == 0
                ? MINIMUM_DEPOSIT_X2Y2
                : (totalNumberPrimeShares * MINIMUM_DEPOSIT_X2Y2) / totalShares;
    }

    /**
     * @notice Calculate shares value of a user (in X2Y2)
     * @param user address of the user
     */
    function calculateSharesValueInX2Y2(address user) external view returns (uint256) {
        uint256 totalAmountStakedWithAggregator = feeSharingSystem.calculateSharesValueInX2Y2(
            address(this)
        );

        return
            totalShares == 0 ? 0 : (totalAmountStakedWithAggregator * userInfo[user]) / totalShares;
    }

    /**
     * @notice Harvest pending WETH, sell them to X2Y2, and deposit X2Y2 (if possible)
     */
    function _harvestAndSellAndCompound() internal {
        // Try/catch to prevent revertions if nothing to harvest
        try feeSharingSystem.harvest() {} catch {}

        uint256 amountToSell = rewardToken.balanceOf(address(this));

        if (amountToSell >= thresholdAmount) {
            bool isExecuted = _sellRewardTokenToX2Y2(amountToSell);

            if (isExecuted) {
                uint256 adjustedAmount = x2y2Token.balanceOf(address(this));

                if (adjustedAmount >= MINIMUM_DEPOSIT_X2Y2) {
                    feeSharingSystem.deposit(adjustedAmount, false);
                }
            }
        }

        // Adjust last harvest block
        lastHarvestBlock = block.number;
    }

    /**
     * @notice Sell WETH to X2Y2
     * @param _amount amount of rewardToken to convert (WETH)
     * @return whether the transaction went through
     */
    function _sellRewardTokenToX2Y2(uint256 _amount) internal returns (bool) {
        uint256 minAmountOut = 0;
        if (maxPriceX2Y2InWETH > 0) {
            minAmountOut = (_amount * 1e18) / maxPriceX2Y2InWETH;
        }

        address[] memory path = new address[](2);
        path[0] = address(rewardToken);
        path[1] = address(x2y2Token);

        try
            uniswapRouter.swapExactTokensForTokens(
                _amount, // amountIn
                minAmountOut, // amountOutMin
                path, // path
                address(this), // to
                block.timestamp // deadline
            )
        returns (uint256[] memory amounts) {
            emit ConversionToX2Y2(amounts[0], amounts[1]);
            return true;
        } catch {
            emit FailedConversion();
            return false;
        }

        return false;
    }

    /**
     * @notice Withdraw shares
     * @param _shares number of shares to redeem
     * @dev The difference between the two snapshots of X2Y2 balances is used to know how many tokens to transfer to user.
     */
    function _withdraw(uint256 _shares) internal {
        if (block.number > (lastHarvestBlock + harvestBufferBlocks) && canHarvest) {
            _harvestAndSellAndCompound();
        }

        // Take snapshot of current X2Y2 balance
        uint256 previousBalanceX2Y2 = x2y2Token.balanceOf(address(this));

        // Fetch total number of prime shares
        (uint256 totalNumberPrimeShares, , ) = feeSharingSystem.userInfo(address(this));

        // Calculate number of prime shares to redeem based on existing shares (from this contract)
        uint256 currentNumberPrimeShares = (totalNumberPrimeShares * _shares) / totalShares;

        // Adjust number of shares for user/total
        userInfo[msg.sender] -= _shares;
        totalShares -= _shares;

        // Withdraw amount equivalent in prime shares
        feeSharingSystem.withdraw(currentNumberPrimeShares, false);

        // Calculate the difference between the current balance of X2Y2 with the previous snapshot
        uint256 amountToTransfer = x2y2Token.balanceOf(address(this)) - previousBalanceX2Y2;

        // Transfer the x2y2 amount back to user
        x2y2Token.safeTransfer(msg.sender, amountToTransfer);

        emit Withdraw(msg.sender, amountToTransfer);
    }
}