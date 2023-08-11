// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.16;

import "./interfaces/IWETH.sol";
import "./interfaces/ISwapV2Router.sol";
import "./interfaces/ISwapV3Router.sol";
import "./libraries/TransferHelper.sol";


contract SwapCentral {
    address public immutable WETH;
    address public owner;
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    ISwapV2Router private constant routerV2 = ISwapV2Router(UNISWAP_V2_ROUTER);
    ISwapV3Router private constant routerV3 = ISwapV3Router(UNISWAP_V3_ROUTER);

    event NewOwner(address indexed owner, uint time);
    event WithdrawETH(uint amount, uint time);
    event WithdrawToken(address indexed token, uint amount, uint time);
    
    constructor(address _WETH){
        require(_WETH != address(0), "please put the correct WETH token address");
        WETH = _WETH;
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "you're not the owner");
        _;
    }

    //---------------Uniswap V2 Starts Here----------------------//
    //get estimation output
    function V2GetEstimatedOut(uint amountIn, address tokenIn, address tokenOut) external view returns (uint[] memory){
        address[] memory path = createPath(tokenIn, tokenOut);
        return routerV2.getAmountsOut(amountIn, path);
    }

    //get estimation input
    function V2GetEstimatedIn(uint amountOutDesired, address tokenIn, address tokenOut) external view returns (uint[] memory){
        address[] memory path = createPath(tokenIn, tokenOut);
        return routerV2.getAmountsIn(amountOutDesired, path);
    }


    //1. token exact amount in, exact token -> token 
    function V2SwapExactTokensForTokens(
        address caller,
        address tokenIn, 
        address tokenOut, 
        uint amountIn, 
        uint amountOutMin,
        uint deadlineInSeconds
    ) external returns (uint[] memory amounts)
    {
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        TransferHelper.safeApprove(tokenIn, UNISWAP_V2_ROUTER, amountIn);

        address[] memory path = createPath(tokenIn, tokenOut);
        amounts = routerV2.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            caller,
            block.timestamp + deadlineInSeconds
        );
    }

    //2. token exact amount out, token -> exact token
    function V2SwapTokensForExactTokens(
        address caller, 
        address tokenIn,
        address tokenOut,
        uint amountOutDesired,
        uint amountInMax,
        uint deadlineInSeconds
    ) external returns (uint[] memory amounts) 
    {
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountInMax);
        TransferHelper.safeApprove(tokenIn, UNISWAP_V2_ROUTER, amountInMax);

        address[] memory path = createPath(tokenIn, tokenOut);
        amounts = routerV2.swapTokensForExactTokens(
            amountOutDesired,
            amountInMax,
            path,
            caller,
            block.timestamp + deadlineInSeconds
        );

        // refund the change to caller
        if(amounts[0] < amountInMax){
            TransferHelper.safeApprove(tokenIn, UNISWAP_V2_ROUTER, 0);
            TransferHelper.safeTransfer(tokenIn, caller, amountInMax - amounts[0]);
        }
    }

    //3. ETH exact amount in, exact ETH -> token
    function V2SwapExactETHForTokens(
        address caller, 
        address tokenOut, 
        uint amountOutMin,
        uint deadlineInSeconds
    ) external payable returns (uint[] memory amounts)
    {
        address[] memory path = createPath(WETH, tokenOut);
        amounts = routerV2.swapExactETHForTokens{value: msg.value}(
            amountOutMin,
            path,
            caller,
            block.timestamp + deadlineInSeconds
        );
    }

    //4. ETH exact amount out, token -> exact ETH
    function V2SwapTokensForExactETH(
        address caller, 
        address tokenIn, 
        uint amountOut, 
        uint amountInMax,
        uint deadlineInSeconds
    ) external returns (uint[] memory amounts)
    {
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountInMax);
        TransferHelper.safeApprove(tokenIn, UNISWAP_V2_ROUTER, amountInMax);

        address[] memory path = createPath(tokenIn, WETH);
        amounts = routerV2.swapTokensForExactETH(
            amountOut,
            amountInMax,
            path,
            caller,
            block.timestamp + deadlineInSeconds
        );

        // refund the change to caller
        if(amounts[0] < amountInMax){
            TransferHelper.safeApprove(tokenIn, UNISWAP_V2_ROUTER, 0);
            TransferHelper.safeTransfer(tokenIn, caller, amountInMax - amounts[0]);
        }
    }

    // 5. token exact amount in, exact token -> ETH
    function V2SwapExactTokensForETH(
        address caller, 
        address tokenIn, 
        uint amountIn, 
        uint amountOutMin,
        uint deadlineInSeconds
    ) external returns (uint[] memory amounts)
    {
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        TransferHelper.safeApprove(tokenIn, UNISWAP_V2_ROUTER, amountIn);

        address[] memory path = createPath(tokenIn, WETH);
        amounts = routerV2.swapExactTokensForETH(
            amountIn,
            amountOutMin,
            path,
            caller,
            block.timestamp + deadlineInSeconds
        );
    }

    // 6. token exact amout out, ETH -> exact token
    function V2SwapETHForExactTokens(
        address caller, 
        address tokenOut, 
        uint amountOut,
        uint deadlineInSeconds
    ) external payable returns (uint[] memory amounts)
    {
        address[] memory path = createPath(WETH, tokenOut);
        amounts = routerV2.swapETHForExactTokens{value: msg.value}(
            amountOut,
            path,
            caller,
            block.timestamp + deadlineInSeconds
        );
        // refund the change to caller
        if(amounts[0] < msg.value){
            TransferHelper.safeTransferETH(caller, msg.value - amounts[0]);
        }
    }

    // These functions below are for tokens that require fee when doing transactions
    // 7. token exact input -> token
    function V2SwapExactTokensForTokensSupportingFeeOnTransferTokens(
        address caller, 
        address tokenIn, 
        address tokenOut, 
        uint amountIn, 
        uint amountOutMin,
        uint deadlineInSeconds
    ) external 
    {
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        TransferHelper.safeApprove(tokenIn, UNISWAP_V2_ROUTER, amountIn);

        address[] memory path = createPath(tokenIn, tokenOut);
        routerV2.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            caller,
            block.timestamp + deadlineInSeconds
        );
    }

    // 8. ETH exact input -> token
    function V2SwapExactETHForTokensSupportingFeeOnTransferTokens(
        address caller, 
        address tokenOut, 
        uint amountOutMin,
        uint deadlineInSeconds
    ) external payable
    {
        address[] memory path = createPath(WETH, tokenOut);
        routerV2.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            amountOutMin,
            path,
            caller,
            block.timestamp + deadlineInSeconds
        );
    }

    // 9. Token exact input -> ETH 
    function V2SwapExactTokensForETHSupportingFeeOnTransferTokens(
        address caller, 
        address tokenIn, 
        uint amountIn, 
        uint amountOutMin,
        uint deadlineInSeconds
    ) external
    {
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        TransferHelper.safeApprove(tokenIn, UNISWAP_V2_ROUTER, amountIn);

        address[] memory path = createPath(tokenIn, WETH);
        routerV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            caller,
            block.timestamp + deadlineInSeconds
        );
    }


    // create path
    function createPath(address tokenIn, address tokenOut) private pure returns (address[] memory){
        address[] memory path = new address[](2);
        path[0] = tokenIn; //input token
        path[1] = tokenOut; //output token
        return path;
    }

    //---------------Uniswap V3 Starts Here----------------------//
    function V3SwapExactInputSingleHop(
        address caller, 
        address tokenIn, 
        address tokenOut,
        uint24 fee, 
        uint amountIn, 
        uint amountOutMin, 
        uint deadlineInSeconds,
        uint160 sqrtPriceLimitX96
    ) external returns (uint amountOut)
    {
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        TransferHelper.safeApprove(tokenIn, address(UNISWAP_V3_ROUTER), amountIn);
        

        ISwapV3Router.ExactInputSingleParams memory params = ISwapV3Router
            .ExactInputSingleParams({ 
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: fee,
                recipient: caller,
                deadline: block.timestamp + deadlineInSeconds,
                amountIn: amountIn,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: sqrtPriceLimitX96
            });
        amountOut = routerV3.exactInputSingle(params);
    }

    function V3SwapExactOutputSingleHop(
        address caller, 
        address tokenIn, 
        address tokenOut, 
        uint24 fee, 
        uint amountOut, 
        uint amountInMax,
        uint deadlineInSeconds,
        uint160 sqrtPriceLimitX96
    ) external returns (uint amountIn)
    {
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountInMax);
        TransferHelper.safeApprove(tokenIn, address(UNISWAP_V3_ROUTER), amountInMax);
        
        ISwapV3Router.ExactOutputSingleParams memory params = ISwapV3Router
            .ExactOutputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: fee,
                recipient: caller,
                deadline: block.timestamp + deadlineInSeconds,
                amountOut: amountOut,
                amountInMaximum: amountInMax,
                sqrtPriceLimitX96: sqrtPriceLimitX96
            });
        amountIn = routerV3.exactOutputSingle(params);

        // refund to caller
        if (amountIn < amountInMax) {
            TransferHelper.safeApprove(tokenIn, address(UNISWAP_V3_ROUTER), 0);
            TransferHelper.safeTransfer(tokenIn, caller, amountInMax - amountIn);
        }
    }

    //---------------Universal Getter Functions----------------------//
    
    function checkETHBalance() external view returns (uint) {
        return address(this).balance;
    }

    function checkTokenBalance(address token) external view returns (uint){
        return IERC20(token).balanceOf(address(this));
    }

    function withdrawETH() external onlyOwner {
        uint amount = address(this).balance;

        emit WithdrawETH(amount, block.timestamp);
        TransferHelper.safeTransferETH(owner, amount);  
    }

    function withdrawToken(address token) external onlyOwner {
        uint amount = IERC20(token).balanceOf(address(this));
    
        emit WithdrawToken(token, amount, block.timestamp);
        TransferHelper.safeTransfer(token, owner, amount);    
    }

    function changeOwner(address newOwner) external onlyOwner {      
        require(newOwner != address(0), "new candidate can't be address zero");
        owner = newOwner;

        emit NewOwner(newOwner, block.timestamp);
    }
    receive() external payable {}
    fallback() external payable {}
}