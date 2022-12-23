// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import 'rubic-bridge-base/contracts/architecture/OnlySourceFunctionality.sol';
import 'rubic-bridge-base/contracts/errors/Errors.sol';
import 'rubic-bridge-base/contracts/libraries/SmartApprove.sol';
import 'rubic-whitelist-contract/contracts/interfaces/IRubicWhitelist.sol';

import './interfaces/IcBridge.sol';

error DifferentAmountSpent();
error TooMuchValue();
error DexNotAvailable();
error CannotBridgeToSameNetwork();
error LessOrEqualsMinAmount();
error IncorrectAnyNative();

contract cBridgeProxy is OnlySourceFunctionality {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IcBridge public cBridge;
    IRubicWhitelist public whitelistRegistry;

    constructor(
        uint256 _fixedCryptoFee,
        uint256 _rubicPlatformFee,
        address[] memory _tokens,
        uint256[] memory _minTokenAmounts,
        uint256[] memory _maxTokenAmounts,
        address _admin,
        IRubicWhitelist _whitelistRegistry,
        IcBridge _cBridge
    ) {
        if (address(_whitelistRegistry) == address(0)) {
            revert ZeroAddress();
        }

        if (address(_cBridge) == address(0)) {
            revert ZeroAddress();
        }

        whitelistRegistry = _whitelistRegistry;
        cBridge = _cBridge;

        initialize(
            _fixedCryptoFee,
            _rubicPlatformFee,
            _tokens,
            _minTokenAmounts,
            _maxTokenAmounts,
            _admin
        );
    }

    function initialize(
        uint256 _fixedCryptoFee,
        uint256 _rubicPlatformFee,
        address[] memory _tokens,
        uint256[] memory _minTokenAmounts,
        uint256[] memory _maxTokenAmounts,
        address _admin
    ) private initializer {
        __OnlySourceFunctionalityInit(
            _fixedCryptoFee,
            _rubicPlatformFee,
            _tokens,
            _minTokenAmounts,
            _maxTokenAmounts,
            _admin
        );
    }

    function bridge(uint32 _maxSlippage, BaseCrossChainParams memory _params)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        (_params.srcInputAmount, ) = _receiveTokens(_params.srcInputToken, _params.srcInputAmount);

        IntegratorFeeInfo memory _info = integratorToFeeInfo[_params.integrator];

        _params.srcInputAmount = accrueTokenFees(
            _params.integrator,
            _info,
            _params.srcInputAmount,
            0,
            _params.srcInputToken
        );

        if (accrueFixedCryptoFee(_params.integrator, _info) != 0) {
            revert TooMuchValue();
        }

        _checkParamsBeforeBridge(
            _params.srcInputToken,
            _params.srcInputAmount,
            _params.dstChainID
        );

        _bridgeTokens(
            _params.srcInputToken,
            _params.srcInputAmount,
            _params.recipient,
            _params.dstChainID,
            _maxSlippage
        );

        emit RequestSent(_params, 'native:cBridge');
    }

    function bridgeNative(uint32 _maxSlippage, BaseCrossChainParams memory _params)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        IntegratorFeeInfo memory _info = integratorToFeeInfo[_params.integrator];

        // msg.value - fees
        _params.srcInputAmount = accrueTokenFees(
            _params.integrator,
            _info,
            accrueFixedCryptoFee(_params.integrator, _info),
            0,
            address(0)
        );

        _checkParamsBeforeBridge(
            address(0),
            _params.srcInputAmount,
            _params.dstChainID
        );

        _bridgeNative(
            _params.srcInputAmount,
            _params.recipient,
            _params.dstChainID,
            _maxSlippage
        );

        _params.srcInputToken = address(0);
        emit RequestSent(_params, 'native:cBridge');
    }

    function swapAndBridge(
        address _tokenOut,
        bytes calldata _swapData,
        uint32 _maxSlippage,
        BaseCrossChainParams memory _params
    ) external payable nonReentrant whenNotPaused {
        uint256 tokenInBeforeSwap;
        (_params.srcInputAmount, tokenInBeforeSwap) = _receiveTokens(
            _params.srcInputToken,
            _params.srcInputAmount
        );

        IntegratorFeeInfo memory _info = integratorToFeeInfo[_params.integrator];

        _params.srcInputAmount = accrueTokenFees(
            _params.integrator,
            _info,
            _params.srcInputAmount,
            0,
            _params.srcInputToken
        );

        if (accrueFixedCryptoFee(_params.integrator, _info) != 0) {
            revert TooMuchValue();
        }

        IERC20Upgradeable(_params.srcInputToken).safeApprove(_params.router, _params.srcInputAmount);

        uint256 amountOut = _performSwap(_tokenOut, _params.router, _swapData, 0);

        _amountAndAllowanceChecks(
            _params.srcInputToken,
            _params.router,
            _params.srcInputAmount,
            tokenInBeforeSwap
        );

        _checkParamsBeforeBridge(_tokenOut, amountOut, _params.dstChainID);

        if (_tokenOut == address(0)) {
            _bridgeNative(
                amountOut,
                _params.recipient,
                _params.dstChainID,
                _maxSlippage
            );
        } else {
            _bridgeTokens(
                _tokenOut,
                amountOut,
                _params.recipient,
                _params.dstChainID,
                _maxSlippage
            );
        }

        emit RequestSent(_params, 'native:cBridge');
    }

    function swapNativeAndBridge(
        address _tokenOut,
        bytes calldata _swapData,
        uint32 _maxSlippage,
        BaseCrossChainParams memory _params
    ) external payable nonReentrant whenNotPaused {
        IntegratorFeeInfo memory _info = integratorToFeeInfo[_params.integrator];

        _params.srcInputAmount = accrueTokenFees(
            _params.integrator,
            _info,
            accrueFixedCryptoFee(_params.integrator, _info),
            0,
            address(0)
        );

        uint256 amountOut = _performSwap(_tokenOut, _params.router, _swapData, _params.srcInputAmount);

        _checkParamsBeforeBridge(_tokenOut, amountOut, _params.dstChainID);

        if (_tokenOut == address(0)) {
            _bridgeNative(
                amountOut,
                _params.recipient,
                _params.dstChainID,
                _maxSlippage
            );
        } else {
            _bridgeTokens(
                _tokenOut,
                amountOut,
                _params.recipient,
                _params.dstChainID,
                _maxSlippage
            );
        }

        emit RequestSent(_params, 'native:cBridge');
    }

    function _checkParamsBeforeSwapOut(address _anyToken, uint256 _amount) private view {
        // initial min amount is 0
        // revert in case we received 0 tokens after swap or _receiveTokens
        if (_amount <= minTokenAmount[_anyToken]) {
            revert LessOrEqualsMinAmount();
        }
    }

    /// @dev Checks that dex spent the specified amount
    /// @dev Also erases the allowance to the dex if there is
    /// @param _tokenIn token that we swapped on dex and approved
    /// @param _router the dex address
    /// @param _amountIn amount that we should spend
    /// @param _tokenInBefore amount of token before swap
    function _amountAndAllowanceChecks(
        address _tokenIn,
        address _router,
        uint256 _amountIn,
        uint256 _tokenInBefore
    ) internal {
        // check for spent amount
        if (_tokenInBefore - IERC20Upgradeable(_tokenIn).balanceOf(address(this)) != _amountIn) {
            revert DifferentAmountSpent();
        }

        // reset allowance back to zero, just in case
        if (IERC20Upgradeable(_tokenIn).allowance(address(this), _router) > 0) {
            IERC20Upgradeable(_tokenIn).safeApprove(_router, 0);
        }
    }


    /*
     * @return Received amount after swap
     */
    function _performSwap(
        address _tokenOut,
        address _dex,
        bytes calldata _data,
        uint256 _value
    ) internal returns (uint256) {
        if (!whitelistRegistry.isWhitelistedDEX(_dex)) revert DexNotAvailable();

        bool isNativeOut = _tokenOut == address(0);

        uint256 balanceBeforeSwap = isNativeOut
            ? address(this).balance
            : IERC20Upgradeable(_tokenOut).balanceOf(address(this));

        AddressUpgradeable.functionCallWithValue(_dex, _data, _value);

        return
            isNativeOut
                ? address(this).balance - balanceBeforeSwap
                : IERC20Upgradeable(_tokenOut).balanceOf(address(this)) - balanceBeforeSwap;
    }

    function _receiveTokens(address _tokenIn, uint256 _amountIn)
        internal
        returns (uint256, uint256)
    {
        uint256 balanceBeforeTransfer = IERC20Upgradeable(_tokenIn).balanceOf(address(this));
        IERC20Upgradeable(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
        uint256 balanceAfterTransfer = IERC20Upgradeable(_tokenIn).balanceOf(address(this));
        _amountIn = balanceAfterTransfer - balanceBeforeTransfer;
        return (_amountIn, balanceAfterTransfer);
    }

    /// @dev Calls cBridge function for token bridge
    /// @param _tokenIn token address
    /// @param _amount bridging amount
    /// @param _recipient receiver in destination chain
    /// @param _dstChain destination chain id
    /// @param _maxSlippage Max slippage for celer bridge
    function _bridgeTokens(
        address _tokenIn,
        uint256 _amount,
        address _recipient,
        uint256 _dstChain,
        uint32 _maxSlippage
    ) private {
        IERC20Upgradeable(_tokenIn).safeApprove(address(cBridge), _amount);

        cBridge.send(
            _recipient,
            _tokenIn,
            _amount,
            uint64(_dstChain),
            uint64(block.timestamp),
            _maxSlippage
        );
    }

    /// @dev Calls cBridge function for native bridge
    /// @param _amount bridging amount
    /// @param _recipient receiver in destination chain
    /// @param _dstChain destination chain id
    /// @param _maxSlippage Max slippage for celer bridge
    function _bridgeNative(
        uint256 _amount,
        address _recipient,
        uint256 _dstChain,
        uint32 _maxSlippage
    ) private {
        cBridge.sendNative{value: _amount}(
            _recipient,
            _amount,
            uint64(_dstChain),
            uint64(block.timestamp),
            _maxSlippage
        );
    }

    function _checkParamsBeforeBridge(
        address _transitToken,
        uint256 _amount,
        uint256 _dstChain
    ) private view {
        // initial min amount is 0
        // revert in case we received 0 tokens after swap
        if (_amount <= minTokenAmount[_transitToken]) {
            revert LessOrEqualsMinAmount();
        }

        if (block.chainid == _dstChain) revert CannotBridgeToSameNetwork();
    }

    /// MANAGEMENT ///

    /**
     * @dev Sets the address of a new whitelist registry contract
     * @param _newWhitelistRegistry The address of the registry
     */
    function setWhitelistRegistry(IRubicWhitelist _newWhitelistRegistry) external onlyAdmin {
        if (address(_newWhitelistRegistry) == address(0)) {
            revert ZeroAddress();
        }

        whitelistRegistry = _newWhitelistRegistry;
    }
}