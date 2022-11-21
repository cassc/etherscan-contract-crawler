// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IBeneficiaryBase.sol";

abstract contract SwapTokenBase is AccessControl {
    using SafeERC20 for IERC20;
    bytes32 public constant DEVELOPER = keccak256("DEVELOPER");
    bytes32 public constant ADMIN = keccak256("ADMIN");
    address internal constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    address internal immutable WETH;
    address public immutable wallet;
    uint256 public immutable fee;

    modifier validate(address[] memory path) {
        require(path.length >= 2, "INVALID_PATH");
        _;
    }

    constructor(uint256 _fee, address _addr) {
        WETH = UNISWAP_V2_ROUTER().WETH();
        fee = _fee;
        wallet = _addr;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
        _grantRole(DEVELOPER, msg.sender);
    }

    function VOLT() public pure virtual returns (address) {
        return 0x7db5af2B9624e1b3B4Bb69D6DeBd9aD1016A58Ac;
    }

    function UNISWAP_V2_ROUTER() internal pure virtual returns (IUniswapV2Router02);

    function UNISWAP_FACTORY() internal pure virtual returns (IUniswapV2Factory);

    function burn(uint256 _feeAmount, address[] memory _path) internal {
        address tokenIn = _path[0];
        address tokenOut = _path[_path.length - 1];
        bool whitelistIn = tokenIn == WETH ? true : IBeneficiaryBase(wallet).tokenWhitelist(tokenIn);
        bool whitelistOut = tokenOut == WETH ? true : IBeneficiaryBase(wallet).tokenWhitelist(tokenOut);
        if (whitelistIn && whitelistOut) {
            if (tokenIn == WETH) {
                _safeTransfer(wallet, _feeAmount);
            } else {
                address[] memory wethPath = _getWETHPath(_path);
                if (wethPath.length >= 2) {
                    // buy ETH and send to beneficiary to buy-back and burn 0.5% VOLT
                    UNISWAP_V2_ROUTER().swapExactTokensForETHSupportingFeeOnTransferTokens(
                        _feeAmount,
                        0,
                        wethPath,
                        wallet,
                        block.timestamp
                    );
                } else {
                    IERC20(tokenIn).safeTransfer(wallet, _feeAmount);
                }
            }
        } else if (whitelistOut) {
            if (tokenIn == VOLT()) {
                IERC20(tokenIn).safeTransfer(deadAddress, _feeAmount);
            } else {
                uint256 _firstFeeAmount = _feeAmount / 2;
                // burn 0.25% of input token
                IERC20(tokenIn).safeTransfer(deadAddress, _firstFeeAmount);
                uint256 _secondFeeAmount = _feeAmount - _firstFeeAmount;
                address[] memory wethPath = _getWETHPath(_path);
                if (wethPath.length >= 2) {
                    // buy ETH and send to beneficiary to buy-back and burn 0.25% VOLT
                    UNISWAP_V2_ROUTER().swapExactTokensForETHSupportingFeeOnTransferTokens(
                        _secondFeeAmount,
                        0,
                        wethPath,
                        wallet,
                        block.timestamp
                    );
                } else {
                    IERC20(tokenIn).safeTransfer(wallet, _secondFeeAmount);
                }
            }
        } else {
            uint256 _firstFeeAmount = _feeAmount / 2;
            uint256 _secondFeeAmount = _feeAmount - _firstFeeAmount;

            // buy 0.25% of output token and burn
            if (tokenIn == WETH) {
                UNISWAP_V2_ROUTER().swapExactETHForTokensSupportingFeeOnTransferTokens{value: _firstFeeAmount}(
                    0,
                    _path,
                    deadAddress,
                    block.timestamp
                );
                _safeTransfer(wallet, _secondFeeAmount);
            } else {
                UNISWAP_V2_ROUTER().swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    _firstFeeAmount,
                    0,
                    _path,
                    deadAddress,
                    block.timestamp
                );
                address[] memory wethPath = _getWETHPath(_path);
                if (wethPath.length >= 2) {
                    // buy ETH and send to beneficiary to buy-back and burn 0.25% VOLT
                    UNISWAP_V2_ROUTER().swapExactTokensForETHSupportingFeeOnTransferTokens(
                        _secondFeeAmount,
                        0,
                        wethPath,
                        wallet,
                        block.timestamp
                    );
                } else {
                    IERC20(tokenIn).safeTransfer(wallet, _secondFeeAmount);
                }
            }
        }
    }

    function swapTokenForToken(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path
    ) public validate(_path) {
        address tokenIn = _path[0];

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
        uint256 _realAmountIn = IERC20(tokenIn).balanceOf(address(this)); // handle fee on transfer tokens

        _approve(tokenIn, _realAmountIn);

        uint256 feeAmount = (_realAmountIn * fee) / 10000;
        uint256 amountInSub = _realAmountIn - feeAmount;
        UNISWAP_V2_ROUTER().swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountInSub,
            _amountOutMin,
            _path,
            msg.sender,
            block.timestamp
        );
        burn(feeAmount, _path);
    }

    function swapTokenForExactToken(
        uint256 _amountOut,
        uint256 _amountInMax,
        address[] memory _path
    ) public validate(_path) {
        address tokenIn = _path[0];

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), _amountInMax);
        uint256 adjustedAmountIn = IERC20(tokenIn).balanceOf(address(this)); // handle fee on transfer tokens
        _approve(tokenIn, adjustedAmountIn);
        uint256 adjustedFee = (adjustedAmountIn * fee) / 10000;
        uint256[] memory amounts = UNISWAP_V2_ROUTER().swapTokensForExactTokens(
            _amountOut,
            adjustedAmountIn - adjustedFee,
            _path,
            msg.sender,
            block.timestamp
        );

        uint256 realAmountIn = amounts[0];
        uint256 feeAmount = (realAmountIn * fee) / 10000;
        uint256 refundAmount = adjustedAmountIn - realAmountIn - feeAmount;
        if (refundAmount > 0) {
            IERC20(tokenIn).safeTransfer(msg.sender, refundAmount);
        }
        burn(feeAmount, _path);
    }

    function swapTokenForETH(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path
    ) public validate(_path) {
        address tokenIn = _path[0];

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
        uint256 adjustedAmountIn = IERC20(tokenIn).balanceOf(address(this)); // handle fee on transfer tokens

        if (tokenIn == WETH) {
            IWETH(WETH).withdraw(adjustedAmountIn);
            _safeTransfer(msg.sender, adjustedAmountIn);
        } else {
            _approve(tokenIn, adjustedAmountIn);
            uint256 feeAmount = (adjustedAmountIn * fee) / 10000;
            uint256 amountInSub = adjustedAmountIn - feeAmount;
            UNISWAP_V2_ROUTER().swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountInSub,
                _amountOutMin,
                _path,
                msg.sender,
                block.timestamp
            );
            burn(feeAmount, _path);
        }
    }

    function swapTokenForExactETH(
        uint256 _amountOut,
        uint256 _amountInMax,
        address[] memory _path
    ) public validate(_path) {
        address tokenIn = _path[0];
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), _amountInMax);
        uint256 adjustedAmountIn = IERC20(tokenIn).balanceOf(address(this)); // handle fee on transfer tokens

        if (tokenIn == WETH) {
            IWETH(WETH).withdraw(adjustedAmountIn);
            _safeTransfer(msg.sender, adjustedAmountIn);
        } else {
            _approve(tokenIn, adjustedAmountIn);
            uint256 adjustedFee = (adjustedAmountIn * fee) / 10000;
            uint256[] memory amounts = UNISWAP_V2_ROUTER().swapTokensForExactETH(
                _amountOut,
                adjustedAmountIn - adjustedFee,
                _path,
                msg.sender,
                block.timestamp
            );
            uint256 realAmountIn = amounts[0];
            uint256 feeAmount = (realAmountIn * fee) / 10000;
            uint256 refundAmount = adjustedAmountIn - realAmountIn - feeAmount;
            if (refundAmount > 0) {
                IERC20(tokenIn).safeTransfer(msg.sender, refundAmount);
            }
            burn(feeAmount, _path);
        }
    }

    function swapETHForToken(uint256 _amountOutMin, address[] memory _path) public payable validate(_path) {
        address tokenOut = _path[_path.length - 1];
        uint256 amountIn = msg.value;

        if (tokenOut == WETH) {
            IWETH(WETH).deposit{value: amountIn}();
            IERC20(WETH).safeTransfer(msg.sender, amountIn);
        } else {
            uint256 feeAmount = (amountIn * fee) / 10000;
            uint256 amountInSub = amountIn - feeAmount;
            UNISWAP_V2_ROUTER().swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountInSub}(
                _amountOutMin,
                _path,
                msg.sender,
                block.timestamp
            );
            burn(feeAmount, _path);
        }
    }

    function swapETHforExactToken(uint256 _amountOut, address[] memory _path) public payable validate(_path) {
        address tokenOut = _path[_path.length - 1];
        uint256 amountIn = msg.value;

        if (tokenOut == WETH) {
            IWETH(WETH).deposit{value: amountIn}();
            IERC20(WETH).safeTransfer(msg.sender, amountIn);
        } else {
            uint256 feeAmount = (amountIn * fee) / 10000;
            uint256 amountInSub = amountIn - feeAmount;
            uint256[] memory amounts = UNISWAP_V2_ROUTER().swapETHForExactTokens{value: amountInSub}(
                _amountOut,
                _path,
                msg.sender,
                block.timestamp
            );
            uint256 refund = amountInSub - amounts[0];
            if (refund > 0) {
                _safeTransfer(msg.sender, refund);
            }
            burn(feeAmount, _path);
        }
    }

    function getPair(address _tokenIn, address _tokenOut) external view returns (address) {
        return UNISWAP_FACTORY().getPair(_tokenIn, _tokenOut);
    }

    function getAmountIn(uint256 _amountOut, address[] memory _path) public view returns (uint256) {
        uint256[] memory amountsIn = UNISWAP_V2_ROUTER().getAmountsIn(_amountOut, _path);
        return amountsIn[0];
    }

    function getAmountOutMinWithFees(uint256 _amountIn, address[] memory _path) public view returns (uint256) {
        uint256 feeAmount = (_amountIn * fee) / 10000;
        uint256 amountInSub = _amountIn - feeAmount;

        uint256[] memory amountOutMins = UNISWAP_V2_ROUTER().getAmountsOut(amountInSub, _path);
        return amountOutMins[amountOutMins.length - 1];
    }

    function _getWETHPath(address[] memory _path) internal view returns (address[] memory wethPath) {
        uint256 index = 0;
        for (uint256 i = 0; i < _path.length; i++) {
            if (_path[i] == WETH) {
                index = i + 1;
                break;
            }
        }
        wethPath = new address[](index);
        for (uint256 i = 0; i < index; i++) {
            wethPath[i] = _path[i];
        }
    }

    function _safeTransfer(address _to, uint256 _amount) internal {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function getTokenDecimals(address _addr) public view returns (uint8) {
        return IERC20Metadata(_addr).decimals();
    }

    /// @dev USDTs token implementation does not conform to the ERC20 standard
    /// first of all it requires an allowance to be set to zero before it can be set to a new value, therefore we set the allowance to zero here first
    /// secondly the return type does not conform to the ERC20 standard, therefore we ignore the return value
    function _approve(address token, uint256 amount) internal {
        (bool success, ) = token.call(
            abi.encodeWithSignature("approve(address,uint256)", address(UNISWAP_V2_ROUTER()), 0)
        );
        require(success, "Approval to zero failed");
        (success, ) = token.call(
            abi.encodeWithSignature("approve(address,uint256)", address(UNISWAP_V2_ROUTER()), amount)
        );
        require(success, "Approval failed");
    }

    receive() external payable {}
}