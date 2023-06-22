// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import "./uniswapv2/interfaces/IUniswapV2Router02.sol";
import "./uniswapv2/interfaces/IUniswapV2Factory.sol";
import "./interfaces/IDvd.sol";
import "./interfaces/IPool.sol";
import "./Pool.sol";

contract DvdPool is Pool {

    event StakedETH(address indexed account, uint256 amount);
    event WithdrawnETH(address indexed account, uint256 amount);
    event ClaimedAndStaked(address indexed account, uint256 amount);

    /// @dev mUSD instance
    address public musd;

    /// @dev Uniswap router
    IUniswapV2Router02 uniswapRouter;

    /// @dev Uniswap factory
    IUniswapV2Factory uniswapFactory;

    /// @dev WETH address
    address weth;

    /// @dev SDVD ETH pool address
    address public sdvdEthPool;

    constructor(address _poolTreasury, address _musd, address _uniswapRouter, address _sdvdEthPool, uint256 _farmOpenTime) public Pool(_poolTreasury, _farmOpenTime) {
        rewardAllocation = 360000 * 1e18;
        musd = _musd;
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        uniswapFactory = IUniswapV2Factory(uniswapRouter.factory());
        weth = uniswapRouter.WETH();
        sdvdEthPool = _sdvdEthPool;
    }

    /// @dev Added to receive ETH when swapping on Uniswap
    receive() external payable {
    }

    /// @notice Stake token using ETH conveniently.
    function stakeETH() external payable nonReentrant {
        // Buy DVD using ETH
        (uint256 dvdAmount,,,) = ILordOfCoin(controller).buyFromETH{value : msg.value}();

        // Approve self
        IERC20(stakedToken).approve(address(this), dvdAmount);
        // Stake user DVD
        _stake(address(this), msg.sender, dvdAmount);

        emit StakedETH(msg.sender, msg.value);
    }

    /// @notice Withdraw token to ETH conveniently.
    /// @param amount Number of staked DVD token.
    /// @dev Need to approve DVD token first.
    function withdrawETH(uint256 amount) external nonReentrant farmOpen {
        // Call withdraw to this address
        _withdraw(msg.sender, address(this), amount);
        // Approve LoC to spend DVD
        IERC20(stakedToken).approve(controller, amount);
        // Sell received DVD to ETH
        (uint256 receivedETH,,,,) = ILordOfCoin(controller).sellToETH(amount);
        // Send received ETH to sender
        msg.sender.transfer(receivedETH);

        emit WithdrawnETH(msg.sender, receivedETH);
    }

    /// @notice Claim reward and re-stake conveniently.
    function claimRewardAndStake() external nonReentrant farmOpen {
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
        address pairAddress = uniswapFactory.getPair(address(sdvd), weth);
        uint256 pairSDVDBalance = IERC20(sdvd).balanceOf(pairAddress);
        uint256 pairETHBalance = IERC20(weth).balanceOf(pairAddress);

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
            // Send dust
            msg.sender.transfer(amountETHReceived.sub(amountETH));
        }

        // Approve uniswap router to spend SDVD
        IERC20(sdvd).approve(address(uniswapRouter), amountSDVD);
        // Add liquidity
        (,, uint256 liquidity) = uniswapRouter.addLiquidityETH{value : amountETH}(address(sdvd), amountSDVD, 0, 0, address(this), block.timestamp.add(30 minutes));

        // Approve SDVD ETH pool to spend LP token
        IERC20(pairAddress).approve(sdvdEthPool, liquidity);
        // Stake LP token for sender
        IPool(sdvdEthPool).stakeTo(msg.sender, liquidity);

        emit ClaimedAndStaked(msg.sender, liquidity);
    }

    /* ========== Internal ========== */

    /// @notice Override stake function to check shareholder points
    /// @param amount Number of DVD token to be staked.
    function _stake(address sender, address recipient, uint256 amount) internal virtual override {
        require(IDvd(stakedToken).shareholderPointOf(sender) >= amount, 'Insufficient shareholder points');
        super._stake(sender, recipient, amount);
    }

}