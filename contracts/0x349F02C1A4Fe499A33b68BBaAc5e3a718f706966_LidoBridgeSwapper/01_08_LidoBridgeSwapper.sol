//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "./ZkSyncBridgeSwapper.sol";
import "./interfaces/IZkSync.sol";
import "./interfaces/IWstETH.sol";
import "./interfaces/ILido.sol";
import "./interfaces/ICurvePool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
* Exchanges between ETH and wStETH
* index 0: ETH
* index 1: wStETH
*/
contract LidoBridgeSwapper is ZkSyncBridgeSwapper {

    // The address of the stEth token
    address public immutable stEth;
    // The address of the wrapped stEth token
    address public immutable wStEth;
    // The address of the stEth/Eth Curve pool
    address public immutable stEthPool;
    // The referral address for Lido
    address public immutable lidoReferral;

    constructor(
        address _zkSync,
        address _l2Account,
        address _wStEth,
        address _stEthPool,
        address _lidoReferral
    )
        ZkSyncBridgeSwapper(_zkSync, _l2Account)
    {
        wStEth = _wStEth;
        address _stEth = IWstETH(_wStEth).stETH();
        require(_stEth == ICurvePool(_stEthPool).coins(1), "stEth mismatch");
        stEth = _stEth;
        stEthPool = _stEthPool;
        lidoReferral = _lidoReferral;
    }

    function exchange(
        uint256 _indexIn,
        uint256 _indexOut,
        uint256 _amountIn,
        uint256 _minAmountOut
    ) 
        onlyOwner
        external 
        override 
        returns (uint256 amountOut) 
    {
        require(_indexIn + _indexOut == 1, "invalid indexes");

        if (_indexIn == 0) {
            transferFromZkSync(ETH_TOKEN);
            amountOut = swapEthForWstEth(_amountIn);
            require(amountOut >= _minAmountOut, "slippage");
            transferToZkSync(wStEth, amountOut);
            emit Swapped(ETH_TOKEN, _amountIn, wStEth, amountOut);
        } else {
            transferFromZkSync(wStEth);
            amountOut = swapWstEthForEth(_amountIn);
            require(amountOut >= _minAmountOut, "slippage");
            transferToZkSync(ETH_TOKEN, amountOut);
            emit Swapped(wStEth, _amountIn, ETH_TOKEN, amountOut);
        }
    }

    /**
    * @dev Swaps ETH for wrapped stETH and deposits the resulting wstETH to the ZkSync bridge.
    * First withdraws ETH from the bridge if there is a pending balance.
    * @param _amountIn The amount of ETH to swap.
    */
    function swapEthForWstEth(uint256 _amountIn) internal returns (uint256) {
        uint256 dy = ICurvePool(stEthPool).get_dy(0, 1, _amountIn);
        uint256 stEthAmount;

        // if stETH below parity on Curve get it there, otherwise stake on Lido contract
        if (dy > _amountIn) {
            stEthAmount = ICurvePool(stEthPool).exchange{value: _amountIn}(0, 1, _amountIn, 1);
        } else {
            ILido(stEth).submit{value: _amountIn}(lidoReferral);
            stEthAmount = _amountIn;
        }

        // approve the wStEth contract to take the stEth
        IERC20(stEth).approve(wStEth, stEthAmount);
        // wrap to wStEth and return deposited amount
        return IWstETH(wStEth).wrap(stEthAmount);
    }

    /**
    * @dev Swaps wrapped stETH for ETH and deposits the resulting ETH to the ZkSync bridge.
    * First withdraws wrapped stETH from the bridge if there is a pending balance.
    * @param _amountIn The amount of wrapped stETH to swap.
    */
    function swapWstEthForEth(uint256 _amountIn) internal returns (uint256) {
        // unwrap to stEth
        uint256 unwrapped = IWstETH(wStEth).unwrap(_amountIn);
        // approve pool
        bool success = IERC20(stEth).approve(stEthPool, unwrapped);
        require(success, "approve failed");
        // swap stEth for ETH on Curve and return deposited amount
        return ICurvePool(stEthPool).exchange(1, 0, unwrapped, 1);
    }
}