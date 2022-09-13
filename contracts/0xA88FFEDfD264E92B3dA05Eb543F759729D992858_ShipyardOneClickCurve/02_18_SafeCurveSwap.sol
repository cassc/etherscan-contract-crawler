// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/curve/ICurveSwap.sol";

library SafeCurveSwap {

    using SafeMath for uint256;

    // 2 length array of amounts

    function safeAddLiquidity(
        ICurveSwap _used,
        uint[2] memory _slippage,
        uint256[2] memory _amounts
    ) internal {

        uint256 minMintAmount = _used.calc_token_amount(_amounts, true).mul(_slippage[0]).div(_slippage[1]);

        _used.add_liquidity(_amounts, minMintAmount);
    }

    function safeAddLiquidity(
        ICurveSwap _pool,
        uint[2] memory _slippage,
        uint256[2] memory _amounts,
        uint256 _depositNativeAmount
    ) internal {

        uint256 minMintAmount = _pool.calc_token_amount(_amounts, true).mul(_slippage[0]).div(_slippage[1]);

        _pool.add_liquidity{value : _depositNativeAmount}(_amounts, minMintAmount);
    }

    function safeAddLiquidityUsingNoDepositSlippageCalculation(
        ICurveSwap _pool,
        uint[2] memory _slippage,
        uint256[2] memory _amounts
    ) internal {

        uint256 minMintAmount = _pool.calc_token_amount(_amounts).mul(_slippage[0]).div(_slippage[1]);

        _pool.add_liquidity(_amounts, minMintAmount);
    }

    function safeAddLiquidity(
        ICurveSwap _used,
        uint[2] memory _slippage,
        uint256[2] memory _amounts,
        bool _useUnderlying
    ) internal {

        uint256 minMintAmount = _used.calc_token_amount(_amounts, true).mul(_slippage[0]).div(_slippage[1]);

        _used.add_liquidity(_amounts, minMintAmount, _useUnderlying);
    }

    function safeAddLiquidity(
        ICurveSwap _used,
        address _pool,
        uint[2] memory _slippage,
        uint256[2] memory _amounts
    ) internal {

        uint256 minMintAmount = _used.calc_token_amount(_amounts, true).mul(_slippage[0]).div(_slippage[1]);

        _used.add_liquidity(_pool, _amounts, minMintAmount);
    }

    // 3 length array of amounts

    function safeAddLiquidity(
        ICurveSwap _used,
        uint[2] memory _slippage,
        uint256[3] memory _amounts
    ) internal {

        uint256 minMintAmount = _used.calc_token_amount(_amounts, true).mul(_slippage[0]).div(_slippage[1]);

        _used.add_liquidity(_amounts, minMintAmount);
    }

    function safeAddLiquidity(
        ICurveSwap _used,
        uint[2] memory _slippage,
        uint256[3] memory _amounts,
        bool _useUnderlying
    ) internal {

        uint256 minMintAmount = _used.calc_token_amount(_amounts, true).mul(_slippage[0]).div(_slippage[1]);

        _used.add_liquidity(_amounts, minMintAmount, _useUnderlying);
    }

    function safeAddLiquidity(
        ICurveSwap _used,
        uint[2] memory _slippage,
        address _pool,
        uint256[3] memory _amounts
    ) internal {

        uint256 minMintAmount = _used.calc_token_amount(_amounts, true).mul(_slippage[0]).div(_slippage[1]);

        _used.add_liquidity(_pool, _amounts, minMintAmount);
    }

    // 4 length array of amounts

    function safeAddLiquidity(
        ICurveSwap _used,
        uint[2] memory _slippage,
        uint256[4] memory _amounts
    ) internal {

        uint256 minMintAmount = _used.calc_token_amount(_amounts, true).mul(_slippage[0]).div(_slippage[1]);

        _used.add_liquidity(_amounts, minMintAmount);
    }

    function safeAddLiquidity(
        ICurveSwap _used,
        uint[2] memory _slippage,
        address _pool,
        uint256[4] memory _amounts
    ) internal {

        uint256 minMintAmount = _used.calc_token_amount(_amounts, true).mul(_slippage[0]).div(_slippage[1]);

        _used.add_liquidity(_pool, _amounts, minMintAmount);
    }

    // 5 length array of amounts

    function safeAddLiquidity(
        ICurveSwap _used,
        uint[2] memory _slippage,
        uint256[5] memory _amounts
    ) internal {

        uint256 minMintAmount = _used.calc_token_amount(_amounts, true).mul(_slippage[0]).div(_slippage[1]);

        _used.add_liquidity(_amounts, minMintAmount);
    }

    //

    function safeRemoveLiquidityOneCoin(
        ICurveSwap _used,
        uint[2] memory _slippage,
        uint256 tokenAmount,
        int128 index
    ) internal {

        uint256 minMintAmount = _used.calc_withdraw_one_coin(tokenAmount, index).mul(_slippage[0]).div(_slippage[1]);

        _used.remove_liquidity_one_coin(tokenAmount, index, minMintAmount);
    }

}