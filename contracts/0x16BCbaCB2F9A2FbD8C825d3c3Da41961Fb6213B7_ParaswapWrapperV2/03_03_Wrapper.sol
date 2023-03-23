// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";

contract ParaswapWrapperV2 {
    address public immutable PARASWAP_V5;
    address public immutable PARASWAP_TRANSFER_PROXY;

    /// @notice Thrown when swap fails.
    error swapFailed(bytes output);

    constructor(address _paraswapV5, address _paraswapTransferProxy) {
        PARASWAP_V5 = _paraswapV5;
        PARASWAP_TRANSFER_PROXY = _paraswapTransferProxy;
    }

    function swapToTokens(
        bytes calldata _txData,
        address _receiver,
        ERC20 _fromToken,
        ERC20 _toToken,
        uint256 _inputAmount
    ) external payable returns (bool success, bytes memory output) {
        if (msg.value == 0) {
            SafeTransferLib.safeTransferFrom(
                _fromToken,
                msg.sender,
                address(this),
                _inputAmount
            );
            SafeTransferLib.safeApprove(
                _fromToken,
                PARASWAP_TRANSFER_PROXY,
                _inputAmount
            );
        }
        (success, output) = PARASWAP_V5.call{value: msg.value}(_txData);
        if (!success) revert swapFailed(output);

        SafeTransferLib.safeTransfer(
            _toToken,
            _receiver,
            _toToken.balanceOf(address(this))
        );
        if (address(_fromToken) != address(0)) checkTokenRefund(_fromToken);
    }

    function swapToEth(
        bytes calldata _txData,
        address _receiver,
        ERC20 _fromToken,
        uint256 _inputAmount
    ) external returns (bool success, bytes memory output) {
        SafeTransferLib.safeTransferFrom(
            _fromToken,
            msg.sender,
            address(this),
            _inputAmount
        );
        SafeTransferLib.safeApprove(
            _fromToken,
            PARASWAP_TRANSFER_PROXY,
            _inputAmount
        );
        (success, output) = PARASWAP_V5.call(_txData);
        if (!success) revert swapFailed(output);

        SafeTransferLib.safeTransferETH(_receiver, address(this).balance);
        if (address(_fromToken) != address(0)) checkTokenRefund(_fromToken);
    }

    function checkTokenRefund(ERC20 _fromToken) internal {
        if (_fromToken.balanceOf(address(this)) > 0) {
            SafeTransferLib.safeTransfer(
                _fromToken,
                msg.sender,
                _fromToken.balanceOf(address(this))
            );
        }
    }
}