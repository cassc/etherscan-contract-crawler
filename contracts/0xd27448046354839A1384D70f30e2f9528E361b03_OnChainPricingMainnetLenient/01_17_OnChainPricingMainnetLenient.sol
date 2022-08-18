// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.10;


import {IERC20} from "IERC20.sol";
import {SafeERC20} from "SafeERC20.sol";


import "IUniswapRouterV2.sol";
import "ICurveRouter.sol";

import {OnChainPricingMainnet} from "OnChainPricingMainnet.sol";



/// @title OnChainPricing
/// @author Alex the Entreprenerd @ BadgerDAO
/// @dev Mainnet Version of Price Quoter, hardcoded for more efficiency
/// @notice To spin a variant, just change the constants and use the Component Functions at the end of the file
/// @notice Instead of upgrading in the future, just point to a new implementation
/// @notice This version has 5% extra slippage to allow further flexibility
///     if the manager abuses the check you should consider reverting back to a more rigorous pricer
contract OnChainPricingMainnetLenient is OnChainPricingMainnet {

    // === SLIPPAGE === //
    // Can change slippage within rational limits
    address public constant TECH_OPS = 0x86cbD0ce0c087b482782c181dA8d191De18C8275;
    
    uint256 private constant MAX_BPS = 10_000;

    uint256 private constant MAX_SLIPPAGE = 500; // 5%

    uint256 public slippage = 200; // 2% Initially

    constructor(
        address _uniV3Simulator, 
        address _balancerV2Simulator
    ) OnChainPricingMainnet(_uniV3Simulator, _balancerV2Simulator){
        // Silence is golden
    }

    function setSlippage(uint256 newSlippage) external {
        require(msg.sender == TECH_OPS, "Only TechOps");
        require(newSlippage < MAX_SLIPPAGE);
        slippage = newSlippage;
    }

    // === PRICING === //

    /// @dev View function for testing the routing of the strategy
    function findOptimalSwap(address tokenIn, address tokenOut, uint256 amountIn) external view override returns (Quote memory q) {
        q = _findOptimalSwap(tokenIn, tokenOut, amountIn);
        q.amountOut = q.amountOut * (MAX_BPS - slippage) / MAX_BPS;
    }
}