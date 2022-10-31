// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ISwapExecutor
 * @notice Interface for executing low level swaps, including all relevant structs and enums
 */
interface ISwapExecutor {
    enum SourceTokenInteraction {
        None,
        TransferToTarget,
        ApproveToTarget
    }

    enum CallType {
        Direct,
        Calculated
    }

    struct TargetSwapDescription {
        uint256 tokenRatio;
        address target;
        bytes data;
        CallType callType;

        uint256 amountOffset;
        SourceTokenInteraction sourceInteraction;
    }

    struct SwapDescription {
        IERC20 sourceToken;
        TargetSwapDescription[] swaps;
    }

    function executeSwap(address payable recipient, IERC20 tokenToTransfer, SwapDescription[] calldata swapDescriptions) external payable;
}