// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { FactoryControlled } from "./FactoryControlled.sol";
import { ErrorHandler } from "../libraries/ErrorHandler.sol";

abstract contract VaultRecipient is Initializable, FactoryControlled {
    using ErrorHandler for bytes4;

    /// @dev Link to deployed IlluviumVault instance.
    address internal _vault;

    /// @dev Used to calculate vault rewards.
    /// @dev This value is different from "reward per token" used in locked pool.
    /// @dev Note: stakes are different in duration and "weight" reflects that,
    uint256 public vaultRewardsPerWeight;

    /**
     * @dev Fired in `setVault()`.
     *
     * @param by an address which executed the function, always a factory owner
     * @param previousVault previous vault contract address
     * @param newVault new vault address
     */
    event LogSetVault(address indexed by, address previousVault, address newVault);

    /**
     * @dev Executed only by the factory owner to Set the vault.
     *
     * @param vault_ an address of deployed IlluviumVault instance
     */
    function setVault(address vault_) external virtual {
        // we're using selector to simplify input and state validation
        bytes4 fnSelector = this.setVault.selector;
        // verify function is executed by the factory owner
        fnSelector.verifyState(_factory.owner() == msg.sender, 0);
        // verify input is set
        fnSelector.verifyInput(vault_ != address(0), 0);

        // saves current vault to memory
        address previousVault = vault_;
        // update vault address
        _vault = vault_;

        // emit an event
        emit LogSetVault(msg.sender, previousVault, _vault);
    }

    /// @dev Utility function to check if caller is the Vault contract
    function _requireIsVault() internal view virtual {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("_requireIsVault()"))`
        bytes4 fnSelector = 0xeeea774b;
        // checks if caller is the same stored vault address
        fnSelector.verifyAccess(msg.sender == _vault);
    }

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}