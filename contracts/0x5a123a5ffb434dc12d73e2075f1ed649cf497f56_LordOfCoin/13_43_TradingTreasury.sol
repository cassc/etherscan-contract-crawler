// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "./uniswapv2/interfaces/IUniswapV2Factory.sol";
import "./uniswapv2/interfaces/IUniswapV2Router02.sol";
import "./uniswapv2/interfaces/IWETH.sol";
import "./interfaces/ILordOfCoin.sol";
import "./interfaces/IBPool.sol";

/// @dev Ownable is used because solidity complain trying to deploy a contract whose code is too large when everything is added into Lord of Coin contract.
/// The only owner function is `init` which is to setup for the first time after deployment.
/// After init finished, owner will be renounced automatically. owner() function will return 0x0 address.
contract TradingTreasury is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Received(address indexed from, uint256 amount);

    /// @dev Lord of coin address
    address public controller;

    /// @dev Uniswap router
    IUniswapV2Router02 uniswapRouter;

    /// @dev Uniswap factory
    IUniswapV2Factory uniswapFactory;

    /// @dev Balancer pool WETH-MUSD
    address balancerPool;

    /// @dev WETH address
    address weth;

    /// @dev mUSD contract address
    address musd;

    /// @dev SDVD contract address
    address public sdvd;

    /// @dev Uniswap LP address
    address public pairAddress;

    /// @notice Release balance as sharing pool profit every 1 hour
    uint256 public releaseThreshold = 1 hours;

    /// @dev Last release timestamp
    uint256 public releaseTime;

    constructor (address _uniswapRouter, address _balancerPool, address _sdvd, address _musd) public {
        // Set uniswap router
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        // Set uniswap factory
        uniswapFactory = IUniswapV2Factory(uniswapRouter.factory());
        // Get weth address
        weth = uniswapRouter.WETH();
        // Set balancer pool
        balancerPool = _balancerPool;
        // Set SDVD address
        sdvd = _sdvd;
        // Set mUSD address
        musd = _musd;
        // Approve uniswap to spend SDVD
        IERC20(sdvd).approve(_uniswapRouter, uint256(- 1));
        // Approve balancer to spend WETH
        IERC20(weth).approve(balancerPool, uint256(- 1));
        // Set initial release time
        releaseTime = block.timestamp;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /* ========== Owner Only ========== */

    function init(address _controller) external onlyOwner {
        // Set Lord of coin address
        controller = _controller;
        // Get pair address
        pairAddress = ILordOfCoin(controller).sdvdEthPairAddress();
        // Renounce ownership immediately after init
        renounceOwnership();
    }

    /* ========== Mutative ========== */

    /// @notice Release SDVD to be added as profit
    function release() external {
        _release();
    }

    /* ========== Internal ========== */

    function _release() internal {
        if (releaseTime.add(releaseThreshold) <= block.timestamp) {
            // Update release time
            releaseTime = block.timestamp;

            // Get SDVD balance
            uint256 sdvdBalance = IERC20(sdvd).balanceOf(address(this));

            // If there is SDVD in this contract
            // and there is enough liquidity to swap
            if (sdvdBalance > 0 && IERC20(sdvd).balanceOf(pairAddress) >= sdvdBalance) {
                // Use uniswap since this contract is registered as no fee address for swapping SDVD to ETH
                // Swap path
                address[] memory path = new address[](2);
                path[0] = sdvd;
                path[1] = weth;

                // Swap SDVD to ETH on uniswap
                // uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
                uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    sdvdBalance,
                    0,
                    path,
                    address(this),
                    block.timestamp.add(30 minutes)
                );

                // Get all ETH in this contract
                uint256 ethAmount = address(this).balance;

                // Convert ETH to WETH
                IWETH(weth).deposit{ value: ethAmount }();
                // Swap WETH to mUSD
                (uint256 musdAmount,) = IBPool(balancerPool).swapExactAmountIn(weth, ethAmount, musd, 0, uint256(-1));
                // Send it to Lord of Coin
                IERC20(musd).safeTransfer(controller, musdAmount);
                // Deposit profit
                ILordOfCoin(controller).depositTradingProfit(musdAmount);
            }
        }
    }

}