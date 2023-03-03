// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SwapTypes} from "../libraries/SwapTypes.sol";

interface IEscrow {
    event SwapEvent(
        address indexed maker,
        address indexed taker,
        uint256 swapId,
        uint256 time,
        SwapTypes.SwapStatus status
    );

    event Erc20AllowlistSet(address[] erc20s, bool allow);

    event NftAllowlistSet(address[] nfts, bool allow);

    event FeeUpdated(uint256 fee);

    event FeeRecipientUpdated(address feeRecipient);

    function createSwap(
        SwapTypes.Intent memory,
        SwapTypes.Assets[] memory,
        SwapTypes.Assets[] memory
    ) external payable;

    function closeSwap(uint256) external payable;

    function cancelSwap(uint256) external;

    function getMakerAssetsLength(uint256) external returns (uint256);

    function getTakerAssetsLength(uint256) external returns (uint256);

    function getMakerAssets(
        uint256,
        uint256
    ) external view returns (SwapTypes.Assets memory);

    function getTakerAssets(
        uint256,
        uint256
    ) external view returns (SwapTypes.Assets memory);

    // admin functions

    function pause() external;

    function unpause() external;

    function setErc20Allowlist(address[] calldata erc20s, bool allow) external;

    function setNftAllowlist(address[] calldata nfts, bool allow) external;

    function setFee(uint256 fee) external;

    function setFeeRecipient(address payable feeRecipient) external;
}