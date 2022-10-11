// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "./libs/OneInchSwapValidation.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/OneInchAggregator.sol";
import "./AbstractDynaset.sol";

contract Dynaset is AbstractDynaset {
    using SafeERC20 for IERC20;
    using OneInchSwapValidation for address;

    /* ==========  Constants  ========== */
    address private constant ONEINCH_V4_AGREGATION_ROUTER = 0x1111111254fb6c44bAC0beD2854e76F90643097d;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /* ==========  State variables  ========== */
    address public uniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 public deadline;

    /* ==========  Events  ========== */
    event Swap(
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOutMin
    );

    /* ==========  Constructor  ========== */
    constructor(
        address factoryContract,
        address dam,
        address controller_,
        string memory name,
        string memory symbol
    ) AbstractDynaset(factoryContract, dam, controller_, name, symbol) {
    }

    /* ==========  Token Swaps  ========== */
    function swapUniswap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin
    ) external payable nonReentrant {
        onlyDigitalAssetManager();
        _checkBounds(tokenIn, tokenOut); 
        //next we need to allow the uniswapv2 router to spend the token we just sent to this contract
        //by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract
        IERC20(tokenIn).safeIncreaseAllowance(uniswapV2Router, amountIn);
        //path is an array of addresses.
        //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
        //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path;
        if (tokenIn == WETH || tokenOut == WETH) {
            path = new address[](2);
            path[0] = tokenIn;
            path[1] = tokenOut;
        } else {
            path = new address[](3);
            path[0] = tokenIn;
            path[1] = WETH;
            path[2] = tokenOut;
        }
        //then we will call swapExactTokensForTokens
        //for the deadline we will pass in block.timestamp + deadline
        //the deadline is the latest time the trade is valid for
        IUniswapV2Router(uniswapV2Router).swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            block.timestamp + deadline
        );
        _afterSwap(tokenIn, tokenOut, amountIn, amountOutMin);
    }



    // swap using 1inch API
    function swapOneInch(
        address tokenIn,
        address tokenOut,
        uint256 amount,
        uint256 minReturn,
        bytes32[] calldata pools
    ) external payable nonReentrant {
        onlyDigitalAssetManager();
        _checkBounds(tokenIn, tokenOut); 
        tokenIn.validateUnoswap(tokenOut, pools);
        IERC20(tokenIn).safeIncreaseAllowance(ONEINCH_V4_AGREGATION_ROUTER, amount);
        OneInchAggregator(ONEINCH_V4_AGREGATION_ROUTER).unoswap(
            tokenIn,
            amount,
            minReturn,
            pools
        );
        _afterSwap(tokenIn, tokenOut, amount, minReturn);
    }

    // swap on uniswapV3 using 1inch API
    function swapOneInchUniV3(
        address tokenIn,
        address tokenOut,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) external payable nonReentrant {
        onlyDigitalAssetManager();
        _checkBounds(tokenIn, tokenOut); 
        tokenIn.validateUniswapV3Swap(tokenOut, pools);
        IERC20(tokenIn).safeIncreaseAllowance(ONEINCH_V4_AGREGATION_ROUTER, amount);
        OneInchAggregator(ONEINCH_V4_AGREGATION_ROUTER).uniswapV3Swap(
            amount,
            minReturn,
            pools
        );
        _afterSwap(tokenIn, tokenOut, amount, minReturn);
    }
    
    /* =========== Internal functions ============ */
    
    function _checkBounds(address tokenIn, address tokenOut) internal view {
        require(records[tokenIn].bound, "ERR_NOT_BOUND");
        require(records[tokenOut].bound, "ERR_NOT_BOUND");    
    }
    
    function _afterSwap(address tokenIn, address tokenOut, uint256 amount, uint256 minReturn) internal {
        updateAfterSwap(tokenIn, tokenOut);
        emit Swap(tokenIn, tokenOut, amount, minReturn);    
    }

    /* =========== Privileged configuration functions ============ */

    function setDeadline(uint256 newDeadline) external {
        onlyController();
        deadline = newDeadline;
    }

    function upgradeUniswapV2Router(address newUniswapV2Router) external {
        onlyController();
        require(newUniswapV2Router != address(0), "ERR_ADDRESS_ZERO");
        uniswapV2Router = newUniswapV2Router;
    }

}