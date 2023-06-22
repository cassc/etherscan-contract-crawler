// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../lib/DataTypes.sol";
import "hardhat/console.sol";

contract SwitchEvent is Ownable, AccessControl {
    bytes32 public constant EMITTOR_ROLE=keccak256("EMITTOR_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    event Swapped(
        address from,
        address recipient,
        IERC20 fromToken,
        IERC20 destToken,
        uint256 fromAmount,
        uint256 destAmount,
        uint256 reward
    );

    event ParaswapSwapped(
        address from,
        IERC20 fromToken,
        uint256 fromAmount
    );

    event CrosschainSwapRequest(
        bytes32 indexed id,
        bytes32 bridgeTransferId,
        bytes32 indexed bridge, // bridge slug
        address indexed from, // user address
        address fromToken, // source token on sending chain
        address bridgeToken, // bridge token on sending chain
        address destToken, // dest token on receiving chain
        uint256 fromAmount, // source token amount on sending chain
        uint256 bridgeAmount, // swapped amount on sending chain
        uint256 dstAmount, // estimated amount of dest token on receiving chain
        DataTypes.SwapStatus status
    );

    event CrosschainSwapDone(
        bytes32 indexed id,
        bytes32 indexed bridge,
        address indexed from, // user address
        address bridgeToken, // source token on receiving chain
        address destToken, // dest token on receiving chain
        uint256 bridgeAmount, // bridge token amount on receiving chain
        uint256 destAmount, //dest token amount on receiving chain
        DataTypes.SwapStatus status
    );

    event CrosschainContractCallRequest(
        bytes32 indexed id,
        bytes32 bridgeTransferId,
        bytes32 indexed bridge, // bridge slug
        address indexed from, // user address
        address toContractAddress, // The address of the contract to interact with
        address toApprovalAddress, // the approval address for contract call
        address fromToken, // source token on sending chain
        address callToken, // contract call token on receiving chain
        uint256 fromAmount, // source token amount on sending chain
        uint256 estimatedCallAmount, // estimated amount of contract call token on receiving chain
        DataTypes.ContractCallStatus status
    );

    event CrosschainContractCallDone(
        bytes32 indexed id,
        bytes32 indexed bridge,
        address indexed from, // user address
        address toContractAddress, // The address of the contract to interact with
        address toApprovalAddress, // the approval address for contract call
        address bridgeToken, // source token on receiving chain
        address callToken, // call token on receiving chain
        uint256 bridgeAmount, // bridge token amount on receiving chain
        uint256 estimatedCallAmount, //dest token amount on receiving chain
        DataTypes.ContractCallStatus status
    );

    event SingleChainContractCallDone(
        address indexed from, // user address
        address toContractAddress, // The address of the contract to interact with
        address toApprovalAddress, // the approval address for contract call
        address fromToken, // source token
        address callToken, // call token
        uint256 fromAmount, // from token amount
        uint256 callAmount, // call token amount
        DataTypes.ContractCallStatus status
    );

    function emitSwapped(
        address from,
        address recipient,
        IERC20 fromToken,
        IERC20 destToken,
        uint256 fromAmount,
        uint256 destAmount,
        uint256 reward
    )
        external onlyRole(EMITTOR_ROLE)
    {
        emit Swapped(from, recipient, fromToken, destToken, fromAmount, destAmount, reward);
    }

    function emitParaswapSwapped(
        address from,
        IERC20 fromToken,
        uint256 fromAmount
    )
        external onlyRole(EMITTOR_ROLE)
    {
        emit ParaswapSwapped(from, fromToken, fromAmount);
    }

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
        uint256 destAmount, // estimated amount of dest token on receiving chain
        DataTypes.SwapStatus status
    ) external onlyRole(EMITTOR_ROLE) {
        emit CrosschainSwapRequest(id, bridgeTransferId, bridge, from, fromToken, bridgeToken, destToken, fromAmount, bridgeAmount, destAmount, status);
    }

    function emitCrosschainSwapDone(
        bytes32 id,
        bytes32 bridge,
        address from, // user address
        address bridgeToken, // source token on receiving chain
        address destToken, // dest token on receiving chain
        uint256 bridgeAmount, // bridge token amount on receiving chain
        uint256 destAmount, //dest token amount on receiving chain
        DataTypes.SwapStatus status
    ) external onlyRole(EMITTOR_ROLE) {
        emit CrosschainSwapDone(id, bridge, from, bridgeToken, destToken, bridgeAmount, destAmount, status);
    }

    function emitCrosschainContractCallRequest(
        bytes32 id,
        bytes32 bridgeTransferId,
        bytes32 bridge, // bridge slug
        address from, // user address
        address toContractAddress, // The address of the contract to interact with
        address toApprovalAddress, // the approval address for contract call
        address fromToken, // source token on sending chain
        address callToken, // dest token on receiving chain
        uint256 fromAmount, // source token amount on sending chain
        uint256 estimatedCallAmount, // estimated amount of dest token on receiving chain
        DataTypes.ContractCallStatus status
    ) external onlyRole(EMITTOR_ROLE) {
        emit CrosschainContractCallRequest(id, bridgeTransferId, bridge, from, toContractAddress, toApprovalAddress, fromToken, callToken, fromAmount, estimatedCallAmount, status);
    }

    function emitCrosschainContractCallDone(
        bytes32 id,
        bytes32 bridge,
        address from, // user address
        address toContractAddress, // The address of the contract to interact with
        address toApprovalAddress, // the approval address for contract call
        address bridgeToken, // source token on receiving chain
        address callToken, // dest token on receiving chain
        uint256 bridgeAmount, // bridge token amount on receiving chain
        uint256 estimatedCallAmount, //dest token amount on receiving chain
        DataTypes.ContractCallStatus status
    ) external onlyRole(EMITTOR_ROLE) {
        emit CrosschainContractCallDone(id, bridge, from, toContractAddress, toApprovalAddress, bridgeToken, callToken, bridgeAmount, estimatedCallAmount, status);
    }

    function emitSingleChainContractCallDone(
        address from, // user address
        address toContractAddress, // The address of the contract to interact with
        address toApprovalAddress, // the approval address for contract call
        address fromToken, // source token
        address callToken, // destination token
        uint256 fromAmount, // source token amount
        uint256 callAmount, // call token amount
        DataTypes.ContractCallStatus status
    ) external onlyRole(EMITTOR_ROLE) {
        emit SingleChainContractCallDone(from, toContractAddress, toApprovalAddress, fromToken, callToken, fromAmount, callAmount, status);
    }
}