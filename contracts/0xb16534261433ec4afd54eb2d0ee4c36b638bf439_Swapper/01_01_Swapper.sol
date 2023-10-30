// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    function approve(address, uint256) external returns (bool);
}

interface IV2SwapRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IV3SwapRouter {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);
}

contract Swapper {
    enum SwapKind {
        UniswapV2,
        UniswapV3
    }

    function swap(
        IERC20 _token,
        uint256 _amountInPrev,
        uint256 _amountOutMinPrev,
        address _callee,
        bytes calldata _data,
        SwapKind _kind
    ) external {
        uint256 amountIn = _token.balanceOf(address(this));
        uint256 amountOutMin = (_amountOutMinPrev * amountIn) / _amountInPrev;
        _approve(_token, _callee, amountIn);
        if (_kind == SwapKind.UniswapV2) {
            _swapUniswapV2(amountIn, amountOutMin, _callee, _data);
        } else if (_kind == SwapKind.UniswapV3) {
            _swapUniswapV3(amountIn, amountOutMin, _callee, _data);
        }
    }

    function _approve(IERC20 _token, address _to, uint256 _amount) internal {
        uint256 allowance = _token.allowance(address(this), _to);
        if (allowance < _amount) {
            try _token.approve(_to, ~uint256(0)) {} catch {
                _token.approve(_to, 0);
                _token.approve(_to, ~uint256(0));
            }
        }
    }

    function _swapUniswapV2(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _callee,
        bytes calldata _data
    ) internal {
        (address[] memory path, address to) = abi.decode(
            _data,
            (address[], address)
        );
        IV2SwapRouter(_callee).swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            to,
            ~uint256(0)
        );
    }

    function _swapUniswapV3(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _callee,
        bytes calldata _data
    ) internal {
        (bytes memory path, address recipient) = abi.decode(
            _data,
            (bytes, address)
        );
        IV3SwapRouter(_callee).exactInput(
            IV3SwapRouter.ExactInputParams({
                path: path,
                recipient: recipient,
                amountIn: _amountIn,
                amountOutMinimum: _amountOutMin
            })
        );
    }
}