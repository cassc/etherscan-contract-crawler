// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./libraries/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract LiquidityBootstrapAuction is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public immutable asto;
    IERC20 public immutable usdc;
    uint256 public immutable totalRewardAmount;
    uint256 public auctionStartTime;
    uint256 public totalDepositedUSDC;
    uint256 public totalDepositedASTO;
    address public liquidityPair;
    uint256 public lpTokenAmount;
    uint16 public constant REWARDS_RELEASE_DURATION_IN_WEEKS = 12;
    uint16 public constant HOURS_PER_DAY = 24;
    uint256 internal constant SECONDS_PER_WEEK = 604800;
    uint256 public constant SECONDS_PER_DAY = 86400;
    uint256 public constant SECONDS_PER_HOUR = 3600;

    mapping(address => uint256) public depositedUSDC;
    mapping(address => uint256) public depositedASTO;
    mapping(address => bool) public usdcWithdrawnOnDay6;
    mapping(address => bool) public usdcWithdrawnOnDay7;
    mapping(address => uint256) public rewardClaimed;
    mapping(address => uint256) public lpClaimed;

    struct Timeline {
        uint256 auctionStartTime;
        uint256 astoDepositEndTime;
        uint256 usdcDepositEndTime;
        uint256 auctionEndTime;
    }

    struct Stats {
        uint256 totalDepositedASTO;
        uint256 totalDepositedUSDC;
        uint256 depositedASTO;
        uint256 depositedUSDC;
    }

    event ASTODeposited(address indexed recipient, uint256 amount, Stats stats);
    event USDCDeposited(address indexed recipient, uint256 amount, Stats stats);
    event USDCWithdrawn(address indexed recipient, uint256 amount, Stats stats);
    event RewardsClaimed(address indexed recipient, uint256 amount);
    event LiquidityAdded(uint256 astoAmount, uint256 usdcAmount, uint256 lpTokenAmount);
    event TokenWithdrawn(address indexed recipient, uint256 tokenAmount);

    /**
     * @notice Initialize the contract
     * @param multisig Multisig address as the contract owner
     * @param _asto $ASTO contract address
     * @param _usdc $USDC contract address
     * @param rewardAmount Total $ASTO token amount as rewards
     * @param startTime Auction start timestamp
     */
    constructor(
        address multisig,
        IERC20 _asto,
        IERC20 _usdc,
        uint256 rewardAmount,
        uint256 startTime
    ) {
        require(address(_asto) != address(0), "invalid token address");
        require(address(_usdc) != address(0), "invalid token address");

        asto = _asto;
        usdc = _usdc;
        totalRewardAmount = rewardAmount;
        auctionStartTime = startTime;
        _transferOwnership(multisig);
    }

    /**
     * @notice Deposit `astoAmount` $ASTO and `usdcAmount` $USDC to the contract
     * @param astoAmount $ASTO token amount to deposit
     * @param usdcAmount $USDC token amount to deposit
     */
    function deposit(uint256 astoAmount, uint256 usdcAmount) external {
        if (astoAmount > 0) {
            depositASTO(astoAmount);
        }

        if (usdcAmount > 0) {
            depositUSDC(usdcAmount);
        }
    }

    /**
     * @notice Deposit `amount` $ASTO to the contract
     * @param amount $ASTO token amount to deposit
     */
    function depositASTO(uint256 amount) public nonReentrant {
        require(astoDepositAllowed(), "deposit not allowed");
        require(asto.balanceOf(msg.sender) >= amount, "insufficient balance");

        depositedASTO[msg.sender] += amount;
        totalDepositedASTO += amount;
        emit ASTODeposited(msg.sender, amount, stats(msg.sender));

        asto.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice Deposit `amount` $USDC to the contract
     * @param amount $USDC token amount to deposit
     */
    function depositUSDC(uint256 amount) public nonReentrant {
        require(usdcDepositAllowed(), "deposit not allowed");
        require(usdc.balanceOf(msg.sender) >= amount, "insufficient balance");

        depositedUSDC[msg.sender] += amount;
        totalDepositedUSDC += amount;
        emit USDCDeposited(msg.sender, amount, stats(msg.sender));

        usdc.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice Get withdrawable $USDC amount to `recipient`
     * @param recipient Wallet address to calculate for
     * @return Withdrawable $USDC token amount
     */
    function withdrawableUSDCAmount(address recipient) public view returns (uint256) {
        if (currentTime() < auctionStartTime || currentTime() >= auctionEndTime()) {
            return 0;
        }

        // USDC can only be withdrawn once on Day 6 and once on Day 7
        // Withdrawable USDC amount on Day 6: half of deposited USDC amount
        // Withdrawable USDC amount on Day 7: hourly linear decrease from half of deposited USDC amount to 0
        if (currentTime() < usdcDepositEndTime()) {
            return depositedUSDC[recipient];
        } else if (currentTime() >= usdcWithdrawLastDay()) {
            // On day 7, $USDC is only allowed to be withdrawn once
            if (usdcWithdrawnOnDay7[recipient]) {
                return 0;
            }
            uint256 elapsedTime = currentTime() - usdcWithdrawLastDay();
            uint256 maxAmount = depositedUSDC[recipient] / 2;

            if (elapsedTime > SECONDS_PER_DAY) {
                return 0;
            }

            // Elapsed time in hours, range from 1 to 24
            uint256 elapsedTimeRatio = (SECONDS_PER_DAY - elapsedTime) / SECONDS_PER_HOUR + 1;

            return (maxAmount * elapsedTimeRatio) / HOURS_PER_DAY;
        }
        // On day 6, $USDC is only allowed to be withdrawn once
        return usdcWithdrawnOnDay6[recipient] ? 0 : depositedUSDC[msg.sender] / 2;
    }

    /**
     * @notice Withdraw `amount` $USDC
     * @param amount The $USDC token amount to withdraw
     */
    function withdrawUSDC(uint256 amount) external nonReentrant {
        require(usdcWithdrawAllowed(), "withdraw not allowed");
        require(amount > 0, "amount should greater than zero");
        require(amount <= withdrawableUSDCAmount(msg.sender), "amount exceeded allowance");

        if (currentTime() >= usdcWithdrawLastDay()) {
            usdcWithdrawnOnDay7[msg.sender] = true;
        } else if (currentTime() >= usdcDepositEndTime()) {
            usdcWithdrawnOnDay6[msg.sender] = true;
        }

        depositedUSDC[msg.sender] -= amount;
        totalDepositedUSDC -= amount;

        emit USDCWithdrawn(msg.sender, amount, stats(msg.sender));

        usdc.safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Calculate optimal swap amount to AMM based exchange
     * @param amtA Token amount for token A
     * @param amtB Token amount for token B
     * @param resA Reserved token amount for token A in LP pool
     * @param resB Reserved token amount for token B in LP pool
     * @return The optimal swap amount for token A
     */
    function optimalDeposit(
        uint256 amtA,
        uint256 amtB,
        uint256 resA,
        uint256 resB
    ) internal pure returns (uint256) {
        // This function implements the forumal mentioned in the following article
        // https://blog.alphafinance.io/onesideduniswap/
        require(amtA.mul(resB) >= amtB.mul(resA), "invalid token amount");

        uint256 a = 997;
        uint256 b = uint256(1997).mul(resA);
        uint256 _c = (amtA.mul(resB)).sub(amtB.mul(resA));
        uint256 c = _c.mul(1000).div(amtB.add(resB)).mul(resA);

        uint256 d = a.mul(c).mul(4);
        uint256 e = Math.sqrt(b.mul(b).add(d));

        uint256 numerator = e.sub(b);
        uint256 denominator = a.mul(2);

        return numerator.div(denominator);
    }

    /**
     * @notice Add all deposited $ASTO and $USDC to AMM based exchange
     * @param router Router contract address to the exchange
     * @param factory Factory contract address to the exchange
     */
    function addLiquidityToExchange(address router, address factory) external nonReentrant onlyOwner {
        require(currentTime() >= auctionEndTime(), "auction not finished");
        require(totalDepositedUSDC > 0, "no USDC deposited");
        require(totalDepositedASTO > 0, "no ASTO deposited");

        // 1. Approve the router contract to get all tokens from this contract
        usdc.approve(router, type(uint256).max);
        asto.approve(router, type(uint256).max);

        uint256 usdcSent;
        uint256 astoSent;

        // 2. Add deposited tokens to the exchange as much as posisble
        // The tokens will be transferred to the liquidity pool if it exists, otherwise a new trading pair will be created
        (usdcSent, astoSent, lpTokenAmount) = IUniswapV2Router02(router).addLiquidity(
            address(usdc),
            address(asto),
            totalDepositedUSDC,
            totalDepositedASTO,
            0,
            0,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );

        // Store the LP contract address
        liquidityPair = IUniswapV2Factory(factory).getPair(address(asto), address(usdc));

        // Both deposited $ASTO and $USDC are transferred to the liquidity pool,
        // which means the trading pair was not created before, or the price from exchange matches with auction
        if (usdcSent == totalDepositedUSDC && astoSent == totalDepositedASTO) {
            emit LiquidityAdded(astoSent, usdcSent, lpTokenAmount);
            return;
        }

        // 3. Swap the tokens left in the contract if not all tokens been aadded to the liquidity pool

        // Get reserved token amounts in LP pool
        uint256 resASTO;
        uint256 resUSDC;
        if (IUniswapV2Pair(liquidityPair).token0() == address(asto)) {
            (resASTO, resUSDC, ) = IUniswapV2Pair(liquidityPair).getReserves();
        } else {
            (resUSDC, resASTO, ) = IUniswapV2Pair(liquidityPair).getReserves();
        }

        // Calculate swap amount
        uint256 swapAmt;
        address[] memory path = new address[](2);
        bool isReserved;
        uint256 balance;
        if (usdcSent == totalDepositedUSDC) {
            balance = totalDepositedASTO - astoSent;
            swapAmt = optimalDeposit(balance, 0, resASTO, resUSDC);
            (path[0], path[1]) = (address(asto), address(usdc));
        } else {
            balance = totalDepositedUSDC - usdcSent;
            swapAmt = optimalDeposit(balance, 0, resUSDC, resASTO);
            (path[0], path[1]) = (address(usdc), address(asto));
            isReserved = true;
        }

        require(swapAmt > 0, "swapAmt must great then 0");

        // Swap the token
        uint256[] memory amounts = IUniswapV2Router02(router).swapExactTokensForTokens(
            swapAmt,
            0,
            path,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );

        // 4. Add liquidity to the exchange again. All tokens should be transferred in this step
        (uint256 amountA, , uint256 moreLPAmount) = IUniswapV2Router02(router).addLiquidity(
            isReserved ? address(usdc) : address(asto),
            isReserved ? address(asto) : address(usdc),
            balance - swapAmt,
            amounts[1],
            0,
            0,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );

        lpTokenAmount += moreLPAmount;
        uint256 totalASTOSent = isReserved ? astoSent : astoSent + swapAmt + amountA;
        uint256 totalUSDCSent = isReserved ? usdcSent + swapAmt + amountA : usdcSent;
        emit LiquidityAdded(totalASTOSent, totalUSDCSent, lpTokenAmount);
    }

    /**
     * @notice Claim LP tokens. The LP tokens are locked for 12 weeks after auction ends
     */
    function claimLPToken() external nonReentrant {
        uint256 claimable = claimableLPAmount(msg.sender);
        require(claimable > 0, "no claimable token");

        lpClaimed[msg.sender] += claimable;

        require(IUniswapV2Pair(liquidityPair).transfer(msg.sender, claimable), "insufficient LP token balance");
    }

    /**
     * @notice Calculate claimable LP amount based on deposited token amount
     * @param recipient Wallet address to calculate for
     * @return Claimable LP amount
     */
    function claimableLPAmount(address recipient) public view returns (uint256) {
        if (currentTime() < lpTokenReleaseTime()) {
            return 0;
        }
        // LP tokens are splitted into two equal parts. One part for $ASTO and another for $USDC
        uint256 claimableLPTokensForASTO = (lpTokenAmount * depositedASTO[recipient]) / (2 * totalDepositedASTO);
        uint256 claimableLPTokensForUSDC = (lpTokenAmount * depositedUSDC[recipient]) / (2 * totalDepositedUSDC);
        uint256 total = claimableLPTokensForASTO + claimableLPTokensForUSDC;
        return total - lpClaimed[recipient];
    }

    /**
     * @notice Claim `amount` $ASTO tokens as rewards
     * @param amount The $ASTO token amount to claim
     */
    function claimRewards(uint256 amount) external nonReentrant {
        uint256 amountVested;
        (, amountVested) = claimableRewards(msg.sender);

        require(amount <= amountVested, "amount not claimable");
        rewardClaimed[msg.sender] += amount;

        require(asto.balanceOf(address(this)) >= amount, "insufficient ASTO balance");
        asto.safeTransfer(msg.sender, amount);

        emit RewardsClaimed(msg.sender, amount);
    }

    /**
     * @notice Calculate claimable $ASTO token amount as rewards. The rewards are released weekly for 12 weeks after auction ends.
     * @param recipient Wallet address to calculate for
     * @return Vested weeks and vested(claimable) $ASTO token amount
     */
    function claimableRewards(address recipient) public view returns (uint16, uint256) {
        if (currentTime() < auctionEndTime()) {
            return (0, 0);
        }

        uint256 elapsedTime = currentTime() - auctionEndTime();
        uint16 elapsedWeeks = uint16(elapsedTime / SECONDS_PER_WEEK);

        if (elapsedWeeks >= REWARDS_RELEASE_DURATION_IN_WEEKS) {
            uint256 remaining = calculateRewards(recipient) - rewardClaimed[recipient];
            return (REWARDS_RELEASE_DURATION_IN_WEEKS, remaining);
        } else {
            uint256 amountVestedPerWeek = calculateRewards(recipient) / REWARDS_RELEASE_DURATION_IN_WEEKS;
            uint256 amountVested = amountVestedPerWeek * elapsedWeeks - rewardClaimed[recipient];
            return (elapsedWeeks, amountVested);
        }
    }

    /**
     * @notice Calculate the total $ASTO token amount as rewards
     * @param recipient Wallet address to calculate for
     * @return Total rewards amount
     */
    function calculateRewards(address recipient) public view returns (uint256) {
        return calculateASTORewards(recipient) + calculateUSDCRewards(recipient);
    }

    /**
     * @notice Calculate the $ASTO rewards amount for depositing $ASTO
     * @param recipient Wallet address to calculate for
     * @return Rewards amount for for depositing $ASTO
     */
    function calculateASTORewards(address recipient) public view returns (uint256) {
        if (totalDepositedASTO == 0) {
            return 0;
        }
        return (astoRewardAmount() * depositedASTO[recipient]) / totalDepositedASTO;
    }

    /**
     * @notice Calculate the $ASTO rewards amount for depositing $USDC
     * @param recipient Wallet address to calculate for
     * @return Rewards amount for for depositing $USDC
     */
    function calculateUSDCRewards(address recipient) public view returns (uint256) {
        if (totalDepositedUSDC == 0) {
            return 0;
        }
        return (usdcRewardAmount() * depositedUSDC[recipient]) / totalDepositedUSDC;
    }

    /**
     * @notice Withdraw any token left in the contract to multisig
     * @param token ERC20 token contract address to withdraw
     * @param amount Token amount to withdraw
     */
    function withdrawToken(address token, uint256 amount) external onlyOwner {
        require(token != address(0), "invalid token address");
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(amount <= balance, "amount should not exceed balance");
        IERC20(token).safeTransfer(msg.sender, amount);
        emit TokenWithdrawn(msg.sender, amount);
    }

    /**
     * @notice Check if depositing $ASTO is allowed
     * @return $ASTO deposit status
     */
    function astoDepositAllowed() public view returns (bool) {
        return currentTime() >= auctionStartTime && currentTime() < astoDepositEndTime();
    }

    /**
     * @notice Check if depositing $USDC is allowed
     * @return $USDC deposit status
     */
    function usdcDepositAllowed() public view returns (bool) {
        return currentTime() >= auctionStartTime && currentTime() < usdcDepositEndTime();
    }

    /**
     * @notice Check if withdrawing $USDC is allowed
     * @return $USDC withdraw status
     */
    function usdcWithdrawAllowed() public view returns (bool) {
        return currentTime() >= auctionStartTime && currentTime() < auctionEndTime();
    }

    /**
     * @notice Get $ASTO deposit end timestamp
     * @return Timestamp when $ASTO deposit ends
     */
    function astoDepositEndTime() public view returns (uint256) {
        return auctionStartTime + 3 days;
    }

    /**
     * @notice Get $USDC deposit end timestamp
     * @return Timestamp when $USDC deposit ends
     */
    function usdcDepositEndTime() public view returns (uint256) {
        return auctionStartTime + 5 days;
    }

    /**
     * @notice Get the timestamp for the last day of withdrawing $USDC
     * @return Timestamp for the last day of withdrawing $USDC
     */
    function usdcWithdrawLastDay() public view returns (uint256) {
        return auctionStartTime + 6 days;
    }

    /**
     * @notice Get auction end timestamp
     * @return Timestamp when the auction ends
     */
    function auctionEndTime() public view returns (uint256) {
        return auctionStartTime + 7 days;
    }

    /**
     * @notice Get LP token release timestamp
     * @return Timestamp when the locked LP tokens been released
     */
    function lpTokenReleaseTime() public view returns (uint256) {
        return auctionEndTime() + 12 weeks;
    }

    /**
     * @notice Get the rewards portion for all deposited $ASTO
     * @return $ASTO token amount to be distributed as rewards for depositing $ASTO
     */
    function astoRewardAmount() public view returns (uint256) {
        return (totalRewardAmount * 75) / 100;
    }

    /**
     * @notice Get the rewards portion for all deposited $USDC
     * @return $ASTO token amount to be distributed as rewards for depositing $USDC
     */
    function usdcRewardAmount() public view returns (uint256) {
        return (totalRewardAmount * 25) / 100;
    }

    /**
     * @notice Set auction start timestamp
     * @param newStartTime The auction start timestamp to set
     */
    function setStartTime(uint256 newStartTime) external onlyOwner {
        auctionStartTime = newStartTime;
    }

    /**
     * @notice Get the auction timelines
     * @return Timeline struct for the auction
     */
    function timeline() public view returns (Timeline memory) {
        return Timeline(auctionStartTime, astoDepositEndTime(), usdcDepositEndTime(), auctionEndTime());
    }

    /**
     * @notice Get the deposit stats
     * @param depositor The wallet address to get the stats for
     * @return Stats struct for the auction
     */
    function stats(address depositor) public view returns (Stats memory) {
        return Stats(totalDepositedASTO, totalDepositedUSDC, depositedASTO[depositor], depositedUSDC[depositor]);
    }

    /**
     * @notice Get the latest block timestamp
     * @return The latest block timestamp
     */
    function currentTime() public view virtual returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }
}