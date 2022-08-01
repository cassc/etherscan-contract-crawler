// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "./interfaces/IExchangeAdapter.sol";
import "../dependencies/interfaces/IUniswapV2Router02.sol";
import "../dependencies/token/IWETH.sol";

contract UniswapV2Exchange is OwnableUpgradeable, IExchangeAdapter {
    using SafeMathUpgradeable for uint256;

    IUniswapV2Router02 public uniswapRouter;
    address public wethToken;

    function __UniswapV2Exchange_init(address _router, address _wethAddress)
        external
        initializer
    {
        __Ownable_init();
        uniswapRouter = IUniswapV2Router02(_router);
        wethToken = _wethAddress;
    }

    function swapExactInputSingle(
        address _tokenIn,
        address _tokenOut,
        address _recipient,
        uint256 _amountIn,
        uint256 _amountOutMinimum,
        uint24 _poolFee
    ) external payable override returns (uint256) {
        _transferAndApprove(_tokenIn, _amountIn);

        address[] memory _pairs = new address[](2);
        _pairs[0] = _tokenIn;
        _pairs[1] = _tokenOut;
        return
            uniswapRouter.swapExactTokensForTokens(
                _amountIn,
                _amountOutMinimum,
                _pairs,
                _recipient,
                block.timestamp
            )[_pairs.length.sub(1)];
    }

    function swapExactInput(
        address _tokenIn,
        address[] memory _viaPath,
        address _tokenOut,
        address _recipient,
        uint256 _amountIn,
        uint256 _amountOutMinimum,
        uint24[] memory _poolFees
    ) external payable override returns (uint256) {
        _transferAndApprove(_tokenIn, _amountIn);
        address[] memory _pairs = _defineSwapPath(
            _tokenIn,
            _viaPath,
            _tokenOut
        );
        return
            uniswapRouter.swapExactTokensForTokens(
                _amountIn,
                _amountOutMinimum,
                _pairs,
                _recipient,
                block.timestamp
            )[_pairs.length.sub(1)];
    }

    function exactOutputSingle(
        address _tokenIn,
        address _tokenOut,
        address _recipient,
        uint256 _amountOut,
        uint256 _amountInMaximum,
        uint24 _poolFee
    ) external payable override returns (uint256 _amountIn) {
        _transferAndApprove(_tokenIn, _amountInMaximum);

        address[] memory _pairs = new address[](2);
        _pairs[0] = _tokenIn;
        _pairs[1] = _tokenOut;
        _amountIn = uniswapRouter.swapTokensForExactTokens(
            _amountOut,
            _amountInMaximum,
            _pairs,
            _recipient,
            block.timestamp
        )[_pairs.length.sub(1)];

        if (_amountIn < _amountInMaximum) {
            SafeERC20Upgradeable.safeApprove(
                IERC20Upgradeable(_tokenIn),
                address(uniswapRouter),
                0
            );
            SafeERC20Upgradeable.safeTransfer(
                IERC20Upgradeable(_tokenIn),
                _msgSender(),
                _amountInMaximum - _amountIn
            );
        }
        if (IERC20Upgradeable(_tokenIn).balanceOf(address(this)) > 0) {
            IERC20Upgradeable(_tokenIn).transfer(_msgSender(), IERC20Upgradeable(_tokenIn).balanceOf(address(this)));
        }
    }

    function exactOutput(
        address _tokenIn,
        address[] memory _viaPath,
        address _tokenOut,
        address _recipient,
        uint256 _amountOut,
        uint256 _amountInMaximum,
        uint24[] memory _poolFees
    ) external payable override returns (uint256 _amountIn) {
        _transferAndApprove(_tokenIn, _amountInMaximum);

        address[] memory _pairs = _defineSwapPath(
            _tokenIn,
            _viaPath,
            _tokenOut
        );

        _amountIn = uniswapRouter.swapTokensForExactTokens(
            _amountOut,
            _amountInMaximum,
            _pairs,
            _recipient,
            block.timestamp
        )[_pairs.length.sub(1)];

        if (_amountIn < _amountInMaximum) {
            SafeERC20Upgradeable.safeApprove(
                IERC20Upgradeable(_tokenIn),
                address(uniswapRouter),
                0
            );

            SafeERC20Upgradeable.safeTransfer(
                IERC20Upgradeable(_tokenIn),
                _msgSender(),
                IERC20Upgradeable(_tokenIn).balanceOf(address(this))
            );
        }
        if (IERC20Upgradeable(_tokenIn).balanceOf(address(this)) > 0) {
            IERC20Upgradeable(_tokenIn).transfer(_msgSender(), IERC20Upgradeable(_tokenIn).balanceOf(address(this)));
        }
    }

    function _defineSwapPath(
        address _tokenIn,
        address[] memory _viaPath,
        address _tokenOut
    ) internal returns (address[] memory _pairs) {
        _pairs = new address[](_viaPath.length + 2);
        if (_viaPath.length == 1) {
            _pairs[0] = _tokenIn;
            _pairs[1] = _viaPath[0];
            _pairs[2] = _tokenOut;
        } else if (_viaPath.length == 2) {
            _pairs[0] = _tokenIn;
            _pairs[1] = _viaPath[0];
            _pairs[2] = _viaPath[1];
            _pairs[3] = _tokenOut;
        }
        if (_viaPath.length == 3) {
            _pairs[0] = _tokenIn;
            _pairs[1] = _viaPath[0];
            _pairs[2] = _viaPath[1];
            _pairs[3] = _viaPath[2];
            _pairs[4] = _tokenOut;
        }
    }

    function _transferAndApprove(address _tokenIn, uint256 _amount) internal {
        if (_tokenIn == address(wethToken)) {
            IWETH(wethToken).transferFrom(_msgSender(), address(this), _amount);
            IWETH(wethToken).approve(address(uniswapRouter), _amount);
        } else {
            SafeERC20Upgradeable.safeTransferFrom(
                IERC20Upgradeable(_tokenIn),
                _msgSender(),
                address(this),
                _amount
            );
            SafeERC20Upgradeable.safeApprove(
                IERC20Upgradeable(_tokenIn),
                address(uniswapRouter),
                _amount
            ); // max amount to spend
        }
    }
}