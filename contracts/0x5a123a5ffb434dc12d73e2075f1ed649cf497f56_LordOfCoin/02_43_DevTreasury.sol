// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "./uniswapv2/interfaces/IUniswapV2Factory.sol";
import "./uniswapv2/interfaces/IUniswapV2Router02.sol";

/// @dev Ownable is used because solidity complain trying to deploy a contract whose code is too large when everything is added into Lord of Coin contract.
/// The only owner function is `init` which is to setup for the first time after deployment.
/// After init finished, owner will be renounced automatically. owner() function will return 0x0 address.
contract DevTreasury is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @dev Developer wallet
    address payable public devWallet;

    /// @dev SDVD contract address
    address public sdvd;

    /// @dev Uniswap router
    IUniswapV2Router02 uniswapRouter;

    /// @dev Uniswap factory
    IUniswapV2Factory uniswapFactory;

    /// @dev WETH address
    address weth;

    /// @dev Uniswap LP address
    address public pairAddress;

    /// @notice Release balance every 1 hour to dev wallet
    uint256 public releaseThreshold = 1 hours;

    /// @dev Last release timestamp
    uint256 public releaseTime;

    constructor (address _uniswapRouter, address _sdvd) public {
        // Set dev wallet
        devWallet = msg.sender;
        // Set uniswap router
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        // Set uniswap factory
        uniswapFactory = IUniswapV2Factory(uniswapRouter.factory());
        // Get weth address
        weth = uniswapRouter.WETH();
        // Set SDVD address
        sdvd = _sdvd;
        // Approve uniswap router to spend sdvd
        IERC20(sdvd).approve(_uniswapRouter, uint256(- 1));
        // Set initial release time
        releaseTime = block.timestamp;
    }

    /* ========== Owner Only ========== */

    function init() external onlyOwner {
        // Get pair address after init because we wait until pair created in lord of coin
        pairAddress = uniswapFactory.getPair(sdvd, weth);
        // Renounce ownership immediately after init
        renounceOwnership();
    }

    /* ========== Mutative ========== */

    /// @notice Release SDVD to market regardless the price so dev doesn't own any SDVD from 0.5% fee.
    /// This is to protect SDVD holders.
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
                address[] memory path = new address[](2);
                path[0] = sdvd;
                path[1] = weth;

                // Swap SDVD to ETH on uniswap
                // uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
                uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    sdvdBalance,
                    0,
                    path,
                    devWallet,
                    block.timestamp.add(30 minutes)
                );
            }
        }
    }

}