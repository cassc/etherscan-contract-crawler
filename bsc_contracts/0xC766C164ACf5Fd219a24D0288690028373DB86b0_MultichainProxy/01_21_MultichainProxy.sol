// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import 'rubic-bridge-base/contracts/architecture/OnlySourceFunctionality.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import 'rubic-bridge-base/contracts/errors/Errors.sol';
import './interfaces/IAnyswapRouter.sol';
import './interfaces/IAnyswapToken.sol';

error DifferentAmountSpent();
error RouterNotAvailable();
error CannotBridgeToSameNetwork();

contract MultichainProxy is OnlySourceFunctionality {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    constructor(
        uint256 _fixedCryptoFee,
        uint256 _rubicPlatformFee,
        address[] memory _routers,
        address[] memory _tokens,
        uint256[] memory _minTokenAmounts,
        uint256[] memory _maxTokenAmounts
    ) {
        initialize(_fixedCryptoFee, _rubicPlatformFee, _routers, _tokens, _minTokenAmounts, _maxTokenAmounts);
    }

    function initialize(
        uint256 _fixedCryptoFee,
        uint256 _rubicPlatformFee,
        address[] memory _routers,
        address[] memory _tokens,
        uint256[] memory _minTokenAmounts,
        uint256[] memory _maxTokenAmounts
    ) private initializer {
        __OnlySourceFunctionalityInit(
            _fixedCryptoFee,
            _rubicPlatformFee,
            _routers,
            _tokens,
            _minTokenAmounts,
            _maxTokenAmounts
        );
    }

    function multiBridge(BaseCrossChainParams memory _params) external payable nonReentrant whenNotPaused {
        (address underlyingToken, bool isNative) = _getUnderlyingToken(_params.srcInputToken, _params.router);

        uint256 tokenInAfter;
        (_params.srcInputAmount, tokenInAfter) = _checkAmountIn(underlyingToken, _params.srcInputAmount);

        IntegratorFeeInfo memory _info = integratorToFeeInfo[_params.integrator];

        _params.srcInputAmount = accrueTokenFees(_params.integrator, _info, _params.srcInputAmount, 0, underlyingToken);

        accrueFixedCryptoFee(_params.integrator, _info); // add require msg.value left == 0 ?

        _transferToMultichain(
            _params.srcInputToken,
            _params.router,
            _params.srcInputAmount,
            _params.recipient,
            _params.dstChainID,
            underlyingToken,
            isNative
        );

        _amountAndAllowanceChecks(underlyingToken, _params.router, _params.srcInputAmount, tokenInAfter);

        // emit underlying token token
        _params.srcInputToken = underlyingToken;
        emit RequestSent(_params, 'native:Multichain');
    }

    function multiBridgeNative(BaseCrossChainParams memory _params) external payable nonReentrant whenNotPaused {
        (address underlyingToken, bool isNative) = _getUnderlyingToken(_params.srcInputToken, _params.router);

        IntegratorFeeInfo memory _info = integratorToFeeInfo[_params.integrator];

        _params.srcInputAmount = accrueTokenFees(
            _params.integrator,
            _info,
            accrueFixedCryptoFee(_params.integrator, _info),
            0,
            address(0)
        );

        _transferToMultichain(
            _params.srcInputToken,
            _params.router,
            _params.srcInputAmount,
            _params.recipient,
            _params.dstChainID,
            underlyingToken,
            isNative
        );

        // emit underlying native token
        _params.srcInputToken = address(0);
        emit RequestSent(_params, 'native:Multichain');
    }

    function multiBridgeSwap(
        BaseCrossChainParams memory _params,
        address _dex,
        address _anyTokenOut,
        bytes calldata _swapData
    ) external payable nonReentrant whenNotPaused {
        uint256 tokenInAfter;
        (_params.srcInputAmount, tokenInAfter) = _checkAmountIn(_params.srcInputToken, _params.srcInputAmount);

        IntegratorFeeInfo memory _info = integratorToFeeInfo[_params.integrator];

        _params.srcInputAmount = accrueTokenFees(
            _params.integrator,
            _info,
            _params.srcInputAmount,
            0,
            _params.srcInputToken
        );

        IERC20Upgradeable(_params.srcInputToken).safeApprove(_dex, _params.srcInputAmount);

        (address underlyingToken, bool isNative) = _getUnderlyingToken(_anyTokenOut, _params.router);

        // todo what if native token received?
        uint256 tokenOutBefore = IERC20Upgradeable(underlyingToken).balanceOf(address(this)); 
        AddressUpgradeable.functionCallWithValue(_dex, _swapData, accrueFixedCryptoFee(_params.integrator, _info));
        uint256 amountOut = IERC20Upgradeable(underlyingToken).balanceOf(address(this)) - tokenOutBefore;

        _amountAndAllowanceChecks(_params.srcInputToken, _dex, _params.srcInputAmount, tokenInAfter);

        _transferToMultichain(
            _anyTokenOut,
            _params.router,
            amountOut,
            _params.recipient,
            _params.dstChainID,
            underlyingToken,
            isNative
        );

        // already know amount out
        // allowance check? Its safe to approve multichain for uintmax
        // _amountAndAllowanceChecks(...

        emit RequestSent(_params, 'native:Multichain');
    }

    function multiBridgeSwapNative(
        BaseCrossChainParams memory _params,
        address _dex,
        address _anyTokenOut,
        bytes calldata _swapData
    ) external payable nonReentrant whenNotPaused {
        IntegratorFeeInfo memory _info = integratorToFeeInfo[_params.integrator];

        _params.srcInputAmount = accrueTokenFees(
            _params.integrator,
            _info,
            accrueFixedCryptoFee(_params.integrator, _info),
            0,
            address(0)
        );

        (address underlyingToken, bool isNative) = _getUnderlyingToken(_anyTokenOut, _params.router);

        uint256 tokenOutBefore = IERC20Upgradeable(underlyingToken).balanceOf(address(this));
        AddressUpgradeable.functionCallWithValue(_dex, _swapData, _params.srcInputAmount);
        uint256 amountOut = IERC20Upgradeable(underlyingToken).balanceOf(address(this)) - tokenOutBefore;

        _transferToMultichain(
            _anyTokenOut,
            _params.router,
            amountOut,
            _params.recipient,
            _params.dstChainID,
            underlyingToken,
            isNative
        );

        emit RequestSent(_params, 'native:Multichain');
    }

    function _amountAndAllowanceChecks(
        address _tokenIn,
        address _router,
        uint256 _amountIn,
        uint256 tokenInAfter
    ) internal {
        if (tokenInAfter - IERC20Upgradeable(_tokenIn).balanceOf(address(this)) != _amountIn) {
            revert DifferentAmountSpent();
        }

        // reset allowance back to zero, just in case
        if (IERC20Upgradeable(_tokenIn).allowance(address(this), _router) > 0) {
            IERC20Upgradeable(_tokenIn).safeApprove(_router, 0);
        }
    }

    function _checkAmountIn(address _tokenIn, uint256 _amountIn) internal returns (uint256, uint256) {
        uint256 balanceBeforeTransfer = IERC20Upgradeable(_tokenIn).balanceOf(address(this));
        IERC20Upgradeable(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
        uint256 balanceAfterTransfer = IERC20Upgradeable(_tokenIn).balanceOf(address(this));
        _amountIn = balanceAfterTransfer - balanceBeforeTransfer;
        return (_amountIn, balanceAfterTransfer);
    }

    function sweepTokens(address _token, uint256 _amount) external onlyAdmin {
        sendToken(_token, _amount, msg.sender);
    }

    /// @dev Conatains the business logic for the bridge via Anyswap
    /// @param _tokenIn data specific to Anyswap
    /// @param _anyRouter data specific to Anyswap
    /// @param _amount data specific to Anyswap
    /// @param _recipient data specific to Anyswap
    /// @param _dstChain data specific to Anyswap
    /// @param _underlyingToken the underlying token to swap
    /// @param _isNative denotes whether the token is a native token or ERC20
    function _transferToMultichain(
        address _tokenIn,
        address _anyRouter,
        uint256 _amount,
        address _recipient,
        uint256 _dstChain,
        address _underlyingToken,
        bool _isNative
    ) private {
        require(_amount >= minTokenAmount[_tokenIn], 'MultichainProxy: amount must be greater than min swap amount');
        if (maxTokenAmount[_tokenIn] > 0) {
            // TODO errors
            require(_amount <= maxTokenAmount[_tokenIn], 'MultichainProxy: amount must be lower than max swap amount');
        }

        if (!availableRouters.contains(_anyRouter)) {
            revert RouterNotAvailable();
        }
        if (block.chainid == _dstChain) revert CannotBridgeToSameNetwork();

        if (_isNative) {
            IAnyswapRouter(_anyRouter).anySwapOutNative{value: _amount}(_tokenIn, _recipient, _dstChain);
        } else {
            // Give Anyswap approval to bridge tokens
            IERC20Upgradeable(_underlyingToken).safeApprove(_anyRouter, _amount);
            // Was the token wrapping another token?
            if (_tokenIn != _underlyingToken) {
                IAnyswapRouter(_anyRouter).anySwapOutUnderlying(_tokenIn, _recipient, _amount, _dstChain);
            } else {
                IAnyswapRouter(_anyRouter).anySwapOut(_tokenIn, _recipient, _amount, _dstChain);
            }
        }
    }

    /// @dev Unwraps the underlying token from the Anyswap token if necessary
    /// @param token The (maybe) wrapped token
    /// @param router The Anyswap router
    function _getUnderlyingToken(address token, address router)
        private
        returns (address underlyingToken, bool isNative)
    {
        // Token must implement IAnyswapToken interface
        if (token == address(0)) revert ZeroAddress();
        underlyingToken = IAnyswapToken(token).underlying();
        // The native token does not use the standard null address
        isNative = IAnyswapRouter(router).wNATIVE() == underlyingToken;
        // Some Multichain complying tokens may wrap nothing
        if (!isNative && underlyingToken == address(0)) {
            underlyingToken = token;
        }
    }
}