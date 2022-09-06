// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; 
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {ISpumeRewardPool} from "./interfaces/ISpumeRewardPool.sol";

contract SpumeSwap is Ownable, Pausable  {
    //Variables 
    ISpumeRewardPool public spumeRewardPool;
    IERC20 public weth;
    ISwapRouter public immutable swapRouter;
    //Events
    event deposit(uint256 indexed amount);
    event newRewardPool(address indexed spumeRewardPool);

    constructor(address _spumeRewardPool, address Weth) {
        swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        spumeRewardPool = ISpumeRewardPool(_spumeRewardPool);
        weth = IERC20(Weth);
    }

    // @notice Swaps a fixed amount of Token for a maximum possible amount of WETH
    function swapExactInputSingle(address _tokenIn, uint amountIn) external onlyOwner returns (uint amountOut)  {
        TransferHelper.safeApprove(_tokenIn, address(swapRouter), amountIn);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
        .ExactInputSingleParams({
            tokenIn: _tokenIn,
            tokenOut: address(weth),
            // pool fee 0.3%
            fee: 3000,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        amountOut = swapRouter.exactInputSingle(params);
    }

    /*
     * @dev Deposit WETH to RewardPool Contract 
     */  
    function depositToRewardPool() external whenNotPaused onlyOwner {
        uint256 amount = weth.balanceOf(address(this));
        require(amount > 0);
        weth.approve(address(spumeRewardPool), amount); 
        spumeRewardPool.deposit(amount); 
        emit deposit(amount);
    }
    
    /*
     * @notice Update RewardPool Address
     */  
    function updateRewardPool(address _spumeRewardPool) external onlyOwner {
        require(_spumeRewardPool != address(0), "Owner: Cannot be null address");
        spumeRewardPool = ISpumeRewardPool(_spumeRewardPool);
        emit newRewardPool(_spumeRewardPool);
    }

    /*
     * @notice Pauses Contract 
     */  
    function pauseSpumeSwap() external  onlyOwner whenNotPaused {
        _pause(); 
    }

    /*
     * @notice Unpauses Contract 
     */
    function unPauseSpumeSwap() external onlyOwner whenPaused {
        _unpause(); 
    }

    /*
     * @notice Gets the Balance of ERC20 for this contract
     */  
    function getBalances(address token) external view  {
        IERC20(token).balanceOf(address(this));
    }
}