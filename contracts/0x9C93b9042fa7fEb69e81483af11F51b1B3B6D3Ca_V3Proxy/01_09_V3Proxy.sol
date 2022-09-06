// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "Ownable.sol";
import "ERC20.sol";
import "SafeERC20.sol";
import "ReentrancyGuard.sol"; 

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);
    function refundETH() external payable;
    function WETH9() external view returns (address);
}


interface IQuoter {
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);
    
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

interface IWETH9 is IERC20 {
    function withdraw(uint) external;
}

contract V3Proxy is ReentrancyGuard, Ownable {
    using SafeERC20 for ERC20;
    ISwapRouter immutable public ROUTER;
    IQuoter     immutable public QUOTER;
     
    bool acceptPayable;
    
    event Swap(
        address indexed user, 
        address indexed assetIn,
        address indexed assetOut,
        uint256 amountIn,
        uint256 amountOut
    );
    
    constructor(ISwapRouter _router, IQuoter _quoter) {
        ROUTER = _router;
        QUOTER = _quoter;
    }
    
    function WETH() external view returns (address) {
        return ROUTER.WETH9();
    }     
    
    receive() external payable {
        require(acceptPayable, "CannotReceiveETH");
    }
    
    fallback() external payable {
       require(acceptPayable, "CannotReceiveETH");
    }
    
    function emergencyWithdraw(ERC20 token) onlyOwner external {   
        token.safeTransfer(msg.sender, token.balanceOf( address(this) ) );  // msg.sender has been Required to be owner
    }

    function getAmountsOut(uint amountIn, address[] calldata path) external returns (uint[] memory amounts) {
        require(path.length == 2, "Direct swap only");
        amounts = new uint[](2);
        amounts[0] = amountIn;
        amounts[1] = QUOTER.quoteExactInputSingle(path[0], path[1], 3000, amountIn, 0);
    }

    function getAmountsIn(uint amountOut, address[] calldata path) external returns (uint[] memory amounts) {
        require(path.length == 2, "Direct swap only");
        amounts = new uint[](2);
        amounts[0] = QUOTER.quoteExactOutputSingle(path[0], path[1], 3000, amountOut, 0);
        amounts[1] = amountOut;
    }

    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts) {
        require(path.length == 2, "Direct swap only");
        ERC20 ogInAsset = ERC20(path[0]);
        ogInAsset.safeTransferFrom(msg.sender, address(this), amountIn);
        ogInAsset.safeApprove(address(ROUTER), amountIn);
        amounts = new uint[](2);
        amounts[0] = amountIn;         
        amounts[1] = ROUTER.exactInputSingle(ISwapRouter.ExactInputSingleParams(path[0], path[1], 3000, msg.sender, deadline, amountIn, amountOutMin, 0));
        emit Swap(msg.sender, path[0], path[1], amounts[0], amounts[1]); 
    }

    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts) {
        require(path.length == 2, "Direct swap only");
        ERC20 ogInAsset = ERC20(path[0]);
        ogInAsset.safeTransferFrom(msg.sender, address(this), amountInMax);
        ogInAsset.safeApprove(address(ROUTER), amountInMax);
        amounts = new uint[](2);
        amounts[0] = ROUTER.exactOutputSingle(ISwapRouter.ExactOutputSingleParams(path[0], path[1], 3000, msg.sender, deadline, amountOut, amountInMax, 0));         
        amounts[1] = amountOut; 
        ogInAsset.safeTransfer(msg.sender, ogInAsset.balanceOf(address(this)));
        ogInAsset.safeApprove(address(ROUTER), 0);
        emit Swap(msg.sender, path[0], path[1], amounts[0], amounts[1]); 
    }

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) payable external returns (uint[] memory amounts) {
        require(path.length == 2, "Direct swap only");
        require(path[0] == ROUTER.WETH9(), "Invalid path");
        amounts = new uint[](2);
        amounts[0] = msg.value;         
        amounts[1] = ROUTER.exactInputSingle{value: msg.value}(ISwapRouter.ExactInputSingleParams(path[0], path[1], 3000, msg.sender, deadline, msg.value, amountOutMin, 0));
        emit Swap(msg.sender, path[0], path[1], amounts[0], amounts[1]);  
    }

    
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) payable external returns (uint[] memory amounts) {
        require(path.length == 2, "Direct swap only");
        require(path[0] == ROUTER.WETH9(), "Invalid path");
        amounts = new uint[](2);
        amounts[0] = ROUTER.exactOutputSingle{value: msg.value}(ISwapRouter.ExactOutputSingleParams(path[0], path[1], 3000, msg.sender, deadline, amountOut, msg.value, 0));         
        amounts[1] = amountOut;
        acceptPayable = true;
        ROUTER.refundETH();
        acceptPayable = false;
        msg.sender.call{value: msg.value - amounts[0]}("");
        emit Swap(msg.sender, path[0], path[1], amounts[0], amounts[1]); 
    }
    
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) payable external returns (uint[] memory amounts) {
        require(path.length == 2, "Direct swap only");
        require(path[1] == ROUTER.WETH9(), "Invalid path");
        ERC20 ogInAsset = ERC20(path[0]);
        ogInAsset.safeTransferFrom(msg.sender, address(this), amountInMax);
        ogInAsset.safeApprove(address(ROUTER), amountInMax);
        amounts = new uint[](2);
        amounts[0] = ROUTER.exactOutputSingle(ISwapRouter.ExactOutputSingleParams(path[0], path[1], 3000, address(this), deadline, amountOut, amountInMax, 0));         
        amounts[1] = amountOut; 
        ogInAsset.safeApprove(address(ROUTER), 0);
        IWETH9 weth = IWETH9(ROUTER.WETH9());
        acceptPayable = true;
        weth.withdraw(amountOut);
        acceptPayable = false;
        payable(msg.sender).call{value: amountOut}("");
        emit Swap(msg.sender, path[0], path[1], amounts[0], amounts[1]); 
    }
       
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) payable external returns (uint[] memory amounts) {
        require(path.length == 2, "Direct swap only");
        require(path[1] == ROUTER.WETH9(), "Invalid path");
        ERC20 ogInAsset = ERC20(path[0]);
        ogInAsset.safeTransferFrom(msg.sender, address(this), amountIn);
        ogInAsset.safeApprove(address(ROUTER), amountIn);
        amounts = new uint[](2);
        amounts[0] = amountIn;         
        amounts[1] = ROUTER.exactInputSingle(ISwapRouter.ExactInputSingleParams(path[0], path[1], 3000, address(this), deadline, amountIn, amountOutMin, 0)); 
        IWETH9 weth = IWETH9(ROUTER.WETH9());
        acceptPayable = true;
        weth.withdraw(amounts[1]);
        acceptPayable = false;
        payable(msg.sender).call{value: amounts[1]}("");
        emit Swap(msg.sender, path[0], path[1], amounts[0], amounts[1]);                 
    }

}