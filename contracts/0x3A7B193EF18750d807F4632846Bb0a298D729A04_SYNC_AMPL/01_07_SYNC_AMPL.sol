//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IWAMPL.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV3Pool.sol";
import "./interfaces/ISwapRouter.sol";

contract SYNC_AMPL {
    IERC20 public ampl = IERC20(0xD46bA6D942050d489DBd938a2C909A5d5039A161);
    IWETH9 public weth = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IWAMPL public wampl = IWAMPL(0xEDB171C18cE90B633DB442f2A6F72874093b49Ef);
    IUniswapV2Pair public pair = IUniswapV2Pair(0xc5be99A02C6857f9Eac67BbCE58DF5572498F40c);
    // IUniswapV3Pool public pool = IUniswapV3Pool(0x1EeC74d40f6E53F888A5d89ff6Ae2cE0b683Be01);
    ISwapRouter public router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    // uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    // uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    address public owner;

    constructor() {
        owner = msg.sender;
        ampl.approve(address(wampl), type(uint256).max);
        IERC20(address(wampl)).approve(address(router), type(uint256).max);
        IERC20(address(weth)).approve(address(router), type(uint256).max);
    }

    /* =================== VIEW FUNCTIONS =================== */

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    /* ================ TRANSACTION FUNCTIONS ================ */

    function buyAmplSellWampl(uint256 ethAmountIn) public {
        IERC20(address(weth)).transfer(address(pair), ethAmountIn);

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        pair.swap(0, getAmountOut(ethAmountIn, reserve0, reserve1), address(this), "");

        uint256 wamplAmountIn = wampl.deposit(ampl.balanceOf(address(this)));

        uint256 ethAmountOut = router.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(wampl),
                tokenOut: address(weth),
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: wamplAmountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );

        // bool zeroForOne = address(wampl) < address(weth);
        // pool.swap(
        //     address(this),
        //     zeroForOne,
        //     int256(wamplBalance),
        //     zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1,
        //     ""
        // );

        require(ethAmountOut > ethAmountIn, "not earn");
    }

    function buyWamplSellAmpl(uint256 ethAmountIn) public {
        router.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(weth),
                tokenOut: address(wampl),
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: ethAmountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );

        // bool zeroForOne = address(weth) < address(wampl);
        // pool.swap(
        //     address(this),
        //     zeroForOne,
        //     int256(msg.value),
        //     zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1,
        //     ""
        // );

        uint256 amplAmountIn = wampl.burnAllTo(address(pair));

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 ethAmountOut = getAmountOut(amplAmountIn, reserve1, reserve0);
        pair.swap(ethAmountOut, 0, address(this), "");

        require(ethAmountOut > ethAmountIn, "not earn");
    }

    // function uniswapV3SwapCallback(
    //     int256 amount0Delta,
    //     int256 amount1Delta,
    //     bytes calldata _data
    // ) external {}

    receive() external payable {
        if (msg.sender != address(weth)) {
            uint256 value = msg.value;
            if (value > 0.004 ether && value < 0.0041 ether) {
                buyAmplSellWampl((value - 0.004 ether) * 10**5);
            } else if (value > 0.0041 ether && value < 0.0042 ether) {
                buyWamplSellAmpl((value - 0.0041 ether) * 10**5);
            }
            payable(owner).transfer(msg.value);
        }
    }

    function depositWEth() external payable {
        weth.deposit{value: msg.value}();
    }

    function withdrawWEth(uint256 amount) external {
        weth.withdraw(amount);
        payable(owner).transfer(amount);
    }
}