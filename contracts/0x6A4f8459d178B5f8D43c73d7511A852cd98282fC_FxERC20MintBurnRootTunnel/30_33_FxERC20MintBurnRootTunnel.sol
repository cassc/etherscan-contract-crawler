// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC173} from "@animoca/ethereum-contracts/contracts/access/interfaces/IERC173.sol";
import {IERC20Detailed} from "@animoca/ethereum-contracts/contracts/token/ERC20/interfaces/IERC20Detailed.sol";
import {IERC20Metadata} from "@animoca/ethereum-contracts/contracts/token/ERC20/interfaces/IERC20Metadata.sol";
import {IERC20Mintable} from "@animoca/ethereum-contracts/contracts/token/ERC20/interfaces/IERC20Mintable.sol";
import {IERC20Burnable} from "@animoca/ethereum-contracts/contracts/token/ERC20/interfaces/IERC20Burnable.sol";
import {IForwarderRegistry} from "@animoca/ethereum-contracts/contracts/metatx/interfaces/IForwarderRegistry.sol";
import {FxERC20RootTunnel} from "./FxERC20RootTunnel.sol";

/// @title FxERC20MintBurnRootTunnel
/// @notice Fx root mintable burnable ERC20 tunnel.
contract FxERC20MintBurnRootTunnel is FxERC20RootTunnel {
    constructor(
        address checkpointManager,
        address fxRoot,
        address fxERC20Token,
        IForwarderRegistry forwarderRegistry
    ) FxERC20RootTunnel(checkpointManager, fxRoot, fxERC20Token, forwarderRegistry) {}

    /// @inheritdoc FxERC20RootTunnel
    function _encodeChildTokenInitArgs(address rootToken) internal virtual override returns (bytes memory) {
        IERC20Detailed rootTokenContract = IERC20Detailed(rootToken);
        string memory name = rootTokenContract.name();
        string memory symbol = rootTokenContract.symbol();
        uint8 decimals = rootTokenContract.decimals();
        string memory tokenURI = IERC20Metadata(rootToken).tokenURI();
        address owner = IERC173(rootToken).owner();

        return abi.encode(name, symbol, decimals, tokenURI, owner);
    }

    /// @inheritdoc FxERC20RootTunnel
    /// @notice Burns the deposit amount.
    function _depositReceivedTokens(address rootToken, uint256 amount) internal virtual override {
        IERC20Burnable(rootToken).burn(amount);
    }

    /// @inheritdoc FxERC20RootTunnel
    /// @notice Burns the deposit amount.
    function _depositTokensFrom(address rootToken, address depositor, uint256 amount) internal virtual override {
        IERC20Burnable(rootToken).burnFrom(depositor, amount);
    }

    /// @inheritdoc FxERC20RootTunnel
    /// @notice Mints the withdrawal amount.
    function _withdraw(address rootToken, address receiver, uint256 amount) internal virtual override {
        IERC20Mintable(rootToken).mint(receiver, amount);
    }
}