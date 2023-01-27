// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library LibSrcCrossSwap {
    using SafeERC20 for IERC20;

    event SrcCrossSwap(
        address srcToken,
        uint256 srcAmount,
        uint256 destChainId,
        address destToken,
        uint256 minDestAmount,
        address destUser,
        address connectorToken,
        uint256 connectorTokenIncome,
        address refundAddress,
        string liqudityProvider
    );

    struct CrossSwapArgs {
        address srcToken;
        uint256 srcAmount;
        uint256 destChainId;
        address destToken;
        uint256 minDestAmount;
        address destUser;
        address connectorToken;
        address refundAddress;
    }

    struct SrcSwapArgs {
        address provider;
        address approveProxy;
        bytes callData;
    }

    address internal constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @notice executeSrcSwap
     *
     * @param callData encoded calldata of the swap
     * @param srcToken address of src token
     * @param srcAmount amount of the src token to be swaped during cross chain swap
     */
    function _executeSwap(
        bytes calldata callData,
        address srcToken,
        uint256 srcAmount,
        address swapProvider,
        address swapProviderApproveProxy
    ) internal {
        if (srcToken != NATIVE_TOKEN) {
            // todo: try to remind it
            // swapProvider = srcTxRouter
            IERC20(srcToken).safeTransferFrom(msg.sender, address(this), srcAmount);
            IERC20(srcToken).approve(swapProviderApproveProxy, srcAmount);
        }

        // investigate TokenTransferProxy usage

        (bool success, ) = swapProvider.call{ value: msg.value }(callData);

        /** @dev assembly allows to get tx failure reason here*/
        if (success == false) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }
}