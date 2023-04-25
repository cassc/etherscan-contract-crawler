// SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

import "../interface/IUniswapRouterV2.sol";
import "../interface/IUniswapV2Factory.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol';
import "./BaseSwapper.sol";

/*
    Expands swapping functionality over base strategy
    - ETH in and ETH out Variants
    - Sushiswap support in addition to Uniswap
*/
contract UniswapSwapper is BaseSwapper {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using BytesLib for bytes;

    address public uniswapV2; // Uniswap router
    address public sushiswap; // Sushiswap router
    address public uniswapV3; // Uniswapv3 router
    address public oracleRouter; // Aggregator chainlink oracle

    function _setUniswapV2Router(address _router) internal {
        uniswapV2 = _router;
    }

    function _setSushiswapRouter(address _router) internal {
        sushiswap = _router;
    }

    function _setUniswapV3Router(address _router) internal {
        uniswapV3 = _router;
    }

    function _setOracleRouter(address _router) internal {
        oracleRouter = _router;
    }

    // V2
    function _swapExactTokensForTokens(
        address _router,
        address _startToken,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path,
        bytes memory _pathEncoded
    ) internal returns(uint[] memory){
        require(_path.length > 0 || _pathEncoded.length > 0, "path not valid");
        if(_pathEncoded.length > 0 ) {
            _path = _encodePathDataV2(_pathEncoded);
        }
        _safeApproveHelper(_startToken, _router, _amountIn);
        return IUniswapRouterV2(_router).swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            _path,
            address(this),
            block.timestamp
        );
    }

    // V3
    function _swapExactInputMultihop(
        address _router,
        address _startToken,
        uint256 _amountIn,
        uint256 _amountsOutMin,
        bytes memory _pathData
    ) internal returns(uint){
        ISwapRouter swapRouter = ISwapRouter(_router);

        TransferHelper.safeApprove(_startToken, address(swapRouter), 0);
        TransferHelper.safeApprove(_startToken, address(swapRouter), _amountIn);

        ISwapRouter.ExactInputParams memory params =
        ISwapRouter.ExactInputParams({
            path: _pathData,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: _amountIn,
            amountOutMinimum: _amountsOutMin
        });

        // Executes the swap.
        return swapRouter.exactInput(params);
    }

    // INTERNAL

    function _encodePathDataV2(bytes memory _data) internal pure returns(address[] memory){
        require(_data.length % 20 == 0, "Invalid encoded path length");
        uint256 numAddresses = _data.length / 20;
        address[] memory addresses = new address[](numAddresses);
        for (uint256 i = 0; i < numAddresses; i++) {
            addresses[i] = _bytesToAddress(_data.slice(20*i, 20));
        }
        return addresses;
    }

    function _bytesToAddress(bytes memory _data) internal pure returns (address addr) {
        assembly {
            addr := mload(add(_data, 20))
        }
    }


}