// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../vault/IVault.sol";
import "../..//storage/IStorage.sol";
import "./IModule.sol";
import "../../infrastructure/IModuleRegistry.sol";

/**
 * @title BaseModule
 * @notice Base Module contract that contains methods common to all Modules.
 */
abstract contract BaseModule is IModule {

    // different types of signatures
    enum Signature {
        Owner,  
        KWG,
        OwnerAndGuardian, 
        OwnerAndGuardianOrOwnerAndKWG,
        OwnerOrKWG,
        GuardianOrKWG,
        OwnerOrGuardianOrKWG
    }

    // Empty calldata
    bytes constant internal EMPTY_BYTES = "";

    // Zero address
    address constant internal ZERO_ADDRESS = address(0);

    // The guardians storage
    IStorage internal immutable _storage;

    // Module Registry address
    IModuleRegistry internal immutable moduleRegistry;

    /**
     * @notice Throws if the sender is not the module itself.
     */
    modifier onlySelf() {
        require(_isSelf(msg.sender), "BM: must be module");
        _;
    }

    /**
     * @dev Throws if the sender is not the target vault of the call.
     */
    modifier onlyVault(address _vault) {
        require(
            msg.sender == _vault,
            "BM: caller must be vault"
        );
        _;
    }

    /**
     * @param Storage deployed instance of storage contract
     */
    constructor(
        IStorage Storage,
        IModuleRegistry _moduleRegistry
    ) {
        _storage = Storage;
        moduleRegistry = _moduleRegistry;
    }

    /**
     * @notice Helper method to check if an address is the module itself.
     * @param _addr - The target address.
     * @return true if locked.
     */
    function _isSelf(address _addr) internal view returns (bool) {
        return _addr == address(this);
    }

    /**
     * @notice Helper method to check if an address is the owner of a target vault.
     * @param _vault The target vault.
     * @param _addr The address.
     */
    function _isOwner(address _vault, address _addr) internal view returns (bool) {
        return IVault(_vault).owner() == _addr;
    }

    /**
     * @notice Helper method to invoke a vault.
     * @param _vault - The target vault.
     * @param _to - The target address for the transaction.
     * @param _value - The value of the transaction.
     * @param _data - The data of the transaction.
     * @return _res result of low level call from vault.
     */
    function invokeVault(
        address _vault,
        address _to,
        uint256 _value,
        bytes memory _data
    ) 
        internal
        returns
        (bytes memory _res) 
    {
        bool success;
        (success, _res) = _vault.call(
            abi.encodeWithSignature(
                "invoke(address,uint256,bytes)",
                _to,
                _value,
                _data
            )
        );
        if (success && _res.length > 0) {
            (_res) = abi.decode(_res, (bytes));
        } else if (_res.length > 0) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        } else if (!success) {
            revert("BM: vault invoke reverted");
        }
    }
}