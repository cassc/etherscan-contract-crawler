//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IGatewayRegistry} from "@renproject/gateway-sol/src/GatewayRegistry/interfaces/IGatewayRegistry.sol";
import {IMintGateway} from "@renproject/gateway-sol/src/Gateways/interfaces/IMintGateway.sol";
import {ILockGateway} from "@renproject/gateway-sol/src/Gateways/interfaces/ILockGateway.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Allow comminting in advance to a burn or a lock of an unknown amount by
// accepting an approval rather than an amount parameter.
contract GatewayAdapter is Context {
    using SafeERC20 for IERC20;

    IGatewayRegistry public gatewayRegistry;

    // TODO: Remove me.
    event DebugLog();

    constructor(IGatewayRegistry gatewayRegistry_) {
        gatewayRegistry = gatewayRegistry_;
    }

    function bridgeApproved(
        address token,
        string calldata recipientAddress,
        string calldata recipientChain,
        bytes calldata recipientPayload
    ) public payable returns (uint256) {
        emit DebugLog();
        uint256 amount = IERC20(token).allowance(_msgSender(), address(this));
        IERC20(token).safeTransferFrom(_msgSender(), address(this), amount);

        IMintGateway mintGateway = gatewayRegistry.getMintGatewayByToken(token);
        if (address(mintGateway) != address(0x0)) {
            mintGateway.burnWithPayload(
                recipientAddress,
                recipientChain,
                recipientPayload,
                amount
            );
            return amount;
        }

        ILockGateway lockGateway = gatewayRegistry.getLockGatewayByToken(token);
        if (address(lockGateway) != address(0x0)) {
            IERC20(token).safeApprove(address(lockGateway), amount);
            lockGateway.lock(
                recipientAddress,
                recipientChain,
                recipientPayload,
                amount
            );
            return amount;
        }

        revert("GatewayAdapter: unsupported asset");
    }
}