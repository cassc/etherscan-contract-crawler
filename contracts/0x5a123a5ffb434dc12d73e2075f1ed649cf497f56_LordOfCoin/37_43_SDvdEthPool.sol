// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import "./uniswapv2/interfaces/IUniswapV2Router02.sol";
import "./uniswapv2/interfaces/IUniswapV2Pair.sol";
import "./uniswapv2/interfaces/IUniswapV2Factory.sol";
import "./interfaces/IDvd.sol";
import "./Pool.sol";

contract SDvdEthPool is Pool {

    event StakedETH(address indexed account, uint256 amount);
    event ClaimedAndStaked(address indexed account, uint256 amount);

    /// @dev Uniswap router
    IUniswapV2Router02 uniswapRouter;

    /// @dev Uniswap factory
    IUniswapV2Factory uniswapFactory;

    /// @dev WETH address
    address weth;

    /// @notice LGE state
    bool public isLGEActive = true;

    /// @notice Max initial deposit cap
    uint256 public LGE_INITIAL_DEPOSIT_CAP = 5 ether;

    /// @notice Amount in SDVD. After hard cap reached, stake ETH will function as normal staking.
    uint256 public LGE_HARD_CAP = 200 ether;

    /// @dev Initial price multiplier
    uint256 public LGE_INITIAL_PRICE_MULTIPLIER = 2;

    constructor(address _poolTreasury, address _uniswapRouter, uint256 _farmOpenTime) public Pool(_poolTreasury, _farmOpenTime) {
        rewardAllocation = 240000 * 1e18;
        rewardAllocation = rewardAllocation.sub(LGE_HARD_CAP.div(2));
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        uniswapFactory = IUniswapV2Factory(uniswapRouter.factory());
        weth = uniswapRouter.WETH();
    }

    /// @dev Added to receive ETH when swapping on Uniswap
    receive() external payable {
    }

    /// @notice Stake token using ETH conveniently.
    function stakeETH() external payable nonReentrant {
        _stakeETH(msg.value);
    }

    /// @notice Stake token using SDVD and ETH conveniently.
    /// @dev User must approve SDVD first
    function stakeSDVD(uint256 amountToken) external payable nonReentrant farmOpen {
        require(isLGEActive == false, 'LGE still active');

        uint256 pairSDVDBalance = IERC20(sdvd).balanceOf(stakedToken);
        uint256 pairETHBalance = IERC20(weth).balanceOf(stakedToken);
        uint256 amountETH = amountToken.mul(pairETHBalance).div(pairSDVDBalance);

        // Make sure received eth is enough
        require(msg.value >= amountETH, 'Not enough ETH');
        // Check if there is excess eth
        uint256 excessETH = msg.value.sub(amountETH);
        // Send back excess eth
        if (excessETH > 0) {
            msg.sender.transfer(excessETH);
        }

        // Transfer sdvd from sender to this contract
        IERC20(sdvd).safeTransferFrom(msg.sender, address(this), amountToken);

        // Approve uniswap router to spend SDVD
        IERC20(sdvd).approve(address(uniswapRouter), amountToken);
        // Add liquidity
        (,, uint256 liquidity) = uniswapRouter.addLiquidityETH{value : amountETH}(address(sdvd), amountToken, 0, 0, address(this), block.timestamp.add(30 minutes));

        // Approve self
        IERC20(stakedToken).approve(address(this), liquidity);
        // Stake LP token for sender
        _stake(address(this), msg.sender, liquidity);
    }

    /// @notice Claim reward and re-stake conveniently.
    function claimRewardAndStake() external nonReentrant farmOpen {
        require(isLGEActive == false, 'LGE still active');

        // Claim SDVD reward to this address
        (uint256 totalNetReward,,) = _claimReward(msg.sender, address(this));

        // Split total reward to be swapped
        uint256 swapAmountSDVD = totalNetReward.div(2);

        // Swap path
        address[] memory path = new address[](2);
        path[0] = address(sdvd);
        path[1] = weth;

        // Approve uniswap router to spend sdvd
        IERC20(sdvd).approve(address(uniswapRouter), swapAmountSDVD);
        // Swap SDVD to ETH
        // Param: uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
        uint256[] memory amounts = uniswapRouter.swapExactTokensForETH(swapAmountSDVD, 0, path, address(this), block.timestamp.add(30 minutes));
        // Get received ETH amount from swap
        uint256 amountETHReceived = amounts[1];

        // Get pair address and balance
        uint256 pairSDVDBalance = IERC20(sdvd).balanceOf(stakedToken);
        uint256 pairETHBalance = IERC20(weth).balanceOf(stakedToken);

        // Get available SDVD
        uint256 amountSDVD = totalNetReward.sub(swapAmountSDVD);
        // Calculate how much ETH needed to provide liquidity
        uint256 amountETH = amountSDVD.mul(pairETHBalance).div(pairSDVDBalance);

        // If required ETH amount to add liquidity is bigger than what we have
        // Then we need to reduce SDVD amount
        if (amountETH > amountETHReceived) {
            // Set ETH amount
            amountETH = amountETHReceived;
            // Get amount SDVD needed to add liquidity
            uint256 amountSDVDRequired = amountETH.mul(pairSDVDBalance).div(pairETHBalance);
            // Send dust
            if (amountSDVD > amountSDVDRequired) {
                IERC20(sdvd).safeTransfer(msg.sender, amountSDVD.sub(amountSDVDRequired));
            }
            // Set SDVD amount
            amountSDVD = amountSDVDRequired;
        }
        // Else if we have too much ETH
        else if (amountETHReceived > amountETH) {
            // Send excess
            msg.sender.transfer(amountETHReceived.sub(amountETH));
        }

        // Approve uniswap router to spend SDVD
        IERC20(sdvd).approve(address(uniswapRouter), amountSDVD);
        // Add liquidity
        (,, uint256 liquidity) = uniswapRouter.addLiquidityETH{value : amountETH}(address(sdvd), amountSDVD, 0, 0, address(this), block.timestamp.add(30 minutes));

        // Approve self
        IERC20(stakedToken).approve(address(this), liquidity);
        // Stake LP token for sender
        _stake(address(this), msg.sender, liquidity);

        emit ClaimedAndStaked(msg.sender, liquidity);
    }

    /* ========== Internal ========== */

    /// @notice Stake ETH
    /// @param value Value in ETH
    function _stakeETH(uint256 value) internal {
        // If in LGE
        if (isLGEActive) {
            // SDVD-ETH pair address
            uint256 pairSDVDBalance = IERC20(sdvd).balanceOf(stakedToken);

            if (pairSDVDBalance == 0) {
                require(msg.value <= LGE_INITIAL_DEPOSIT_CAP, 'Initial deposit cap reached');
            }

            uint256 pairETHBalance = IERC20(weth).balanceOf(stakedToken);
            uint256 amountETH = msg.value;

            // If SDVD balance = 0 then set initial price
            uint256 amountSDVD = pairSDVDBalance == 0 ? amountETH.mul(LGE_INITIAL_PRICE_MULTIPLIER) : amountETH.mul(pairSDVDBalance).div(pairETHBalance);

            uint256 excessETH = 0;
            // If amount token to be minted pass the hard cap
            if (pairSDVDBalance.add(amountSDVD) > LGE_HARD_CAP) {
                // Get excess token
                uint256 excessToken = pairSDVDBalance.add(amountSDVD).sub(LGE_HARD_CAP);
                // Reduce it
                amountSDVD = amountSDVD.sub(excessToken);
                // Get excess ether
                excessETH = excessToken.mul(pairETHBalance).div(pairSDVDBalance);
                // Reduce amount ETH to be put on uniswap liquidity
                amountETH = amountETH.sub(excessETH);
            }

            // Mint LGE SDVD
            ISDvd(sdvd).mint(address(this), amountSDVD);

            // Add liquidity in uniswap and send the LP token to this contract
            IERC20(sdvd).approve(address(uniswapRouter), amountSDVD);
            (,, uint256 liquidity) = uniswapRouter.addLiquidityETH{value : amountETH}(address(sdvd), amountSDVD, 0, 0, address(this), block.timestamp.add(30 minutes));

            // Recheck the SDVD in pair address
            pairSDVDBalance = IERC20(sdvd).balanceOf(stakedToken);
            // Set LGE active state
            isLGEActive = pairSDVDBalance < LGE_HARD_CAP;

            // Approve self
            IERC20(stakedToken).approve(address(this), liquidity);
            // Stake LP token for sender
            _stake(address(this), msg.sender, liquidity);

            // If there is excess ETH
            if (excessETH > 0) {
                _stakeETH(excessETH);
            }
        } else {
            // Split ETH sent
            uint256 amountETH = value.div(2);

            // Swap path
            address[] memory path = new address[](2);
            path[0] = weth;
            path[1] = address(sdvd);

            // Swap ETH to SDVD using uniswap
            // Param: uint amountOutMin, address[] calldata path, address to, uint deadline
            uint256[] memory amounts = uniswapRouter.swapExactETHForTokens{value : amountETH}(
                0,
                path,
                address(this),
                block.timestamp.add(30 minutes)
            );
            // Get SDVD amount
            uint256 amountSDVDReceived = amounts[1];

            // Get pair address balance
            uint256 pairSDVDBalance = IERC20(sdvd).balanceOf(stakedToken);
            uint256 pairETHBalance = IERC20(weth).balanceOf(stakedToken);

            // Get available ETH
            amountETH = value.sub(amountETH);
            // Calculate amount of SDVD needed to add liquidity
            uint256 amountSDVD = amountETH.mul(pairSDVDBalance).div(pairETHBalance);

            // If required SDVD amount to add liquidity is bigger than what we have
            // Then we need to reduce ETH amount
            if (amountSDVD > amountSDVDReceived) {
                // Set SDVD amount
                amountSDVD = amountSDVDReceived;
                // Get amount ETH needed to add liquidity
                uint256 amountETHRequired = amountSDVD.mul(pairETHBalance).div(pairSDVDBalance);
                // Send dust back to sender
                if (amountETH > amountETHRequired) {
                    msg.sender.transfer(amountETH.sub(amountETHRequired));
                }
                // Set ETH amount
                amountETH = amountETHRequired;
            }
            // Else if we have too much SDVD
            else if (amountSDVDReceived > amountSDVD) {
                // Send dust
                IERC20(sdvd).transfer(msg.sender, amountSDVDReceived.sub(amountSDVD));
            }

            // Approve uniswap router to spend SDVD
            IERC20(sdvd).approve(address(uniswapRouter), amountSDVD);
            // Add liquidity
            (,, uint256 liquidity) = uniswapRouter.addLiquidityETH{value : amountETH}(address(sdvd), amountSDVD, 0, 0, address(this), block.timestamp.add(30 minutes));
            // Sync total token supply
            ISDvd(sdvd).syncPairTokenTotalSupply();

            // Approve self
            IERC20(stakedToken).approve(address(this), liquidity);
            // Stake LP token for sender
            _stake(address(this), msg.sender, liquidity);
        }

        emit StakedETH(msg.sender, msg.value);
    }

}