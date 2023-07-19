// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../lib/DataTypes.sol";

interface ISwitchEvent {
    function emitSwapped(
        address from,
        address recipient,
        IERC20 fromToken,
        IERC20 destToken,
        uint256 fromAmount,
        uint256 destAmount,
        uint256 reward
    ) external;

    function emitParaswapSwapped(
        address from,
        IERC20 fromToken,
        uint256 fromAmount
    ) external;

    function emitCrosschainSwapRequest(
        bytes32 id,
        bytes32 bridgeTransferId,
        bytes32 bridge, // bridge slug
        address from, // user address
        address fromToken, // source token on sending chain
        address bridgeToken, // bridge token on sending chain
        address destToken, // dest token on receiving chain
        uint256 fromAmount, // source token amount on sending chain
        uint256 bridgeAmount, // swapped amount on sending chain
        uint256 dstAmount, // estimated amount of dest token on receiving chain
        DataTypes.SwapStatus status
    ) external;

    function emitCrosschainContractCallRequest(
        bytes32 id,
        bytes32 bridgeTransferId,
        bytes32 bridge, // bridge slug
        address from, // user address
        address toContractAddress, // The address of the contract to interact with
        address toApprovalAddress, // the approval address for contract call
        address fromToken, // source token on sending chain
        address callToken, // contract call token on receiving chain
        uint256 fromAmount, // source token amount on sending chain
        uint256 estimatedCallAmount, // estimated amount of contract call token on receiving chain
        DataTypes.ContractCallStatus status
    ) external;

    function emitCrosschainSwapDone(
        bytes32 id,
        bytes32 bridge,
        address from, // user address
        address bridgeToken, // source token on receiving chain
        address destToken, // dest token on receiving chain
        uint256 bridgeAmount, // bridge token amount on receiving chain
        uint256 destAmount, //dest token amount on receiving chain
        DataTypes.SwapStatus status
    ) external;

    function emitCrosschainContractCallDone(
        bytes32 id,
        bytes32 bridge,
        address from, // user address
        address toContractAddress, // The address of the contract to interact with
        address toApprovalAddress, // the approval address for contract call
        address bridgeToken, // source token on receiving chain
        address callToken, // call token on receiving chain
        uint256 bridgeAmount, // bridge token amount on receiving chain
        uint256 estimatedCallAmount, //dest token amount on receiving chain
        DataTypes.ContractCallStatus status
    ) external;
}