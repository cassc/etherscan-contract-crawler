// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

import {IGatewayRegistry} from "./GatewayRegistry/interfaces/IGatewayRegistry.sol";
import {IMintGateway} from "./Gateways/interfaces/IMintGateway.sol";
import {ILockGateway} from "./Gateways/interfaces/ILockGateway.sol";

contract BasicBridge is Context {
    using SafeERC20 for IERC20;

    string public constant NAME = "BasicBridge";

    IGatewayRegistry public registry;

    constructor(IGatewayRegistry _registry) {
        registry = _registry;
    }

    function mint(
        // Payload
        string calldata symbol,
        address recipient,
        // Required
        uint256 amount,
        bytes32 nHash,
        bytes calldata sig
    ) external {
        IERC20 renAsset = registry.getRenAssetBySymbol(symbol);
        IMintGateway mintGateway = registry.getMintGatewayBySymbol(symbol);

        if (address(renAsset) == address(0x0) || address(mintGateway) == address(0x0)) {
            revert(string(abi.encodePacked("BasicBridge: unknown asset ", symbol)));
        }

        bytes32 payloadHash = keccak256(abi.encode(symbol, recipient));
        uint256 amountMinted = mintGateway.mint(payloadHash, amount, nHash, sig);
        renAsset.safeTransfer(recipient, amountMinted);
    }

    function burn(
        string calldata symbol,
        string calldata recipient,
        uint256 amount
    ) external {
        IERC20 renAsset = registry.getRenAssetBySymbol(symbol);
        IMintGateway mintGateway = registry.getMintGatewayBySymbol(symbol);

        if (address(renAsset) == address(0x0) || address(mintGateway) == address(0x0)) {
            revert(string(abi.encodePacked("BasicBridge: unknown asset ", symbol)));
        }

        renAsset.safeTransferFrom(_msgSender(), address(this), amount);
        mintGateway.burn(recipient, amount);
    }

    function lock(
        string calldata symbol,
        string calldata recipientAddress,
        string calldata recipientChain,
        bytes calldata recipientPayload,
        uint256 amount
    ) external {
        IERC20 lockAsset = registry.getLockAssetBySymbol(symbol);
        ILockGateway lockGateway = registry.getLockGatewayBySymbol(symbol);

        if (address(lockAsset) == address(0x0) || address(lockGateway) == address(0x0)) {
            revert(string(abi.encodePacked("BasicBridge: unknown asset ", symbol)));
        }

        lockAsset.safeTransferFrom(_msgSender(), address(this), amount);
        lockAsset.safeIncreaseAllowance(address(lockGateway), amount);
        lockGateway.lock(recipientAddress, recipientChain, recipientPayload, amount);
    }

    function release(
        // Payload
        string calldata symbol,
        address recipient,
        // Required
        uint256 amount,
        bytes32 nHash,
        bytes calldata sig
    ) external {
        IERC20 lockAsset = registry.getLockAssetBySymbol(symbol);
        ILockGateway lockGateway = registry.getLockGatewayBySymbol(symbol);

        if (address(lockAsset) == address(0x0) || address(lockGateway) == address(0x0)) {
            revert(string(abi.encodePacked("BasicBridge: unknown asset ", symbol)));
        }

        bytes32 payloadHash = keccak256(abi.encode(symbol, recipient));
        uint256 amountReleased = lockGateway.release(payloadHash, amount, nHash, sig);
        lockAsset.safeTransfer(recipient, amountReleased);
    }
}