// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import 'rubic-bridge-base/contracts/architecture/OnlySourceFunctionality.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import 'rubic-bridge-base/contracts/errors/Errors.sol';
import 'rubic-bridge-base/contracts/libraries/SmartApprove.sol';
import './interfaces/IAnyswapRouter.sol';
import './interfaces/IAnyswapToken.sol';
import 'rubic-whitelist-contract/contracts/interfaces/IRubicWhitelist.sol';

error DifferentAmountSpent();
error TooMuchValue();
error AnyRouterNotAvailable();
error DexNotAvailable();
error CannotBridgeToSameNetwork();
error LessOrEqualsMinAmount();
error IncorrectAnyNative();

contract MultichainProxy is OnlySourceFunctionality {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public immutable nativeWrap;
    IRubicWhitelist public whitelistRegistry;

    constructor(
        address _nativeWrap,
        uint256 _fixedCryptoFee,
        uint256 _rubicPlatformFee,
        IRubicWhitelist _whitelistRegistry,
        address[] memory _tokens,
        uint256[] memory _minTokenAmounts,
        uint256[] memory _maxTokenAmounts,
        address _admin
    ) {
        nativeWrap = _nativeWrap;
        whitelistRegistry = _whitelistRegistry;

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

    function multiBridge(BaseCrossChainParams memory _params)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        (address underlyingToken, ) = _getUnderlyingToken(_params.srcInputToken);

        (_params.srcInputAmount, ) = _receiveTokens(underlyingToken, _params.srcInputAmount);

        IntegratorFeeInfo memory _info = integratorToFeeInfo[_params.integrator];

        _params.srcInputAmount = accrueTokenFees(
            _params.integrator,
            _info,
            _params.srcInputAmount,
            0,
            underlyingToken
        );

        if (accrueFixedCryptoFee(_params.integrator, _info) != 0) {
            revert TooMuchValue();
        }

        _checkParamsBeforeBridge(
            _params.router,
            underlyingToken,
            _params.srcInputAmount,
            _params.dstChainID
        );

        _bridgeTokens(
            _params.srcInputToken,
            _params.router,
            _params.srcInputAmount,
            _params.recipient,
            _params.dstChainID,
            underlyingToken
        );

        // emit underlying token
        _params.srcInputToken = underlyingToken;
        emit RequestSent(_params, 'native:Multichain');
    }

    function multiBridgeNative(BaseCrossChainParams memory _params)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        (address underlyingToken, ) = _getUnderlyingToken(_params.srcInputToken);
        // check if we use correct any native to prevent calling Anyswap with incorrect token
        // if the any token is incorrect -> tokens won't arrive in dst chain
        if (underlyingToken != nativeWrap) {
            revert IncorrectAnyNative();
        }

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
            _params.router,
            underlyingToken,
            _params.srcInputAmount,
            _params.dstChainID
        );

        _bridgeNative(
            _params.srcInputToken,
            _params.router,
            _params.srcInputAmount,
            _params.recipient,
            _params.dstChainID
        );

        _params.srcInputToken = address(0);
        emit RequestSent(_params, 'native:Multichain');
    }

    function multiBridgeSwap(
        address _dex,
        address _anyTokenOut,
        bytes calldata _swapData,
        BaseCrossChainParams memory _params
    ) external payable nonReentrant whenNotPaused {
        uint256 tokenInAfter;
        (_params.srcInputAmount, tokenInAfter) = _receiveTokens(
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

        IERC20Upgradeable(_params.srcInputToken).safeApprove(_dex, _params.srcInputAmount);

        (address underlyingToken, bool isNative) = _getUnderlyingToken(_anyTokenOut);

        uint256 amountOut = _performSwap(underlyingToken, _dex, _swapData, isNative, 0);

        _amountAndAllowanceChecks(
            _params.srcInputToken,
            _dex,
            _params.srcInputAmount,
            tokenInAfter
        );

        _checkParamsBeforeBridge(_params.router, underlyingToken, amountOut, _params.dstChainID);

        if (isNative) {
            _bridgeNative(
                _anyTokenOut,
                _params.router,
                amountOut,
                _params.recipient,
                _params.dstChainID
            );
        } else {
            _bridgeTokens(
                _anyTokenOut,
                _params.router,
                amountOut,
                _params.recipient,
                _params.dstChainID,
                underlyingToken
            );
        }

        emit RequestSent(_params, 'native:Multichain');
    }

    function multiBridgeSwapNative(
        address _dex,
        address _anyTokenOut,
        bytes calldata _swapData,
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

        (address underlyingToken, ) = _getUnderlyingToken(_anyTokenOut);

        uint256 amountOut = _performSwap(
            underlyingToken,
            _dex,
            _swapData,
            false,
            _params.srcInputAmount
        );

        _checkParamsBeforeBridge(_params.router, underlyingToken, amountOut, _params.dstChainID);

        _bridgeTokens(
            _anyTokenOut,
            _params.router,
            amountOut,
            _params.recipient,
            _params.dstChainID,
            underlyingToken
        );
        
        _params.srcInputToken = address(0);
        emit RequestSent(_params, 'native:Multichain');
    }

    function multiSwapOut(BaseCrossChainParams memory _params, string calldata _recipientNotEVM)
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

        _checkParamsBeforeSwapOut(_params.srcInputToken, _params.srcInputAmount);

        _swapOutTokens(
            _params.srcInputToken,
            _params.srcInputAmount,
            _params.recipient,
            _recipientNotEVM
        );

        // backend will take _recipientNotEVM from input params if dstChainId is not EVM
        emit RequestSent(_params, 'native:Multichain');
    }

    function multiSwapOutWithSwap(
        address _dex,
        address _anyTokenOut,
        bytes calldata _swapData,
        BaseCrossChainParams memory _params,
        string calldata _recipientNotEVM
    ) external payable nonReentrant whenNotPaused {
        uint256 tokenInAfter;
        (_params.srcInputAmount, tokenInAfter) = _receiveTokens(
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

        IERC20Upgradeable(_params.srcInputToken).safeApprove(_dex, _params.srcInputAmount);

        // always swap for any token
        uint256 amountOut = _performSwap(_anyTokenOut, _dex, _swapData, false, 0);

        _amountAndAllowanceChecks(
            _params.srcInputToken,
            _dex,
            _params.srcInputAmount,
            tokenInAfter
        );

        _checkParamsBeforeSwapOut(_anyTokenOut, amountOut);

        _swapOutTokens(_anyTokenOut, amountOut, _params.recipient, _recipientNotEVM);

        emit RequestSent(_params, 'native:Multichain');
    }

    function multiSwapOutWithSwapNative(
        address _dex,
        address _anyTokenOut,
        bytes calldata _swapData,
        BaseCrossChainParams memory _params,
        string calldata _recipientNotEVM
    ) external payable nonReentrant whenNotPaused {
        IntegratorFeeInfo memory _info = integratorToFeeInfo[_params.integrator];

        _params.srcInputAmount = accrueTokenFees(
            _params.integrator,
            _info,
            accrueFixedCryptoFee(_params.integrator, _info),
            0,
            address(0)
        );

        uint256 amountOut = _performSwap(
            _anyTokenOut,
            _dex,
            _swapData,
            false,
            _params.srcInputAmount
        );

        _checkParamsBeforeSwapOut(_anyTokenOut, amountOut);

        _swapOutTokens(_anyTokenOut, amountOut, _params.recipient, _recipientNotEVM);

        _params.srcInputToken = address(0);
        emit RequestSent(_params, 'native:Multichain');
    }

    function _checkParamsBeforeSwapOut(address _anyToken, uint256 _amount) private view {
        // initial min amount is 0
        // revert in case we received 0 tokens after swap or _receiveTokens
        if (_amount <= minTokenAmount[_anyToken]) {
            revert LessOrEqualsMinAmount();
        }
        // max amount for multichain is very big, no checks for that

        // Check if token is in WL is missing. Multichain has hundreds of any tokens, 
        // so it was decided to skip this check. There is no known contract with SwapOut selector,
        //  which will be able to steal rubic fees for now.
    }

    function _swapOutTokens(
        address _anyToken,
        uint256 _amount,
        address _recipientEVM,
        string calldata _recipientNotEVM
    ) private {
        if (bytes(_recipientNotEVM).length == 0) {
            IAnyswapToken(_anyToken).Swapout(_amount, _recipientEVM);
        } else {
            IAnyswapToken(_anyToken).Swapout(_amount, _recipientNotEVM);
        }
    }

    /// @dev It's safe to approve multichain on max amount, no need to check allowance there
    /// @dev For multichain calls we use on-chain received amount, different amount spent can not happen
    /// @notice Use this function only after external calls with bytes data
    /// @param _tokenIn token that we swapped on dex and approved
    /// @param _router the dex address
    /// @param _amountIn amount we received on the contract
    /// @param _tokenInAfter amount of _tokenIn after swap
    function _amountAndAllowanceChecks(
        address _tokenIn,
        address _router,
        uint256 _amountIn,
        uint256 _tokenInAfter
    ) internal {
        // check for UTXO
        if (_tokenInAfter - IERC20Upgradeable(_tokenIn).balanceOf(address(this)) != _amountIn) {
            revert DifferentAmountSpent();
        }

        // reset allowance back to zero, just in case
        if (IERC20Upgradeable(_tokenIn).allowance(address(this), _router) > 0) {
            IERC20Upgradeable(_tokenIn).safeApprove(_router, 0);
        }
    }

    function _performSwap(
        address _tokenOut,
        address _dex,
        bytes calldata _data,
        bool _isNativeOut,
        uint256 _value
    ) internal returns (uint256) {
        if (!whitelistRegistry.isWhitelistedDEX(_dex)) revert DexNotAvailable();

        uint256 balanceBeforeSwap = _isNativeOut
            ? address(this).balance
            : IERC20Upgradeable(_tokenOut).balanceOf(address(this));

        AddressUpgradeable.functionCallWithValue(_dex, _data, _value);

        return
            _isNativeOut
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

    /// @dev Contains the business logic for the token bridge via Anyswap
    /// @param _anyTokenIn any token
    /// @param _anyRouter Anyswap router
    /// @param _amount bridging amount
    /// @param _recipient receiver in destination chain
    /// @param _dstChain destination chain id
    /// @param _underlyingToken the underlying token of any token
    function _bridgeTokens(
        address _anyTokenIn,
        address _anyRouter,
        uint256 _amount,
        address _recipient,
        uint256 _dstChain,
        address _underlyingToken
    ) private {
        // Give Anyswap approval to bridge tokens
        SmartApprove.smartApprove(_underlyingToken, _amount, _anyRouter);
        // Was the token wrapping another token?
        if (_anyTokenIn != _underlyingToken) {
            IAnyswapRouter(_anyRouter).anySwapOutUnderlying(
                _anyTokenIn,
                _recipient,
                _amount,
                _dstChain
            );
        } else {
            IAnyswapRouter(_anyRouter).anySwapOut(_anyTokenIn, _recipient, _amount, _dstChain);
        }
    }

    /// @dev Contains the business logic for the native token bridge via Anyswap
    /// @param _anyTokenIn any token
    /// @param _anyRouter Anyswap router
    /// @param _amount bridging amount
    /// @param _recipient receiver in destination chain
    /// @param _dstChain destination chain id
    function _bridgeNative(
        address _anyTokenIn,
        address _anyRouter,
        uint256 _amount,
        address _recipient,
        uint256 _dstChain
    ) private {
        IAnyswapRouter(_anyRouter).anySwapOutNative{value: _amount}(
            _anyTokenIn,
            _recipient,
            _dstChain
        );
    }

    function _checkParamsBeforeBridge(
        address _anyRouter,
        address _transitToken,
        uint256 _amount,
        uint256 _dstChain
    ) private view {
        // initial min amount is 0
        // revert in case we received 0 tokens after swap
        if (_amount <= minTokenAmount[_transitToken]) {
            revert LessOrEqualsMinAmount();
        }

        if (!whitelistRegistry.isWhitelistedAnyRouter(_anyRouter)) revert AnyRouterNotAvailable();

        if (block.chainid == _dstChain) revert CannotBridgeToSameNetwork();
    }

    /// @dev Unwraps the underlying token from the Anyswap token if necessary
    /// @param token The (maybe) wrapped token
    function _getUnderlyingToken(address token)
        private
        returns (address underlyingToken, bool isNative)
    {
        // Token must implement IAnyswapToken interface
        if (token == address(0)) revert ZeroAddress();
        underlyingToken = IAnyswapToken(token).underlying();
        // The native token does not use the standard null address
        isNative = nativeWrap == underlyingToken;
        // Some Multichain complying tokens may wrap nothing
        if (underlyingToken == address(0)) {
            underlyingToken = token;
        }
    }

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