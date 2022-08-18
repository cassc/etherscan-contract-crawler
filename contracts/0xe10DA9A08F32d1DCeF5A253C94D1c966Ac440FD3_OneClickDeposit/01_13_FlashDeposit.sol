// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import {PRBMathUD60x18} from "../libraries/math/PRBMathUD60x18.sol";
import {IAuction} from "../interfaces/IAuction.sol";
import {IVault} from "../interfaces/IVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract OneClickDeposit is Ownable, ReentrancyGuard {
    using PRBMathUD60x18 for uint256;

    address public addressVault = 0x001eb0D277d5B24A306582387Cfc16Fa37a1375C;

    ISwapRouter constant swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant OSQTH = 0xf1B99e3E573A1a9C5E6B2Ce818b617F0E664E86B;

    constructor() Ownable() {
        TransferHelper.safeApprove(WETH, address(swapRouter), type(uint256).max);
        TransferHelper.safeApprove(USDC, address(swapRouter), type(uint256).max);
        TransferHelper.safeApprove(OSQTH, address(swapRouter), type(uint256).max);
        IERC20(USDC).approve(addressVault, type(uint256).max);
        IERC20(OSQTH).approve(addressVault, type(uint256).max);
        IERC20(WETH).approve(addressVault, type(uint256).max);
    }

    function setContracts(address _addressVault) external onlyOwner {
        addressVault = _addressVault;
        IERC20(USDC).approve(addressVault, type(uint256).max);
        IERC20(OSQTH).approve(addressVault, type(uint256).max);
        IERC20(WETH).approve(addressVault, type(uint256).max);
    }

    /**
    @notice deposit tokens in proportion to the vault's holding
    @param amountEth ETH amount to deposit
    @param to receiver address
    @param returnMode if 1 convert remaining tokens to wETH and send it back to user, if 2 send remaining wETH, USDC, and oSQTH without convertation to wETH 
    @return shares minted shares
    */
    function deposit(
        uint256 amountEth,
        uint256 slippage,
        address to,
        int24 returnMode
    ) external nonReentrant returns (uint256) {
        IERC20(WETH).transferFrom(msg.sender, address(this), amountEth);

        (uint256 ethToDeposit, uint256 usdcToDeposit, uint256 osqthToDeposit) = swap(amountEth, slippage);

        uint256 shares = IVault(addressVault).deposit(ethToDeposit, usdcToDeposit, osqthToDeposit, to, 0, 0, 0);

        if (returnMode == 0) swapAllToEth(to);
        if (returnMode == 1) withdrawRT(to);

        return shares;
    }

    function swap(uint256 amountEth, uint256 slippage)
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        (, , uint256 usdcToDeposit, uint256 osqthToDeposit) = IVault(addressVault).calcSharesAndAmounts(
            amountEth.mul(slippage),
            0,
            0,
            IERC20(addressVault).totalSupply(),
            true
        );

        uint256 ethIN;
        {
            // swap wETH --> USDC
            ISwapRouter.ExactOutputSingleParams memory params1 = ISwapRouter.ExactOutputSingleParams({
                tokenIn: WETH,
                tokenOut: USDC,
                fee: 500,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: usdcToDeposit,
                amountInMaximum: amountEth,
                sqrtPriceLimitX96: 0
            });
            uint256 ethIN1 = swapRouter.exactOutputSingle(params1);

            // swap wETH --> oSQTH
            ISwapRouter.ExactOutputSingleParams memory params2 = ISwapRouter.ExactOutputSingleParams({
                tokenIn: WETH,
                tokenOut: OSQTH,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: osqthToDeposit,
                amountInMaximum: amountEth,
                sqrtPriceLimitX96: 0
            });
            uint256 ethIN2 = swapRouter.exactOutputSingle(params2);

            ethIN = ethIN1.add(ethIN2);
        }
        return (amountEth.mul(slippage).sub(ethIN), usdcToDeposit, osqthToDeposit);
    }

    // @dev swap all remaining tokens to wETH and send it back to user
    function swapAllToEth(address to) internal {
        //swap remaining USDC --> wETH
        ISwapRouter.ExactInputSingleParams memory params3 = ISwapRouter.ExactInputSingleParams({
            tokenIn: USDC,
            tokenOut: WETH,
            fee: 500,
            recipient: to,
            deadline: block.timestamp,
            amountIn: _getBalance(USDC),
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        //Execute swap
        swapRouter.exactInputSingle(params3);

        //swap remaining oSQTH --> wETH
        ISwapRouter.ExactInputSingleParams memory params2 = ISwapRouter.ExactInputSingleParams({
            tokenIn: OSQTH,
            tokenOut: WETH,
            fee: 3000,
            recipient: to,
            deadline: block.timestamp,
            amountIn: _getBalance(OSQTH),
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        //Execute swap
        swapRouter.exactInputSingle(params2);

        //Send wETH back to user
        IERC20(WETH).transfer(to, _getBalance(WETH));
    }

    // @dev sends remaining tokens back to user
    function withdrawRT(address to) internal {
        IERC20(WETH).transfer(to, _getBalance(WETH));
        IERC20(USDC).transfer(to, _getBalance(USDC));
        IERC20(OSQTH).transfer(to, _getBalance(OSQTH));
    }

    function _getBalance(address coin) internal view returns (uint256) {
        return IERC20(coin).balanceOf(address(this));
    }
}