// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./interfaces/IReceivingForwarder.sol";
import "./libraries/SwapCalldataUtils.sol";
import "./ForwarderBase.sol";

contract ReceivingForwarder is ForwarderBase, IReceivingForwarder {
    using SwapCalldataUtils for bytes;
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public constant NATIVE_TOKEN = address(0);

    /* ========== ERRORS ========== */

    error SwapFailed(address dstRouter);

    /* ========== INITIALIZERS ========== */

    function initialize() external initializer {
        ForwarderBase.initializeBase();
    }

    /* ========== FORWARDER METHOD ========== */

    function forward(
        address _dstTokenIn,
        address _router,
        bytes memory _routerCalldata,
        address _dstTokenOut,
        address _fallbackAddress
    ) external payable override {
        if (_dstTokenIn == NATIVE_TOKEN) {
            return _forwardFromETH(
                _router,
                _routerCalldata,
                new uint16[](0),
                _dstTokenOut,
                _fallbackAddress
            );
        }
        else {
            return _forwardFromERC20(
                IERC20Upgradeable(_dstTokenIn),
                _router,
                _routerCalldata,
                new uint16[](0),
                _dstTokenOut,
                _fallbackAddress
            );
        }
    }

    function forwardUniversal(
        address _dstTokenIn,
        address _router,
        bytes memory _routerCalldata,
        uint16[] memory _routerAmountPositions,
        address _dstTokenOut,
        address _fallbackAddress
    ) external payable override {
        if (_dstTokenIn == NATIVE_TOKEN) {
            return _forwardFromETH(
                _router,
                _routerCalldata,
                _routerAmountPositions,
                _dstTokenOut,
                _fallbackAddress
            );
        }
        else {
            return _forwardFromERC20(
                IERC20Upgradeable(_dstTokenIn),
                _router,
                _routerCalldata,
                _routerAmountPositions,
                _dstTokenOut,
                _fallbackAddress
            );
        }
    }

    /* ========== INTERNAL METHODS ========== */

    function _forwardFromETH(
        address _router,
        bytes memory _routerCalldata,
        uint16[] memory _routerAmountPositions,
        address _dstTokenOut,
        address _fallbackAddress
    ) internal {
        uint correction = address(this).balance - msg.value;
        uint dstTokenInAmount = msg.value;

        _forward(
            NATIVE_TOKEN,
            dstTokenInAmount,
            _router,
            _routerCalldata,
            _routerAmountPositions,
            _dstTokenOut,
            _fallbackAddress
        );

        if(address(this).balance > correction) {
            _safeTransferETH(_fallbackAddress, address(this).balance - correction);
        }
    }

    function _forwardFromERC20(
        IERC20Upgradeable dstTokenIn,
        address _router,
        bytes memory _routerCalldata,
        uint16[] memory _routerAmountPositions,
        address _dstTokenOut,
        address _fallbackAddress
    ) internal {
        // 1. Grab tokens from the gate
        uint correction = dstTokenIn.balanceOf(address(this));
        uint dstTokenInAmount = dstTokenIn.balanceOf(msg.sender);
        dstTokenIn.safeTransferFrom(
            msg.sender,
            address(this),
            dstTokenInAmount
        );

        dstTokenInAmount = dstTokenIn.balanceOf(address(this)) - correction;
        _customApprove(dstTokenIn, _router, dstTokenInAmount);

        _forward(
            address(dstTokenIn),
            dstTokenInAmount,
            _router,
            _routerCalldata,
            _routerAmountPositions,
            _dstTokenOut,
            _fallbackAddress
        );

        // finalize
        dstTokenIn.safeApprove(_router, 0);
        uint postBalance = dstTokenIn.balanceOf(address(this));
        if (postBalance > correction) {
            dstTokenIn.safeTransfer(_fallbackAddress, postBalance - correction);
        }
    }

    function _customApprove(IERC20Upgradeable token, address spender, uint value) internal {
        bytes memory returndata = address(token).functionCall(
            abi.encodeWithSelector(token.approve.selector, spender, value),
            "ERC20 approve failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "ERC20 operation did not succeed");
        }
    }

    function _forwardToETH(
        address _router,
        bytes memory _routerCalldata,
        address _fallbackAddress
    ) internal {
        uint balanceBefore = address(this).balance;

        // value=0 because it's obvious that we won't need ETH to swap to ETH
        // (i.e., impossible: dstTokenIn == dstTokenOut == address(0))
        bool success = _externalCall(_router, _routerCalldata, 0);
        if (!success) {
            revert SwapFailed(_router);
        }

        uint balanceAfter = address(this).balance;

        if (balanceAfter > balanceBefore) {
            _safeTransferETH(_fallbackAddress, balanceAfter - balanceBefore);
        }
    }

    function _forwardToERC20(
        uint256 dstAmountIn,
        address _router,
        bytes memory _routerCalldata,
        IERC20Upgradeable dstTokenOut,
        address _fallbackAddress
    ) internal {
        uint balanceBefore = dstTokenOut.balanceOf(address(this));

        bool success = _externalCall(_router, _routerCalldata, dstAmountIn);
        if (!success) {
            revert SwapFailed(_router);
        }

        uint balanceAfter = dstTokenOut.balanceOf(address(this));

        if (balanceAfter > balanceBefore) {
            dstTokenOut.safeTransfer(
                _fallbackAddress,
                balanceAfter - balanceBefore
            );
        }
    }

    function _forward(
        address _dstTokenIn,
        uint256 _dstAmountIn,
        address _router,
        bytes memory _routerCalldata,
        uint16[] memory _routerAmountPositions,
        address _dstTokenOut,
        address _fallbackAddress
    ) internal {
        bytes memory patchedCalldata;
        bool success;

        if (_routerAmountPositions.length > 0) {
            patchedCalldata = _routerCalldata;

            for (
                uint16 i = 0;
                i < _routerAmountPositions.length;
                i += 1
            ) {
                (patchedCalldata, success) = patchedCalldata.patchAt(
                    _dstAmountIn,
                    _routerAmountPositions[i]
                );

                if (!success) break;
            }
        }
        else {
            (patchedCalldata, success) = _routerCalldata.patch(
                _dstAmountIn
            );
        }

        if (!success) {
            return;
        }

        if (_dstTokenOut == NATIVE_TOKEN) {
            return _forwardToETH(
                 _router,
                 patchedCalldata,
                 _fallbackAddress
            );
        }
        else if (_dstTokenIn == NATIVE_TOKEN) {
            return _forwardToERC20(
                 _dstAmountIn,
                 _router,
                 patchedCalldata,
                 IERC20Upgradeable(_dstTokenOut),
                 _fallbackAddress
            );
        }
        else {
            return _forwardToERC20(
                 0,
                 _router,
                 patchedCalldata,
                 IERC20Upgradeable(_dstTokenOut),
                 _fallbackAddress
            );
        }
    }

    // ============ Version Control ============

    /// @dev Get this contract's version
    function version() external pure returns (uint256) {
        return 121; // 1.2.1
    }
}