// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

import "./interfaces/IDeBridgeGate.sol";
import "./interfaces/ICrossChainForwarder.sol";
import "./libraries/SignatureUtil.sol";
import "./ForwarderBase.sol";

contract CrosschainForwarder is ForwarderBase, ICrossChainForwarder {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SignatureUtil for bytes;

    address public constant NATIVE_TOKEN = address(0);

    IDeBridgeGate public deBridgeGate;

    mapping(address => bool) public supportedRouters;

    /* ========== Events ========== */

    event SupportedRouter(address srcSwapRouter, bool isSupported);

    /* ========== ERRORS ========== */

    // swap router didn't put target tokens on this (forwarder's) address
    error SwapEmptyResult(address srcTokenOut);

    error SwapFailed(address srcRouter);

    error NotEnoughSrcFundsIn(uint256 amount);
    error NotSupportedRouter();

    /* ========== INITIALIZERS ========== */

    function initialize(IDeBridgeGate _deBridgeGate) external initializer {
        ForwarderBase.initializeBase();
        deBridgeGate = _deBridgeGate;
    }

    /* ========== PUBLIC METHODS ========== */

    function sendV2(
        address _srcTokenIn,
        uint256 _srcAmountIn,
        bytes memory _srcTokenInPermit,
        GateParams memory _gateParams
    ) external payable override {
        _obtainSrcTokenIn(_srcTokenIn, _srcAmountIn, _srcTokenInPermit);
        _sendToBridge(_srcTokenIn, _srcAmountIn, msg.value, _gateParams);
    }

    function sendV3(
        address _srcTokenIn,
        uint256 _srcAmountIn,
        bytes memory _srcTokenInPermit,
        uint256 _affiliateFeeAmount,
        address _affiliateFeeRecipient,
        GateParams memory _gateParams
    ) external payable override {
        _obtainSrcTokenIn(_srcTokenIn, _srcAmountIn, _srcTokenInPermit);
        (uint256 srcAmountInAfterFee, uint256 msgValueAfterFee) = _distributeAffiliateFee(
            _srcTokenIn,
            _srcAmountIn,
            _affiliateFeeAmount,
            _affiliateFeeRecipient
        );

        _sendToBridge(_srcTokenIn, srcAmountInAfterFee, msgValueAfterFee, _gateParams);
    }

    function swapAndSendV3(
        address _srcTokenIn,
        uint256 _srcAmountIn,
        bytes memory _srcTokenInPermit,
        uint256 _affiliateFeeAmount,
        address _affiliateFeeRecipient,
        address _srcSwapRouter,
        bytes calldata _srcSwapCalldata,
        address _srcTokenOut,
        GateParams memory _gateParams
    ) external payable override {
        _obtainSrcTokenIn(_srcTokenIn, _srcAmountIn, _srcTokenInPermit);
        (uint256 srcAmountInAfterFee, uint256 msgValueAfterFee) = _distributeAffiliateFee(
            _srcTokenIn,
            _srcAmountIn,
            _affiliateFeeAmount,
            _affiliateFeeRecipient
        );

        (uint256 srcAmountOut, uint256 msgValueAfterSwap) = _performSwap(
            _srcTokenIn,
            srcAmountInAfterFee,
            msgValueAfterFee,
            _srcSwapRouter,
            _srcSwapCalldata,
            _srcTokenOut
        );

        _sendToBridge(_srcTokenOut, srcAmountOut, msgValueAfterSwap, _gateParams);
    }

    function swapAndSendV2(
        address _srcTokenIn,
        uint256 _srcAmountIn,
        bytes memory _srcTokenInPermit,
        address _srcSwapRouter,
        bytes calldata _srcSwapCalldata,
        address _srcTokenOut,
        GateParams memory _gateParams
    ) external payable override {
        _obtainSrcTokenIn(_srcTokenIn, _srcAmountIn, _srcTokenInPermit);

        (uint256 srcAmountOut, uint256 msgValueAfterSwap) = _performSwap(
            _srcTokenIn,
            _srcAmountIn,
            msg.value,
            _srcSwapRouter,
            _srcSwapCalldata,
            _srcTokenOut
        );

        _sendToBridge(_srcTokenOut, srcAmountOut, msgValueAfterSwap, _gateParams);
    }

    /* ========== INTERNAL METHODS ========== */

    function _distributeAffiliateFee(
        address _srcTokenIn,
        uint256 _srcAmountIn,
        uint256 _affiliateFeeAmount,
        address _affiliateFeeRecipient
    ) internal returns (uint256 srcAmountInCleared, uint256 msgValueInCleared) {
        srcAmountInCleared = _srcAmountIn;
        msgValueInCleared = msg.value;

        if (_affiliateFeeAmount > 0 && _affiliateFeeRecipient != address(0)) {
            // cut off fee from srcAmountInCleared
            srcAmountInCleared -= _affiliateFeeAmount;

            if (_srcTokenIn == NATIVE_TOKEN) {
                // reduce value as well!
                msgValueInCleared -= _affiliateFeeAmount;

                (bool success, ) = _affiliateFeeRecipient.call{
                    value: _affiliateFeeAmount
                }("");
                if (!success) {
                    revert AffiliateFeeDistributionFailed(
                        _affiliateFeeRecipient,
                        NATIVE_TOKEN,
                        _affiliateFeeAmount
                    );
                }
            } else {
                IERC20Upgradeable(_srcTokenIn).safeTransfer(
                    _affiliateFeeRecipient,
                    _affiliateFeeAmount
                );
            }
        }
    }

    function _obtainSrcTokenIn(
        address _srcTokenIn,
        uint256 _srcAmountIn,
        bytes memory _srcTokenInPermit
    ) internal {
        if (_srcTokenIn == NATIVE_TOKEN) {
            if (!(address(this).balance > _srcAmountIn))
                revert NotEnoughSrcFundsIn(_srcAmountIn);
        } else {
            uint256 srcAmountCleared = _collectSrcERC20In(
                IERC20Upgradeable(_srcTokenIn),
                _srcAmountIn,
                _srcTokenInPermit
            );
            if (srcAmountCleared < _srcAmountIn)
                revert NotEnoughSrcFundsIn(_srcAmountIn);
        }
    }

    function _performSwap(
        address _srcTokenIn,
        uint256 _srcAmountIn,
        uint256 _msgValue,
        address _srcSwapRouter,
        bytes calldata _srcSwapCalldata,
        address _srcTokenOut
    ) internal returns (uint256 srcAmountOut, uint256 msgValueAfterSwap) {
        if (!supportedRouters[_srcSwapRouter]) revert NotSupportedRouter();

        uint256 ethBalanceBefore = address(this).balance - _msgValue;

        if (_srcTokenIn == NATIVE_TOKEN) {
            srcAmountOut = _swapToERC20Via(
                _srcSwapRouter,
                _srcSwapCalldata,
                _srcAmountIn,
                IERC20Upgradeable(_srcTokenOut)
            );
        } else {
            IERC20Upgradeable(_srcTokenIn).safeApprove(
                _srcSwapRouter,
                _srcAmountIn
            );
            if (_srcTokenOut == NATIVE_TOKEN) {
                srcAmountOut = _swapToETHVia(_srcSwapRouter, _srcSwapCalldata);
            } else {
                srcAmountOut = _swapToERC20Via(
                    _srcSwapRouter,
                    _srcSwapCalldata,
                    0, /*value*/
                    IERC20Upgradeable(_srcTokenOut)
                );
            }
            IERC20Upgradeable(_srcTokenIn).safeApprove(_srcSwapRouter, 0);
        }

        msgValueAfterSwap = address(this).balance - ethBalanceBefore;
    }

    function _collectSrcERC20In(
        IERC20Upgradeable _token,
        uint256 _amount,
        bytes memory _permit
    ) internal returns (uint256) {
        // call permit before transferring token
        if (_permit.length > 0) {
            uint256 deadline = _permit.toUint256(0);
            (bytes32 r, bytes32 s, uint8 v) = _permit.parseSignature(32);
            IERC20Permit(address(_token)).permit(
                msg.sender,
                address(this),
                _amount,
                deadline,
                v,
                r,
                s
            );
        }

        uint256 balanceBefore = _token.balanceOf(address(this));
        _token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 balanceAfter = _token.balanceOf(address(this));

        if (!(balanceAfter > balanceBefore))
            revert NotEnoughSrcFundsIn(_amount);

        return (balanceAfter - balanceBefore);
    }

    function _swapToETHVia(address _router, bytes calldata _calldata)
        internal
        returns (uint256)
    {
        uint256 balanceBefore = address(this).balance;

        bool success = _externalCall(_router, _calldata, 0);
        if (!success) {
            revert SwapFailed(_router);
        }

        uint256 balanceAfter = address(this).balance;

        if (balanceBefore >= balanceAfter) revert SwapEmptyResult(address(0));

        uint256 swapDstTokenBalance = balanceAfter - balanceBefore;
        return swapDstTokenBalance;
    }

    function _swapToERC20Via(
        address _router,
        bytes calldata _calldata,
        uint256 _msgValue,
        IERC20Upgradeable _targetToken
    ) internal returns (uint256) {
        uint256 balanceBefore = _targetToken.balanceOf(address(this));

        bool success = _externalCall(_router, _calldata, _msgValue);
        if (!success) {
            revert SwapFailed(_router);
        }

        uint256 balanceAfter = _targetToken.balanceOf(address(this));
        if (balanceBefore >= balanceAfter)
            revert SwapEmptyResult(address(_targetToken));

        uint256 swapDstTokenBalance = balanceAfter - balanceBefore;
        return swapDstTokenBalance;
    }

    function _sendToBridge(
        address token,
        uint256 amount,
        uint256 _msgValue,
        GateParams memory _gateParams
    ) internal {
        // remember balance to correctly calc the change
        uint256 ethBalanceBefore = address(this).balance - _msgValue;

        if (token != NATIVE_TOKEN) {
            // allow deBridge gate to take all these wrapped tokens
            IERC20Upgradeable(token).safeApprove(address(deBridgeGate), amount);
        }

        // send to deBridge gate
        deBridgeGate.send{value: _msgValue}(
            token, // _tokenAddress
            amount, // _amount
            _gateParams.chainId, // _chainIdTo
            abi.encodePacked(_gateParams.receiver), // _receiver
            "", // _permit
            _gateParams.useAssetFee, // _useAssetFee
            _gateParams.referralCode, // _referralCode
            _gateParams.autoParams // _autoParams
        );

        if (token != NATIVE_TOKEN) {
            // turn off allowance
            IERC20Upgradeable(token).safeApprove(address(deBridgeGate), 0);
        }

        // return change, if any
        if (address(this).balance > ethBalanceBefore) {
            _safeTransferETH(
                msg.sender,
                address(this).balance - ethBalanceBefore
            );
        }
    }

    function updateSupportedRouter(address _srcSwapRouter, bool _isSupported)
        external
        onlyAdmin
    {
        supportedRouters[_srcSwapRouter] = _isSupported;
        emit SupportedRouter(_srcSwapRouter, _isSupported);
    }

    // ============ Version Control ============

    /// @dev Get this contract's version
    function version() external pure returns (uint256) {
        return 131; // 1.3.1
    }
}