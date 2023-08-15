// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IZkEVMBridge} from "./interfaces/IZkEVMBridge.sol";
import {IDai} from "./interfaces/IDai.sol";

/// @title ZkEVMWrapper
/// @author QEDK <[email protected]> (https://polygon.technology)
/// @notice This contract is a wrapper for the zkEVM bridge allowing deposits of Ether and ERC20
/// @custom:security [email protected]
contract ZkEVMWrapper {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Permit;
    using SafeERC20 for IDai;

    IZkEVMBridge private immutable _zkEVMBridge;

    constructor(IZkEVMBridge zkEVMBridge_) {
        _zkEVMBridge = zkEVMBridge_;
    }

    /// @notice Bridge Ether and ERC20 to zkEVM using traditional approval
    /// @param token Address of ERC20 token to deposit
    /// @param amount Amount to deposit
    /// @param destination The destination address on the zkEVM bridge
    function deposit(IERC20 token, uint256 amount, address destination) external payable {
        token.safeTransferFrom(msg.sender, address(this), amount);
        token.forceApprove(address(_zkEVMBridge), amount);
        _zkEVMBridge.bridgeAsset(
            1, // destinationNetwork
            destination,
            amount,
            address(token),
            false, // forceUpdateGlobalExitRoot
            "" // permitData
        );
        _zkEVMBridge.bridgeAsset{value: msg.value}(
            1, // destinationNetwork
            destination,
            msg.value,
            address(0),
            true, // forceUpdateGlobalExitRoot
            "" // permitData
        );
    }

    /// @notice Bridge Ether and ERC20 to zkEVM using EIP-2612 permit
    /// @param token Address of ERC20 token to deposit
    /// @param amount Amount to deposit
    /// @param destination The destination address on the zkEVM bridge
    function deposit(IERC20 token, uint256 amount, address destination, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
        payable
    {
        IERC20Permit(address(token)).safePermit(msg.sender, address(this), amount, deadline, v, r, s);
        token.safeTransferFrom(msg.sender, address(this), amount);
        token.forceApprove(address(_zkEVMBridge), amount);
        _zkEVMBridge.bridgeAsset(
            1, // destinationNetwork
            destination,
            amount,
            address(token),
            false, // forceUpdateGlobalExitRoot
            "" // permitData
        );
        _zkEVMBridge.bridgeAsset{value: msg.value}(
            1, // destinationNetwork
            destination,
            msg.value,
            address(0),
            true, // forceUpdateGlobalExitRoot
            "" // permitData
        );
    }

    /// @notice Bridge Ether and ERC20 to zkEVM using DAI permit
    /// @param token Address of ERC20 token to deposit
    /// @param amount Amount to deposit
    /// @param destination The destination address on the zkEVM bridge
    function deposit(
        IDai token,
        uint256 amount,
        address destination,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        token.permit(msg.sender, address(this), nonce, expiry, allowed, v, r, s);
        token.safeTransferFrom(msg.sender, address(this), amount);
        token.forceApprove(address(_zkEVMBridge), amount);
        _zkEVMBridge.bridgeAsset(
            1, // destinationNetwork
            destination,
            amount,
            address(token),
            false, // forceUpdateGlobalExitRoot
            "" // permitData
        );
        _zkEVMBridge.bridgeAsset{value: msg.value}(
            1, // destinationNetwork
            destination,
            msg.value,
            address(0),
            true, // forceUpdateGlobalExitRoot
            "" // permitData
        );
    }
}