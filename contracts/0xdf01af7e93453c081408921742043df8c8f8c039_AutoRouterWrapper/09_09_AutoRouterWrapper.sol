//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.8.13;

import {ISwapWrapper} from "../interfaces/ISwapWrapper.sol";
import {ISwapRouter} from "../lib/ISwapRouter02.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {IWETH9} from "../lib/IWETH9.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import "../lib/uniswap/Path.sol";

contract AutoRouterWrapper is ISwapWrapper {
    using SafeTransferLib for ERC20;
    using BytesLib for bytes;

    /// @notice A deployed SwapRouter02(1.1.0). See https://docs.uniswap.org/protocol/reference/deployments.
    ISwapRouter public immutable swapRouter;

    /// @notice WETH contract.
    IWETH9 public immutable weth;

    /// @notice SwapWrapper name.
    string public name;

    /// @dev Address we use to represent ETH.
    address internal constant eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    error TxFailed();
    error OnlyMulticallsAllowed();
    error PathMismatch();
    error UnhandledFunction(bytes4 selector);
    error ETHAmountInMismatch();
    error TotalAmountMismatch();
    error RecipientMismatch(bytes4 selector);
    error TokenInMismatch(bytes4 selector);
    error TokenOutMismatch(bytes4 selector);

    /**
     * @param _name SwapWrapper name.
     * @param _uniV3SwapRouter Deployed Uniswap v3 SwapRouter.
     */
    constructor(string memory _name, address _uniV3SwapRouter) {
        name = _name;
        swapRouter = ISwapRouter(_uniV3SwapRouter);
        weth = IWETH9(swapRouter.WETH9());
    }

    function swap(address _tokenIn, address _tokenOut, address _recipient, uint256 _amount, bytes calldata _data)
        external
        payable
        returns (uint256)
    {
        // If token is ETH and value was sent, ensure the value matches the swap input amount.
        bool _isInputEth = _tokenIn == eth;
        if ((_isInputEth && msg.value != _amount) || (!_isInputEth && msg.value > 0)) {
            revert ETHAmountInMismatch();
        }
        uint256 _prevBalance = getBalance(_tokenOut, _recipient);

        if (!_isInputEth) {
            // If caller isn't sending ETH, we need to transfer in tokens...
            ERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amount);
            ERC20(_tokenIn).safeApprove(address(swapRouter), 0);
            ERC20(_tokenIn).safeApprove(address(swapRouter), _amount);
        }

        uint256 _totalAmountIn = _validateData(_tokenIn, _tokenOut, _recipient, _data);
        // _totalAmountIn has been modified by the various `check...()` methods, and should now sum to _amount
        if (_totalAmountIn != _amount) revert TotalAmountMismatch();

        (bool _success,) = address(swapRouter).call{value: _isInputEth ? _amount : 0}(_data);
        if (!_success) revert TxFailed();

        uint256 _amountOut = getBalance(_tokenOut, _recipient) - _prevBalance;
        emit WrapperSwapExecuted(_tokenIn, _tokenOut, msg.sender, _recipient, _totalAmountIn, _amountOut);
        return _amountOut;
    }

    function _validateData(address _tokenIn, address _tokenOut, address _recipient, bytes calldata _data)
        internal
        view
        returns (uint256 _totalAmountIn)
    {
        bytes4 _selector = bytes4(_data[:4]);
        // Check that it's the multicall function that's being called.
        if (_selector != ISwapRouter.multicall.selector) revert OnlyMulticallsAllowed();

        ( /*uint256 deadline*/ , bytes[] memory _calls) = abi.decode(_data[4:], (uint256, bytes[]));

        uint256 _callsLength = _calls.length;
        for (uint256 i = 0; i < _callsLength; i++) {
            bytes memory _call = _calls[i];
            // Get the selector
            _selector = bytes4(_call.slice(0, 4));
            // Remove the selector
            bytes memory _callWithoutSelector = _call.slice(4, _call.length - 4);

            // check TokenIn if it's the first call of a multicall
            bool _checkTokenIn = i == 0;
            // check TokenOut if it's the last call of a multicall
            bool _checkTokenOut = i == _callsLength - 1;

            // Check that selector is an approved selector and validate its arguments.
            if (_selector == ISwapRouter.exactInputSingle.selector) {
                _totalAmountIn += checkExactInputSingle(
                    _callWithoutSelector, _tokenIn, _tokenOut, _recipient, _checkTokenIn, _checkTokenOut
                );
            } else if (_selector == ISwapRouter.exactInput.selector) {
                _totalAmountIn += checkExactInput(
                    _callWithoutSelector, _tokenIn, _tokenOut, _recipient, _checkTokenIn, _checkTokenOut
                );
            } else if (_selector == ISwapRouter.sweepToken.selector) {
                checkSweepToken(_callWithoutSelector, _tokenOut, _recipient);
            } else if (_selector == ISwapRouter.swapExactTokensForTokens.selector) {
                _totalAmountIn += checkSwapExactTokensForTokens(
                    _callWithoutSelector, _tokenIn, _tokenOut, _recipient, _checkTokenIn, _checkTokenOut
                );
            } else if (_selector == ISwapRouter.unwrapWETH9.selector) {
                checkUnwrapWETH9(_callWithoutSelector, _recipient);
            } else {
                revert UnhandledFunction(_selector);
            }
        }
    }

    function checkExactInputSingle(
        bytes memory _data,
        address _tokenInExpected,
        address _tokenOutExpected,
        address _recipientExpected,
        bool _checkTokenIn,
        bool _checkTokenOut
    ) internal view returns (uint256) {
        (
            address _tokenIn,
            address _tokenOut,
            /*uint24 _fee*/
            ,
            address _recipient,
            uint256 _amountIn,
            /*uint256 _amountOutMinimum*/
            ,
            /*uint160 _sqrtPriceLimitX96*/
        ) = abi.decode(_data, (address, address, uint24, address, uint256, uint256, uint160));

        if (_checkTokenIn) {
            bool _tokensMatch = checkTokens(_tokenIn, _tokenInExpected);
            if (!_tokensMatch) revert TokenInMismatch(ISwapRouter.exactInputSingle.selector);
        }
        if (_checkTokenOut) {
            bool _tokensMatch = checkTokens(_tokenOut, _tokenOutExpected);
            if (!_tokensMatch) revert TokenOutMismatch(ISwapRouter.exactInputSingle.selector);
        }
        checkRecipient(_recipient, _recipientExpected, ISwapRouter.exactInputSingle.selector);

        return _amountIn;
    }

    function checkExactInput(
        bytes memory _data,
        address _tokenInExpected,
        address _tokenOutExpected,
        address _recipientExpected,
        bool _checkTokenIn,
        bool _checkTokenOut
    ) internal view returns (uint256) {
        (
            bytes memory _path,
            address _recipient,
            uint256 _amountIn,
            /*uint256 amountOutMinimum*/
            // First 32 bytes point to the location of dynamic bytes _path
        ) = abi.decode(_data.slice(32, _data.length - 32), (bytes, address, uint256, uint256));

        if (_checkTokenIn) {
            (address _tokenA, /*address _tokenB*/,) = Path.decodeFirstPool(_path);
            bool _tokensMatch = checkTokens(_tokenA, _tokenInExpected);
            if (!_tokensMatch) revert TokenInMismatch(ISwapRouter.exactInput.selector);
        }

        if (_checkTokenOut) {
            ( /*address _tokenA*/ , address _tokenB,) = Path.decodeLastPool(_path);
            bool _tokensMatch = checkTokens(_tokenB, _tokenOutExpected);
            if (!_tokensMatch) revert TokenOutMismatch(ISwapRouter.exactInput.selector);
        }
        checkRecipient(_recipient, _recipientExpected, ISwapRouter.exactInput.selector);

        return _amountIn;
    }

    function checkSweepToken(bytes memory _data, address _tokenOutExpected, address _recipientExpected) internal view {
        (address _token, /*uint256 _amountMinimum*/, address _recipient) =
            abi.decode(_data, (address, uint256, address));
        bool _tokensMatch = checkTokens(_token, _tokenOutExpected);
        if (!_tokensMatch) {
            revert TokenOutMismatch(ISwapRouter.sweepToken.selector);
        }
        checkRecipient(_recipient, _recipientExpected, ISwapRouter.sweepToken.selector);
    }

    function checkSwapExactTokensForTokens(
        bytes memory _data,
        address _tokenInExpected,
        address _tokenOutExpected,
        address _recipientExpected,
        bool _checkTokenIn,
        bool _checkTokenOut
    ) internal view returns (uint256) {
        (
            uint256 _amountIn,
            /*uint256 amountOutMin*/
            ,
            address[] memory _path,
            address _recipient
        ) = abi.decode(_data, (uint256, uint256, address[], address));

        if (_checkTokenIn) {
            bool _tokensMatch = checkTokens(_path[0], _tokenInExpected);
            if (!_tokensMatch) revert TokenInMismatch(ISwapRouter.swapExactTokensForTokens.selector);
        }
        if (_checkTokenOut) {
            bool _tokensMatch = checkTokens(_path[_path.length - 1], _tokenOutExpected);
            if (!_tokensMatch) revert TokenOutMismatch(ISwapRouter.swapExactTokensForTokens.selector);
        }
        checkRecipient(_recipient, _recipientExpected, ISwapRouter.swapExactTokensForTokens.selector);

        return _amountIn;
    }

    function checkUnwrapWETH9(bytes memory _data, address _recipientExpected) internal pure {
        ( /*uint256 amountOutMin*/ , address _recipient) = abi.decode(_data, (uint256, address));
        checkRecipient(_recipient, _recipientExpected, ISwapRouter.unwrapWETH9.selector);
    }

    function checkRecipient(address _recipient, address _recipientExpected, bytes4 _selector) internal pure {
        if (_selector == ISwapRouter.sweepToken.selector || _selector == ISwapRouter.unwrapWETH9.selector) {
            if (_recipient != _recipientExpected) revert RecipientMismatch(_selector);
        } else {
            // address(2) is a flag for identifying address(this).
            // See https://github.com/Uniswap/swap-router-contracts/blob/9dc4a9cce101be984e148e1af6fe605ebcfa658a/contracts/libraries/Constants.sol#L14
            if (_recipient != _recipientExpected && _recipient != address(2)) {
                revert RecipientMismatch(_selector);
            }
        }
    }

    function getBalance(address _tokenOut, address _recipient) internal view returns (uint256) {
        if (_tokenOut == address(eth)) {
            return address(_recipient).balance;
        } else {
            return ERC20(_tokenOut).balanceOf(address(_recipient));
        }
    }

    // Return true if two tokens match, OR if _tokenExpected is eth, token must be weth.
    function checkTokens(address _token, address _tokenExpected) internal view returns (bool) {
        // `TokenIn` should never == eth by the time this check is reached.
        return _token == _tokenExpected || (_tokenExpected == eth ? _token == address(weth) : false);
    }

    /// @notice Required to receive ETH on `weth.withdraw()`
    receive() external payable {}
}