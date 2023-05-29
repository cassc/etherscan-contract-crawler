// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Address.sol";
import "../../interfaces/1inch/IAggregationRouterV5.sol";

/**
 * @title OneinchCaller contract
 * @author Cian
 * @notice The focal point of interacting with the 1inch protocol.
 * @dev This contract will be inherited by the strategy contract and the
 * wrapper contract, used for the necessary exchange between ETH (WETH) and
 * STETH when necessary.
 * @dev When using this contract, it is necessary to first obtain the
 * calldata through 1inch API. The contract will then extract and verify the
 * calldata before proceeding with the exchange.
 */
contract OneinchCaller {
    address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // 1inch v5 is currently in use.
    address public constant oneInchRouter = 0x1111111254EEB25477B68fb85Ed929f73A960582;

    /**
     * @dev Separate the function signature and detailed parameters from the calldata.
     * @param _swapData The calldata of 1inch v5.
     * @return functionSignature_ The function signature of the swap method.
     * @return desc_ Detailed parameters of the swap.
     */
    function parseSwapCalldata(bytes memory _swapData)
        internal
        pure
        returns (bytes4 functionSignature_, IAggregationRouterV5.SwapDescription memory desc_)
    {
        // Extract function signature. (first 4 bytes of data)
        functionSignature_ = bytes4(_swapData[0]) | (bytes4(_swapData[1]) >> 8) | (bytes4(_swapData[2]) >> 16)
            | (bytes4(_swapData[3]) >> 24);

        uint256 remainingLength_ = _swapData.length - 4;
        // Create a memory variable to store the remaining bytes.
        bytes memory remainingBytes_ = new bytes(remainingLength_);
        assembly {
            let src := add(_swapData, 0x24) // source data pointer (skip 4 bytes)
            let dst := add(remainingBytes_, 0x20) // destination data pointer
            let size := remainingLength_ // size to copy

            for {} gt(size, 31) {} {
                mstore(dst, mload(src))
                src := add(src, 0x20)
                dst := add(dst, 0x20)
                size := sub(size, 0x20)
            }
            let mask := sub(exp(2, mul(8, size)), 1)
            mstore(dst, and(mload(src), mask))
        }
        (, desc_,,) =
            abi.decode(remainingBytes_, (IAggregationExecutor, IAggregationRouterV5.SwapDescription, bytes, bytes));
    }

    /**
     * @dev Executes the swap operation and verify the validity of the parameters and results.
     * @param _amount The maximum amount of currency spent in this operation.
     * @param _srcToken The token spent in this operation.
     * @param _dstToken The token received from this operation.
     * @param _swapData The calldata of 1inch v5.
     * @param _swapGetMin The minimum amount of token expected to be received from this operation.
     * @return returnAmount_ The actual amount of token spent in this operation.
     * @return spentAmount_ The actual amount of token received from this operation.
     */
    function executeSwap(
        uint256 _amount,
        address _srcToken,
        address _dstToken,
        bytes memory _swapData,
        uint256 _swapGetMin
    ) internal returns (uint256 returnAmount_, uint256 spentAmount_) {
        (bytes4 functionSignature_, IAggregationRouterV5.SwapDescription memory desc_) = parseSwapCalldata(_swapData);
        require(functionSignature_ == IAggregationRouterV5.swap.selector, "1inch: Invalid function!");
        require(address(this) == desc_.dstReceiver, "1inch: Invalid receiver!");
        require(IERC20(_srcToken) == desc_.srcToken && IERC20(_dstToken) == desc_.dstToken, "1inch: Invalid token!");
        require(_amount >= desc_.amount, "1inch: Invalid input amount!");
        bytes memory returnData_;
        if (_srcToken == ETH_ADDR) {
            returnData_ = Address.functionCallWithValue(oneInchRouter, _swapData, _amount);
        } else {
            returnData_ = Address.functionCall(oneInchRouter, _swapData);
        }
        (returnAmount_, spentAmount_) = abi.decode(returnData_, (uint256, uint256));
        require(spentAmount_ <= desc_.amount, "1inch: unexpected spentAmount.");
        require(returnAmount_ >= _swapGetMin, "1inch: unexpected returnAmount.");
    }
}