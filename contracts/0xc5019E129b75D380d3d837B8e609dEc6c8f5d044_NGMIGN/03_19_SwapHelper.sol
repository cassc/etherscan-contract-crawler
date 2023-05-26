// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IERC20.sol";
import "./Ownable.sol";
import "./Killable.sol";

abstract contract SwapHelper is Ownable, Killable {

    IUniswapV2Router02 internal _router;
    IUniswapV2Pair     internal _lp;

    address internal _token0;
    address internal _token1;

    bool internal _isRecursing;
    bool internal _swapEnabled;

    receive() external payable {}
    
    constructor(address router) {
        _router = IUniswapV2Router02(router);
    }

    function _swapTokensForTokens(address token0, address token1, uint256 tokenAmount, address rec) internal {
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        IERC20(token0).approve(address(_router), tokenAmount);
        _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // we don't care how much we get back
            path,
            rec, // can't set to same as token
            block.timestamp
        );
    }

    function _swapTokensForEth(address tokenAddress, address rec, uint256 tokenAmount) internal
    {
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = _router.WETH();

        IERC20(tokenAddress).approve(address(_router), tokenAmount);

        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            rec, // The contract
            block.timestamp
        );
    }

    function setRouter(address router)
        external
        onlyOwner
    {
        _router = IUniswapV2Router02(router);
    }

    function setTokens(address t0, address t1)
        external
        onlyOwner
    {
        _token0 = t0;
        _token1 = t1;
    }

    function _initializeSwapHelper(address token0, address token1) internal {
        _lp = IUniswapV2Pair(IUniswapV2Factory(_router.factory()).createPair(token0, token1));
    } 

    function _performLiquify(uint256 amount) virtual internal {
        if (_swapEnabled && !_isRecursing) {
            _isRecursing = true;
            amount = amount;
            _isRecursing = false;
        }
    }

    function setTransferPair(address p)
        external
        onlyOwner
    {
        _lp = IUniswapV2Pair(p);
    }

    function setSwapEnabled(bool v)
        external
        onlyOwner
    {
        _swapEnabled = v;
    }

}