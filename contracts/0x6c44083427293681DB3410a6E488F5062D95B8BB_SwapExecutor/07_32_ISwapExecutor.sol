// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ISwapExecutor
 * @notice Interface for executing low level swaps, including all relevant structs and enums
 */
interface ISwapExecutor {
    struct TargetSwapDescription {
        uint256 tokenRatio;
        address target;
        bytes data;
        // uint8 callType; first 8 bits
        // uint8 sourceInteraction; next 8 bits
        // uint32 amountOffset; next 32 bits
        // address sourceTokenInteractionTarget; last 160 bits
        uint256 params;
    }

    struct SwapDescription {
        IERC20 sourceToken;
        TargetSwapDescription[] swaps;
    }

    function executeSwap(address payable recipient, IERC20 tokenToTransfer, SwapDescription[] calldata swapDescriptions) external payable;
}

uint8 constant CALL_TYPE_DIRECT = 0;
uint8 constant CALL_TYPE_CALCULATED = 1;
uint8 constant SOURCE_TOKEN_INTERACTION_NONE = 0;
uint8 constant SOURCE_TOKEN_INTERACTION_TRANSFER = 1;
uint8 constant SOURCE_TOKEN_INTERACTION_APPROVE = 2;