// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma abicoder v2;

// Uncomment this line to use console.log
import "hardhat/console.sol";

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract UniswapFlashSwap {

    ISwapRouter public constant swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);


    address public constant factoryAddress = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    uint256 private constant MAX_INT =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;
    
    address public TOKEN1;
    address public TOKEN2;
    address public TOKEN3;
    uint24 public pool1Fee;
    uint24 public pool2Fee;
    uint24 public pool3Fee;

    function setVariables(address token1, address token2 , address token3, uint24 _pool1Fee, uint24 _pool2Fee, uint24 _pool3Fee) public{
                TOKEN1 = token1;
                TOKEN2 = token2;
                TOKEN3 = token3;
                pool1Fee = _pool1Fee;
                pool2Fee = _pool2Fee;
                pool3Fee = _pool3Fee;
    }


    // CHECK PROFITABILITY
    // Checks whether > output > input
    function checkProfitability(uint256 _input, uint256 _output)
        private
        returns (bool)
    {
        return _output > _input;
    }

    //Approve tokens and call the swap function
    function startArbitrage(address tokenBorrow, int256 amount) public{

        TransferHelper.safeApprove(TOKEN1, address(swapRouter), MAX_INT);    
        TransferHelper.safeApprove(TOKEN2, address(swapRouter), MAX_INT);    
        TransferHelper.safeApprove(TOKEN3, address(swapRouter), MAX_INT);    

        address pair = IUniswapV3Factory(factoryAddress).getPool(
            TOKEN1,
            TOKEN2,
            pool1Fee
        );

        // Return error if combination does not exist
        require(pair != address(0), "Pool does not exist");
       
        // Passing data as bytes so that the 'swap' function knows it is a flashloan
        
        bytes memory data = abi.encode(amount, tokenBorrow);

        // Execute the initial swap to get the loan
		console.log(address(this));
        IUniswapV3PoolActions(pair).swap(address(this), true, amount, 100000000000, data);
		console.log('success');
    }




    //Swap token2 and token3 back to token1

     function swapExactInputMultihop(uint amountIn ) public returns (uint256 amountOut) {

       ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: abi.encodePacked(TOKEN2, pool2Fee, TOKEN3, pool3Fee, TOKEN1),
                recipient: msg.sender, 
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0
            });

        // Executes the swap.
        console.log(amountIn);
        amountOut = swapRouter.exactInput(params);
        console.log(amountOut);
		return amountOut;
    }

    function uniswapV3SwapCallback(
    int256 amount0Delta,
    int256 amount1Delta,
    bytes calldata data
  ) external {
    address _token0 = IUniswapV3Pool(msg.sender).token0();
        address _token1 = IUniswapV3Pool(msg.sender).token1();
        uint24 fee = IUniswapV3Pool(msg.sender).fee();
        address pair = IUniswapV3Factory(factoryAddress).getPool(
            _token0,
            _token1,
            fee
        );
        
        require(msg.sender == pair, "The sender needs to match the pair");

        // Decode data for calculating the repayment
                (int256 amountIn, address tokenBorrow) = abi.decode(
            data,
            (int256, address)
        );

        uint token2Balance = IERC20(_token1).balanceOf(address(this));
        uint amountOut = swapExactInputMultihop(token2Balance);

        // Check Profitability
        bool profCheck = checkProfitability(uint(amountIn), amountOut);
        require(profCheck, "Arbitrage not profitable");
        
        int256 loanAmount = amount0Delta > 0 ? amount0Delta : amount1Delta;

        IERC20(tokenBorrow).transfer(pair, uint(loanAmount));
  }

}