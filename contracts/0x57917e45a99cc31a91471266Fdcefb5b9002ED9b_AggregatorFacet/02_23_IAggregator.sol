// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {DataTransferType} from "../../data-transfer/LibCommon.sol";
import {TransferKey} from "../../libraries/LibTransferKey.sol";
import {SwapArgs} from "../../router/LibRouter.sol";
import {Transaction} from "../../bridge/LibTransaction.sol";
import {SwapInArgs, SwapOutArgs} from "../LibAggregator.sol";

interface IAggregator {
    event UpdateWeth(address indexed sender, address weth);

    function updateWeth(address weth) external;

    event UpdateNetworkId(address indexed sender, uint16 networkId);

    function updateNetworkId(uint16 networkId) external;

    event AddMagpieAggregatorAddresses(
        address indexed sender,
        uint16[] networkIds,
        bytes32[] magpieAggregatorAddresses
    );

    function addMagpieAggregatorAddresses(uint16[] calldata networkIds, bytes32[] calldata magpieAggregatorAddresses)
        external;

    event Swap(
        address indexed fromAddress,
        address indexed toAddress,
        address fromAssetAddress,
        address toAssetAddress,
        uint256 amountIn,
        uint256 amountOut
    );

    function swap(SwapArgs calldata swapArgs) external payable returns (uint256 amountOut);

    event SwapIn(
        address indexed fromAddress,
        bytes32 indexed toAddress,
        address fromAssetAddress,
        address toAssetAddress,
        uint256 amountIn,
        uint256 amountOut,
        TransferKey transferKey,
        Transaction transaction
    );

    function swapIn(SwapInArgs calldata swapInArgs) external payable returns (uint256 amountOut);

    event SwapOut(
        address indexed fromAddress,
        address indexed toAddress,
        address fromAssetAddress,
        address toAssetAddress,
        uint256 amountIn,
        uint256 amountOut,
        TransferKey transferKey,
        Transaction transaction
    );

    function swapOut(SwapOutArgs calldata swapOutArgs) external returns (uint256 amountOut);

    event Withdraw(address indexed sender, address indexed assetAddress, uint256 amount);

    function withdraw(address assetAddress) external;

    function getDeposit(address assetAddress) external view returns (uint256);

    function getPayload(
        DataTransferType dataTransferType,
        uint16 senderNetworkId,
        bytes32 senderAddress,
        uint64 swapSequence
    ) external view returns (bytes memory);

    function getDepositByUser(address assetAddress, address senderAddress) external view returns (uint256);

    function isTransferKeyUsed(
        uint16 networkId,
        bytes32 senderAddress,
        uint64 swapSequence
    ) external view returns (bool);
}