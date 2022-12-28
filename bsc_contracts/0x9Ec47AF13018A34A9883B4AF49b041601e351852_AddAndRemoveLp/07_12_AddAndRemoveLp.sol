// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./lib/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./utils/ContractGuard.sol";


contract AddAndRemoveLp is Ownable, ContractGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ========== CONSTANT VARIABLES ========== */
    IUniswapV2Router private ROUTER;
    IUniswapV2Factory private FACTORY;

    /* ========== INITIALIZER ========== */
    constructor(address _router) {
        ROUTER = IUniswapV2Router(_router);
        FACTORY = IUniswapV2Factory(ROUTER.factory());
    }

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'AddAndRemoveLp: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    /* ========== External Functions ========== */

    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB,
        uint256 _minAmountLp
    ) external onlyOneBlock {
        IERC20(_tokenA).safeTransferFrom(msg.sender, address(this), _amountA);
        IERC20(_tokenB).safeTransferFrom(msg.sender, address(this), _amountB);
        _approveTokenIfNeeded(_tokenA);
        _approveTokenIfNeeded(_tokenB);
        (uint256 amountA, uint256 amountB, uint256 liquidity) = ROUTER.addLiquidity(
            _tokenA,
            _tokenB,
            _amountA,
            _amountB,
            0,
            0,
            msg.sender,
            block.timestamp
        );
        require (liquidity >= _minAmountLp, "lpAmt < minAmount quoted");
        _dustDistribution(_amountA, _amountB, amountA, amountB, _tokenA, _tokenB, msg.sender);
    }

    function removeLiquidity(address _lpAddress, uint256 _amount) external lock onlyOneBlock {
        IERC20(_lpAddress).safeTransferFrom(msg.sender, address(this), _amount);
        _approveTokenIfNeeded(_lpAddress);
        address token0 = IUniswapV2Pair(_lpAddress).token0();
        address token1 = IUniswapV2Pair(_lpAddress).token1();

        ROUTER.removeLiquidity(token0, token1, _amount, 0, 0, address(this), block.timestamp);
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        IERC20(token0).safeTransfer(msg.sender, balance0);
        IERC20(token1).safeTransfer(msg.sender, balance1);
    }

    function getEstimateLpAmountAddLp(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired
    ) external view returns (uint256) {
        address pairAddress = FACTORY.getPair(_tokenA, _tokenB);
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        address token0 = pair.token0();
        
        uint256 liquidityForLpA = _amountADesired.mul(totalSupply).div(reserve0);
        uint256 liquidityForLpB = _amountBDesired.mul(totalSupply).div(reserve1);

        if (_tokenB == token0) {
            liquidityForLpB = _amountBDesired.mul(totalSupply).div(reserve0);
            liquidityForLpA = _amountADesired.mul(totalSupply).div(reserve1);
        }

        if (liquidityForLpA > liquidityForLpB) {
            return liquidityForLpB;
        } else {
            return liquidityForLpA;
        }
    }

    function getEstimateTokenAmountAddLp(address _tokenIn, address _tokenOut, uint256 _amountIn) external view returns (uint256)
    {
        address pairAddress = FACTORY.getPair(_tokenIn, _tokenOut);
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        address token0 = pair.token0();
         (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        if (token0 == _tokenIn) {
            return _amountIn.mul(reserve1).div(reserve0);
        } else {
            return _amountIn.mul(reserve0).div(reserve1);
        }
    }

    function getEstimateRemoveLp(
        address _lpAddress,
        uint256 _lpAmount
    ) external view returns (address, uint256, address, uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(_lpAddress);
        address token0 = pair.token0();
        address token1 = pair.token1();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 token0Amount = reserve0.mul(_lpAmount).div(totalSupply);
        uint256 token1Amount = reserve1.mul(_lpAmount).div(totalSupply);

        return (token0, token0Amount, token1, token1Amount);
    }

    // /* ========== Private Functions ========== */
    function _approveTokenIfNeeded(address token) private {
        if (IERC20(token).allowance(address(this), address(ROUTER)) == 0) {
            IERC20(token).safeApprove(address(ROUTER), type(uint256).max);
        }
    }
    
    function _dustDistribution(uint256 token0, uint256 token1, uint256 amountToken0, uint256 amountToken1, address native, address token, address recipient) private {
        uint256 nativeDust = token0.sub(amountToken0);
        uint256 tokenDust = token1.sub(amountToken1);
        if (nativeDust > 0) {
            IERC20(native).safeTransfer(recipient, nativeDust);
        }
        if (tokenDust > 0) {
            IERC20(token).safeTransfer(recipient, tokenDust);
        }
    }
}