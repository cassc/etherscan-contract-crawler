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

    struct limitOrder {
        address _from;
        address _tokenIn;
        uint256 _amountIn;
        address _tokenOut;
        uint256 _amountOut;
        uint256 _expires;
    }

    limitOrder[] public limitOrders;
    event limitOrderCreated(
        address _from,
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _amountOut,
        uint256 _arrayIndex,
        uint256 _expires
    );

    event limitOrderExecuted(uint256 _orderIndex);
    event limitOrderExpired(uint256 _orderIndex);

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
        if (tokenIn == WETH) {
            _safeTransfer(wallet, _feeAmount);
        } else if (tokenOut == WETH) {
            if (tokenIn == VOLT()) {
                IERC20(tokenIn).safeTransfer(deadAddress, _feeAmount);
            } else {
                uint256 _firstFeeAmount = _feeAmount / 2;
                UNISWAP_V2_ROUTER().swapExactTokensForETHSupportingFeeOnTransferTokens(
                    _firstFeeAmount,
                    0,
                    _path,
                    wallet,
                    block.timestamp
                );

                uint256 _secondFeeAmount = _feeAmount - _firstFeeAmount;
                if (!IBeneficiaryBase(wallet).tokenWhitelist(tokenIn)) {
                    IERC20(tokenIn).safeTransfer(deadAddress, _secondFeeAmount);
                } else {
                    UNISWAP_V2_ROUTER().swapExactTokensForETHSupportingFeeOnTransferTokens(
                        _secondFeeAmount,
                        0,
                        _path,
                        wallet,
                        block.timestamp
                    );
                }
            }
        } else {
            if (tokenIn == VOLT()) {
                IERC20(tokenIn).safeTransfer(deadAddress, _feeAmount);
            } else {
                uint256 _firstFeeAmount = _feeAmount / 2;
                uint256 _secondFeeAmount = _feeAmount - _firstFeeAmount;

                address[] memory wethPath = _getWETHPath(_path);

                if (wethPath.length > 0) {
                    UNISWAP_V2_ROUTER().swapExactTokensForETHSupportingFeeOnTransferTokens(
                        _firstFeeAmount,
                        0,
                        wethPath,
                        wallet,
                        block.timestamp
                    );
                } else {
                    IERC20(tokenIn).safeTransfer(wallet, _firstFeeAmount);
                }
                bool whitelistIn = IBeneficiaryBase(wallet).tokenWhitelist(tokenIn);
                bool whitelistOut = IBeneficiaryBase(wallet).tokenWhitelist(tokenOut);
                if (!whitelistIn && whitelistOut) {
                    IERC20(tokenIn).safeTransfer(deadAddress, _secondFeeAmount);
                } else if (!whitelistOut) {
                    UNISWAP_V2_ROUTER().swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        _secondFeeAmount,
                        0,
                        _path,
                        deadAddress,
                        block.timestamp
                    );
                }
            }
        }
    }

    function swapTokenForToken(
        uint256 _amountIn,
        uint256 _amountOutMin,
        bool _isLimitOrder,
        address _dest,
        address[] memory _path
    ) public validate(_path) {
        address tokenIn = _path[0];
        uint256 _realAmountIn;
        if (_isLimitOrder) {
            _realAmountIn = _amountIn;
        } else {
            uint256 prev_balance_tokenIn = IERC20(tokenIn).balanceOf(address(this));
            IERC20(tokenIn).safeTransferFrom(_dest, address(this), _amountIn);
            uint256 curr_balance_tokenIn = IERC20(tokenIn).balanceOf(address(this));
            _realAmountIn = curr_balance_tokenIn - prev_balance_tokenIn; // handle fee on transfer tokens
        }
        IERC20(tokenIn).safeIncreaseAllowance(address(UNISWAP_V2_ROUTER()), _realAmountIn);

        uint256 feeAmount = (_realAmountIn * fee) / 10000;
        uint256 amountInSub = _realAmountIn - feeAmount;
        UNISWAP_V2_ROUTER().swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountInSub,
            _amountOutMin,
            _path,
            _dest,
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
        IERC20(tokenIn).safeIncreaseAllowance(address(UNISWAP_V2_ROUTER()), adjustedAmountIn);
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
        bool _isLimitOrder,
        address _dest,
        address[] memory _path
    ) public validate(_path) {
        address tokenIn = _path[0];
        uint256 adjustedAmountIn;
        if (_isLimitOrder) {
            adjustedAmountIn = _amountIn;
        } else {
            uint256 prev_balance_tokenIn = IERC20(tokenIn).balanceOf(address(this));
            IERC20(tokenIn).safeTransferFrom(_dest, address(this), _amountIn);
            uint256 curr_balance_tokenIn = IERC20(tokenIn).balanceOf(address(this));
            adjustedAmountIn = curr_balance_tokenIn - prev_balance_tokenIn; // handle fee on transfer tokens
        }

        if (tokenIn == WETH) {
            IWETH(WETH).withdraw(adjustedAmountIn);
            _safeTransfer(_dest, adjustedAmountIn);
        } else {
            IERC20(tokenIn).safeIncreaseAllowance(address(UNISWAP_V2_ROUTER()), adjustedAmountIn);
            uint256 feeAmount = (adjustedAmountIn * fee) / 10000;
            uint256 amountInSub = adjustedAmountIn - feeAmount;
            UNISWAP_V2_ROUTER().swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountInSub,
                _amountOutMin,
                _path,
                _dest,
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
        IERC20(tokenIn).safeIncreaseAllowance(address(UNISWAP_V2_ROUTER()), adjustedAmountIn);

        if (tokenIn == WETH) {
            IWETH(WETH).withdraw(adjustedAmountIn);
            _safeTransfer(msg.sender, adjustedAmountIn);
        } else {
            IERC20(tokenIn).safeIncreaseAllowance(address(UNISWAP_V2_ROUTER()), adjustedAmountIn);
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

    function swapETHforToken(
        uint256 _amountOutMin,
        address _dest,
        address[] memory _path
    ) public payable validate(_path) {
        address tokenOut = _path[_path.length - 1];
        uint256 amountIn = msg.value;

        if (tokenOut == WETH) {
            IWETH(WETH).deposit{value: amountIn}();
            IERC20(WETH).transfer(_dest, amountIn);
        } else {
            uint256 feeAmount = (amountIn * fee) / 10000;
            uint256 amountInSub = amountIn - feeAmount;
            UNISWAP_V2_ROUTER().swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountInSub}(
                _amountOutMin,
                _path,
                _dest,
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
            IERC20(WETH).transfer(msg.sender, amountIn);
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

    /*
     *   start limit order functions
     */

    // requires that msg.sender approves this contract to move his tokens
    // amountIn and amountOut may be reduced if token has fees on transfer
    function sendLimitOrder(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOut,
        uint256 expires
    ) external payable {
        require(expires > block.timestamp, "expires");
        limitOrder memory order;
        if (msg.value > 0) {
            order = limitOrder(msg.sender, address(0), msg.value, tokenOut, amountOut, expires);
            limitOrders.push(order);
            emit limitOrderCreated(
                msg.sender,
                address(0),
                msg.value,
                tokenOut,
                amountOut,
                limitOrders.length > 0 ? limitOrders.length - 1 : 0,
                expires
            );
        } else {
            uint256 prev_balance = IERC20(tokenIn).balanceOf(address(this));

            IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
            uint256 curr_balance = IERC20(tokenIn).balanceOf(address(this));
            order = limitOrder(
                msg.sender,
                tokenIn,
                curr_balance - prev_balance, // I do this to take into consideration fees on transfers
                // which can make the amountIn less than the real amount exchanged
                tokenOut,
                amountOut,
                expires
            );
            limitOrders.push(order);
            emit limitOrderCreated(
                msg.sender,
                tokenIn,
                curr_balance - prev_balance,
                tokenOut,
                amountOut,
                limitOrders.length > 0 ? limitOrders.length - 1 : 0,
                expires
            );
        }
    }

    function isExecutableLimitOrder(uint256 orderIndex, address[] memory _path) public view returns (bool) {
        limitOrder memory order = limitOrders[orderIndex];
        uint256 amountOutMin = getAmountOutMinWithFees(
            order._amountIn,
            // order._tokenIn == address(0) ? UNISWAP_V2_ROUTER().WETH() : order._tokenIn,
            // order._tokenOut == address(0) ? UNISWAP_V2_ROUTER().WETH() : order._tokenOut
            _path
        );
        return amountOutMin >= order._amountOut;
    }

    function executeLimitOrder(uint256 _orderIndex, address[] memory _path) public {
        limitOrder memory order = limitOrders[_orderIndex];
        uint256 amountOutMin = getAmountOutMinWithFees(
            order._amountIn,
            // order._tokenIn == address(0) ? UNISWAP_V2_ROUTER().WETH() : order._tokenIn,
            // order._tokenOut == address(0) ? UNISWAP_V2_ROUTER().WETH() : order._tokenOut
            _path
        );
        if (amountOutMin >= order._amountOut && order._expires >= block.timestamp) {
            if (order._tokenIn == address(0)) {
                this.swapETHforToken{value: order._amountIn}(order._amountOut, order._from, _path);
            } else if (order._tokenOut == address(0)) {
                this.swapTokenForETH(order._amountIn, order._amountOut, true, order._from, _path);
            } else {
                this.swapTokenForToken(order._amountIn, order._amountOut, true, order._from, _path);
            }

            limitOrders[_orderIndex] = limitOrders[limitOrders.length - 1];
            limitOrders.pop();

            emit limitOrderExecuted(_orderIndex);
        } else if (order._expires < block.timestamp) {
            limitOrders[_orderIndex] = limitOrders[limitOrders.length - 1];
            limitOrders.pop();
            emit limitOrderExpired(_orderIndex);
        }
    }

    function getLimitOrdersCount() public view returns (uint256) {
        return limitOrders.length;
    }

    /*
     *   end limit order functions
     */

    function getTokenDecimals(address _addr) public view returns (uint8) {
        return IERC20Metadata(_addr).decimals();
    }

    receive() external payable {}
}