//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/ILibertiVault.sol";

struct SwapDescription {
    IERC20 srcToken;
    IERC20 dstToken;
    address srcReceiver; // from
    address dstReceiver; // to
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
    bytes permit;
}

abstract contract LibertiAggregationRouterV4 {
    address private constant AGGREGATION_ROUTER_V4 = 0x1111111254fb6c44bAC0beD2854e76F90643097d;

    error AmountError(uint256 got, uint256 expected);
    error NetworkError();
    error ReceiverError(address got, address expected);
    error TokenError();

    function userSwap(
        bytes calldata data,
        address receiver,
        uint256 swapAmount,
        address srcToken,
        address dstToken
    ) internal returns (uint256 returnAmount) {
        (, SwapDescription memory desc, ) = abi.decode(data[4:], (address, SwapDescription, bytes));
        if (desc.dstReceiver != receiver) {
            revert ReceiverError(desc.dstReceiver, receiver);
        }
        if (desc.amount != swapAmount) {
            revert AmountError(desc.amount, swapAmount);
        }
        if ((address(desc.srcToken) != srcToken) || (address(desc.dstToken) != dstToken)) {
            revert TokenError();
        }
        return _swap(data, swapAmount, srcToken);
    }

    function adminSwap(
        bytes calldata data,
        address asset,
        address other
    ) internal returns (uint256 returnAmount) {
        (, SwapDescription memory desc, ) = abi.decode(data[4:], (address, SwapDescription, bytes));
        if (desc.dstReceiver != address(this)) {
            revert ReceiverError(desc.dstReceiver, address(this));
        }
        // We don't need to check source token as long as destination token is in favor of the vault.
        // It also enable the rescue of tokens that are not `asset` or `other`, and would be locked in
        // contract otherwise.
        if ((address(desc.dstToken) != asset) && (address(desc.dstToken) != other)) {
            revert TokenError();
        }
        return _swap(data, desc.amount, address(desc.srcToken));
    }

    // Will revert in 1inch router contract with 'Return amount is not enough' reason
    // if returnAmount < desc.minReturnAmount
    function _swap(
        bytes calldata data,
        uint256 amount,
        address srcToken
    ) private returns (uint256 returnAmount) {
        SafeERC20.safeIncreaseAllowance(IERC20(srcToken), AGGREGATION_ROUTER_V4, amount);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = AGGREGATION_ROUTER_V4.call(data);
        if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                revert(add(returndata, 32), mload(returndata))
            }
        }
        if (1 == block.chainid) {
            (returnAmount, , ) = abi.decode(returndata, (uint256, uint256, uint256));
        } else if ((56 == block.chainid) || (137 == block.chainid)) {
            (returnAmount, ) = abi.decode(returndata, (uint256, uint256));
        } else {
            revert NetworkError();
        }
    }
}