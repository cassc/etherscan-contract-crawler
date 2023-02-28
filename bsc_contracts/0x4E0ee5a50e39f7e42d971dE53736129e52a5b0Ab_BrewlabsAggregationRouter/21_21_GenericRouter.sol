// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";
import "@1inch/solidity-utils/contracts/libraries/UniERC20.sol";
import "@1inch/solidity-utils/contracts/EthReceiver.sol";

import "contracts/interfaces/IAggregationExecutor.sol";

import "contracts/helpers/RouterErrors.sol";

contract GenericRouter is EthReceiver {
    using UniERC20 for IERC20;
    using SafeERC20 for IERC20;

    error ZeroMinReturn();
    error ZeroReturnAmount();

    uint256 private constant _PARTIAL_FILL = 1 << 0;
    uint256 private constant _REQUIRES_EXTRA_ETH = 1 << 1;

    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    /// @notice Performs a swap, delegating all calls encoded in `data` to `executor`. See tests for usage examples
    /// @dev router keeps 1 wei of every token on the contract balance for gas optimisations reasons. This affects first swap of every token by leaving 1 wei on the contract.
    /// @param executor Aggregation executor that executes calls described in `data`
    /// @param desc Swap description
    /// @param permit Should contain valid permit that can be used in `IERC20Permit.permit` calls.
    /// @param data Encoded calls that `caller` should execute in between of swaps
    /// @return returnAmount Resulting token amount
    /// @return spentAmount Source token amount
    function swap(
        IAggregationExecutor executor,
        SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data,
        uint256 msgValue
    )
        internal
        returns (
            uint256 returnAmount,
            uint256 spentAmount
        )
    {
        if (desc.minReturnAmount == 0) revert ZeroMinReturn();

        IERC20 srcToken = desc.srcToken;
        IERC20 dstToken = desc.dstToken;

        bool srcETH = srcToken.isETH();
        if (desc.flags & _REQUIRES_EXTRA_ETH != 0) {
            if (msgValue <= (srcETH ? desc.amount : 0)) revert RouterErrors.InvalidMsgValue();
        } else {
            if (msgValue != (srcETH ? desc.amount : 0)) revert RouterErrors.InvalidMsgValue();
        }

        if (!srcETH) {
            if (permit.length > 0) {
                srcToken.safePermit(permit);
            }
            srcToken.safeTransferFrom(msg.sender, desc.srcReceiver, desc.amount);
        }

        _execute(executor, msg.sender, msgValue, desc.amount, data);

        spentAmount = desc.amount;
        // we leave 1 wei on the router for gas optimisations reasons
        returnAmount = dstToken.uniBalanceOf(address(this));
        if (returnAmount == 0) revert ZeroReturnAmount();
        unchecked { returnAmount--; }

        if (desc.flags & _PARTIAL_FILL != 0) {
            uint256 unspentAmount = srcToken.uniBalanceOf(address(this));
            if (unspentAmount > 1) {
                // we leave 1 wei on the router for gas optimisations reasons
                unchecked { unspentAmount--; }
                spentAmount -= unspentAmount;
                srcToken.uniTransfer(payable(msg.sender), unspentAmount);
            }
            if (returnAmount * desc.amount < desc.minReturnAmount * spentAmount) revert RouterErrors.ReturnAmountIsNotEnough();
        } else {
            if (returnAmount < desc.minReturnAmount) revert RouterErrors.ReturnAmountIsNotEnough();
        }

        address payable dstReceiver = (desc.dstReceiver == address(0)) ? payable(msg.sender) : desc.dstReceiver;
        dstToken.uniTransfer(dstReceiver, returnAmount);
    }

    function _execute(
        IAggregationExecutor executor,
        address srcTokenOwner,
        uint256 msgValue,
        uint256 inputAmount,
        bytes calldata data
    ) private {
        bytes4 executeSelector = executor.execute.selector;
        /// @solidity memory-safe-assembly
        assembly {  // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)

            mstore(ptr, executeSelector)
            mstore(add(ptr, 0x04), srcTokenOwner)
            calldatacopy(add(ptr, 0x24), data.offset, data.length)
            mstore(add(add(ptr, 0x24), data.length), inputAmount)

            if iszero(call(gas(), executor, msgValue, ptr, add(0x44, data.length), 0, 0)) {
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
        }
    }
}