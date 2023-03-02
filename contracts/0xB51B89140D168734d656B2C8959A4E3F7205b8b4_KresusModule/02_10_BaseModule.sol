// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../vault/IVault.sol";
import "../..//storage/IStorage.sol";
import "./IModule.sol";

/**
 * @title BaseModule
 * @notice Base Module contract that contains methods common to all Modules.
 */
abstract contract BaseModule is IModule {

    // Empty calldata
    bytes constant internal EMPTY_BYTES = "";

    // Mock token address for ETH
    address constant internal ETH_TOKEN = address(0);

    // The guardians storage
    IStorage internal immutable Storage;

    event ModuleCreated(bytes32 name);
    // different types of signatures
    enum Signature {
        Owner,  
        KWG,
        OwnerandGuardian, 
        OwnerandGuardianOrOwnerandKWG,
        OwnerOrKWG,
        GuardianOrKWG,
        OwnerOrGuardianOrKWG
    }

    /**
     * @notice Throws if the vault is not locked.
     */
    modifier onlyWhenLocked(address _vault) {
        require(_isLocked(_vault), "BM: vault must be locked");
        _;
    }

    /**
     * @notice Throws if the vault is locked.
     */
    modifier onlyWhenUnlocked(address _vault) {
        require(!_isLocked(_vault), "BM: vault locked");
        _;
    }

    /**
     * @notice Throws if the sender is not the module itself.
     */
    modifier onlySelf() {
        require(_isSelf(msg.sender), "BM: must be module");
        _;
    }

    /**
     * @notice Throws if the sender is not the module itself or the owner of the target vault.
     */
    modifier onlyVaultOwnerOrSelf(address _vault) {
        require(
            _isSelf(msg.sender) ||
            _isOwner(_vault, msg.sender), 
            "BM: must be vault owner/self"
        );
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
     * @param _Storage deployed instance of storage contract
     * @param _name - The name of the module.
     */
    constructor(
        IStorage _Storage,
        bytes32 _name
    ) {
        Storage = _Storage;
        emit ModuleCreated(_name);
    }
    
    /**
     * @notice Helper method to check if an address is the owner of a target vault.
     * @param _vault - The target vault.
     * @param _addr - The address.
     * @return true if it is address of owner
     */
    function _isOwner(address _vault, address _addr) internal view returns (bool) {
        return IVault(_vault).owner() == _addr;
    }

    /**
     * @notice Helper method to check if a vault is locked.
     * @param _vault - The target vault.
     */
    function _isLocked(address _vault) internal view returns (bool) {
        return Storage.isLocked(_vault);
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