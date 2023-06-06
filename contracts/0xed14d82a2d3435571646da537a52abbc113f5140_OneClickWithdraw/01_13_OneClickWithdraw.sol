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

contract OneClickWithdraw is Ownable, ReentrancyGuard {
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
    }

    function setContracts(address _addressVault) external onlyOwner {
        addressVault = _addressVault;
    }

    /**
    @notice withdraw tokens and swap it into weth
    @param to receiver address
    @param shares shares burned by sender
    @param amountEthMin revert if resulting amount of wETH is smaller than this
    @param amountUsdcMin revert if resulting amount of USDC is smaller than this
    @param amountOsqthMin revert if resulting amount of oSQTH is smaller than th
    */
    function withdraw(
        address to,
        uint256 shares,
        uint256 amountEthMin,
        uint256 amountUsdcMin,
        uint256 amountOsqthMin
    ) external nonReentrant {
        IVault(addressVault).transferFrom(msg.sender, address(this), shares);

        IVault(addressVault).withdraw(shares, amountEthMin, amountUsdcMin, amountOsqthMin);

        swapAllToEth(to);
    }

    // @dev swap all remaining tokens to wETH and send it back to user
    function swapAllToEth(address to) internal {
        //swap all USDC to wETH
        swapRouter.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: USDC,
                tokenOut: WETH,
                fee: 500,
                recipient: to,
                deadline: block.timestamp,
                amountIn: IERC20(USDC).balanceOf(address(this)),
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );

        //swap all oSQTH to wETH
        swapRouter.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: OSQTH,
                tokenOut: WETH,
                fee: 3000,
                recipient: to,
                deadline: block.timestamp,
                amountIn: IERC20(OSQTH).balanceOf(address(this)),
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );

        //Send wETH back to user
        IERC20(WETH).transfer(to, IERC20(WETH).balanceOf(address(this)));
    }
}