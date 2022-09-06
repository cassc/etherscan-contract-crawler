// SPDX-License-Identifier: BSD-3-Clause
pragma solidity >=0.8.9;

// Author: Angry Wasp
// [email protected]

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import "./include/SecureContract.sol";
import "./include/WETH9Interface.sol";
import "./include/DexInterface.sol";

struct Dex {
    uint256 id;
    address wrappedTokenAddress;
    address router;
    uint256 fee;
}

contract Trader is SecureContract
{
    using SafeERC20 for IERC20;

    mapping(uint256 => Dex) private _dexs;

    event Initialized();

    constructor() {}
    receive() external payable {}

    function initialize() public initializer
    {
        SecureContract.init();
        emit Initialized();
    }

    function addDex(uint256 id, address wrappedTokenAddress, address router, uint256 fee) public isAdmin
    {
        _dexs[id] = Dex(id, wrappedTokenAddress, router, fee);
    }

    function queryDex(uint256 id) public view returns (Dex memory) { return _dexs[id]; }

    function calculateFee(uint256 id, uint256 amount) public view returns (uint256) { return (amount / 10000) * _dexs[id].fee; }

    function swapExactTokensForETH(uint256 id, uint256 amountIn, uint256 amountOutMin, address[] calldata path, uint256 deadline)
        public pause returns (uint256[] memory amounts)
    {
        Dex memory dex = _dexs[id];

        uint256 fee = calculateFee(id, amountIn);
        uint256 finalAmount = amountIn - fee;

        IERC20 token = IERC20(path[0]);

        approve(token, address(this), dex.router, amountIn);

        token.safeTransferFrom(msg.sender, address(this), amountIn);

        return DexInterface(dex.router).swapExactTokensForETH(finalAmount, amountOutMin, path, msg.sender, deadline);
    }

    function swapExactETHForTokens(uint256 id, uint256 amountOutMin, address[] calldata path, uint256 deadline)
        public payable pause returns (uint256[] memory amounts)
    {
        Dex memory dex = _dexs[id];

        uint256 fee = calculateFee(id, msg.value);

        return DexInterface(dex.router).swapExactETHForTokens{ value: msg.value - fee }(amountOutMin, path, msg.sender, deadline);
    }

    function swapExactTokensForTokens(uint256 id, uint256 amountIn, uint256 amountOutMin, address[] calldata path, uint256 deadline)
        public pause returns (uint256[] memory amounts)
    {
        Dex memory dex = _dexs[id];

        uint256 fee = calculateFee(id, amountIn);
        IERC20 token = IERC20(path[0]);
        approve(token, address(this), dex.router, amountIn);
        token.safeTransferFrom(msg.sender, address(this), amountIn);

        return DexInterface(dex.router).swapExactTokensForTokens(amountIn - fee, amountOutMin, path, msg.sender, deadline);
    }

    function swapExactETHForTokensV3Single(uint256 id, uint256 amountOutMin, address swapOut, uint24 poolFee, uint256 deadline) public payable pause
    {
        Dex memory dex = _dexs[id];

        uint256 fee = calculateFee(id, msg.value);
        IWETH9 weth9 = IWETH9(dex.wrappedTokenAddress);
        weth9.deposit{ value: msg.value - fee }();
        approve(IERC20(dex.wrappedTokenAddress), address(this), dex.router, msg.value);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: dex.wrappedTokenAddress,
                tokenOut: swapOut,
                fee: poolFee,
                recipient: msg.sender,
                deadline: deadline,
                amountIn: msg.value - fee,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: 0
            });

        ISwapRouter(dex.router).exactInputSingle(params);
    }

    function swapExactTokensForETHV3Single(uint256 id, uint256 amountIn, uint256 amountOutMin, address swapIn, uint24 poolFee, uint256 deadline) public payable pause
    {
        Dex memory dex = _dexs[id];
        uint256 fee = calculateFee(id, amountIn);
        IWETH9 weth9 = IWETH9(dex.wrappedTokenAddress);
        IERC20 token = IERC20(swapIn);
        approve(token, address(this), dex.router, amountIn);
        token.safeTransferFrom(msg.sender, address(this), amountIn);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: swapIn,
                tokenOut: dex.wrappedTokenAddress,
                fee: poolFee,
                recipient: address(this),
                deadline: deadline,
                amountIn: amountIn - fee,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: 0
            });

        uint256 amountOut = ISwapRouter(dex.router).exactInputSingle(params);
        weth9.withdraw(amountOut);
        payable(msg.sender).transfer(amountOut);
    }

    function swapExactTokensForTokensV3Single(uint256 id, uint256 amountIn, uint256 amountOutMin, address swapIn, address swapOut, uint24 poolFee, uint256 deadline) public pause
    {
        Dex memory dex = _dexs[id];
        uint256 fee = calculateFee(id, amountIn);
        IERC20 token = IERC20(swapIn);
        approve(token, address(this), dex.router, amountIn);
        token.safeTransferFrom(msg.sender, address(this), amountIn);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: swapIn,
                tokenOut: swapOut,
                fee: poolFee,
                recipient: msg.sender,
                deadline: deadline,
                amountIn: amountIn - fee,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: 0
            });

        ISwapRouter(dex.router).exactInputSingle(params);
    }

    function swapExactETHForTokensV3Multi(uint256 id, uint256 amountOutMin, bytes calldata path, uint256 deadline) public payable
    {
        Dex memory dex = _dexs[id];

        uint256 fee = calculateFee(id, msg.value);
        IWETH9 weth9 = IWETH9(dex.wrappedTokenAddress);
        weth9.deposit{ value: msg.value - fee }();
        approve(IERC20(dex.wrappedTokenAddress), address(this), dex.router, msg.value - fee);

        ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: path,
                recipient: msg.sender,
                deadline: deadline,
                amountIn: msg.value - fee,
                amountOutMinimum: amountOutMin
            });

        ISwapRouter(dex.router).exactInput(params);
    }

    function swapExactTokensForTokensV3Multi(uint256 id, uint256 amountIn, uint256 amountOutMin, bytes calldata path, uint256 deadline) public pause
    {
        Dex memory dex = _dexs[id];
        uint256 fee = calculateFee(id, amountIn);
        IERC20 token = IERC20(extractFirstHop(path));
        approve(token, address(this), dex.router, amountIn);
        token.safeTransferFrom(msg.sender, address(this), amountIn);

        ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: path,
                recipient: msg.sender,
                deadline: deadline,
                amountIn: amountIn - fee,
                amountOutMinimum: amountOutMin
            });

        ISwapRouter(dex.router).exactInput(params);
    }

    function swapExactTokensForETHV3Multi(uint256 id, uint256 amountIn, uint256 amountOutMin, bytes calldata path, uint256 deadline) public payable pause
    {
        Dex memory dex = _dexs[id];
        uint256 fee = calculateFee(id, amountIn);
        IWETH9 weth9 = IWETH9(dex.wrappedTokenAddress);
        IERC20 token = IERC20(extractFirstHop(path));
        approve(token, address(this), dex.router, amountIn);
        token.safeTransferFrom(msg.sender, address(this), amountIn);

        ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: path,
                recipient: address(this),
                deadline: deadline,
                amountIn: amountIn - fee,
                amountOutMinimum: amountOutMin
            });

        uint256 amountOut = ISwapRouter(dex.router).exactInput(params);
        weth9.withdraw(amountOut);
        payable(msg.sender).transfer(amountOut);
    }

    function approve(IERC20 token, address owner, address spender, uint256 amount) private
    {
        uint256 allowance = token.allowance(owner, spender);

        if (amount > allowance)
            require(token.approve(spender, type(uint256).max), "Trader: Token approval failed");
    }

    function withdrawEth(address to) public isAdmin
    {
        payable(to).transfer(address(this).balance);
    }

    function withdrawToken(address to, address token) public isAdmin
    {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(to, balance);
    }

    function extractFirstHop(bytes memory path) private pure returns (address)
    {
        address a;

        assembly {
            a := mload(add(path, 20))
        }

        return a;
    }
}