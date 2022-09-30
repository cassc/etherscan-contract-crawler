// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IVaultRegistry} from "../interfaces/IVaultRegistry.sol";

/// @title meTokens Protocol Vault Registry
/// @author Carter Carlson (@cartercarlson)
/// @notice Approved vaults to be used within meTokens Protocol.
contract VaultRegistry is IVaultRegistry, Ownable {
    // NOTE: approved vault factories could be for:
    // Vanilla erc20 vaults, Uniswap-LP vaults, Balancer LP  vaults, etc.
    mapping(address => bool) private _approved;

    /// @inheritdoc IVaultRegistry
    function approve(address addr) external override onlyOwner {
        require(!_approved[addr], "addr approved");
        _approved[addr] = true;
        emit Approve(addr);
    }

    /// @inheritdoc IVaultRegistry
    function unapprove(address addr) external override onlyOwner {
        require(_approved[addr], "addr !approved");
        _approved[addr] = false;
        emit Unapprove(addr);
    }

    /// @inheritdoc IVaultRegistry
    function isApproved(address addr) external view override returns (bool) {
        return _approved[addr];
    }
}