// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC173} from "@animoca/ethereum-contracts/contracts/access/interfaces/IERC173.sol";
import {IERC20Detailed} from "@animoca/ethereum-contracts/contracts/token/ERC20/interfaces/IERC20Detailed.sol";
import {IERC20Metadata} from "@animoca/ethereum-contracts/contracts/token/ERC20/interfaces/IERC20Metadata.sol";
import {IForwarderRegistry} from "@animoca/ethereum-contracts/contracts/metatx/interfaces/IForwarderRegistry.sol";
import {FxERC20RootTunnel} from "./FxERC20RootTunnel.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title FxERC20FixedSupplyRootTunnel
/// @notice Fx root fixed supply ERC20 tunnel.
contract FxERC20FixedSupplyRootTunnel is FxERC20RootTunnel {
    using SafeERC20 for IERC20;

    constructor(
        address checkpointManager,
        address fxRoot,
        address fxERC20Token,
        IForwarderRegistry forwarderRegistry
    ) FxERC20RootTunnel(checkpointManager, fxRoot, fxERC20Token, forwarderRegistry) {}

    /// @inheritdoc FxERC20RootTunnel
    function _encodeChildTokenInitArgs(address rootToken) internal virtual override returns (bytes memory) {
        uint256 totalSupply = IERC20(rootToken).totalSupply();
        IERC20Detailed rootTokenContract = IERC20Detailed(rootToken);
        string memory name = rootTokenContract.name();
        string memory symbol = rootTokenContract.symbol();
        uint8 decimals = rootTokenContract.decimals();
        string memory tokenURI = IERC20Metadata(rootToken).tokenURI();
        address owner = IERC173(rootToken).owner();

        return abi.encode(totalSupply, name, symbol, decimals, tokenURI, owner);
    }

    /// @inheritdoc FxERC20RootTunnel
    /// @notice Tokens are already escrowed when coming through the onERC20Received function
    function _depositReceivedTokens(address rootToken, uint256 amount) internal virtual override {}

    /// @inheritdoc FxERC20RootTunnel
    /// @notice Escrows the deposit amount in this contract.
    function _depositTokensFrom(address rootToken, address depositor, uint256 amount) internal virtual override {
        IERC20(rootToken).safeTransferFrom(depositor, address(this), amount);
    }

    /// @inheritdoc FxERC20RootTunnel
    /// @notice Unescrows the withdrawal amount from this contract.
    function _withdraw(address rootToken, address receiver, uint256 amount) internal virtual override {
        IERC20(rootToken).safeTransfer(receiver, amount);
    }
}