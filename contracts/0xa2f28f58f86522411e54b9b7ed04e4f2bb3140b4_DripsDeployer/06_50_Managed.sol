// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.20;

import {UUPSUpgradeable} from "openzeppelin-contracts/proxy/utils/UUPSUpgradeable.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {EnumerableSet} from "openzeppelin-contracts/utils/structs/EnumerableSet.sol";
import {StorageSlot} from "openzeppelin-contracts/utils/StorageSlot.sol";

using EnumerableSet for EnumerableSet.AddressSet;

/// @notice A mix-in for contract pausing, upgrading and admin management.
/// It can't be used directly, only via a proxy. It uses the upgrade-safe ERC-1967 storage scheme.
///
/// Managed uses the ERC-1967 admin slot to store the admin address.
/// All instances of the contracts have admin address `0x00` and are forever paused.
/// When a proxy uses such contract via delegation, the proxy should define
/// the initial admin address and the contract is initially unpaused.
abstract contract Managed is UUPSUpgradeable {
    /// @notice The pointer to the storage slot holding a single `ManagedStorage` structure.
    bytes32 private immutable _managedStorageSlot = _erc1967Slot("eip1967.managed.storage");

    /// @notice Emitted when a new admin of the contract is proposed.
    /// The proposed admin must call `acceptAdmin` to finalize the change.
    /// @param currentAdmin The current admin address.
    /// @param newAdmin The proposed admin address.
    event NewAdminProposed(address indexed currentAdmin, address indexed newAdmin);

    /// @notice Emitted when the pauses role is granted.
    /// @param pauser The address that the pauser role was granted to.
    /// @param admin The address of the admin that triggered the change.
    event PauserGranted(address indexed pauser, address indexed admin);

    /// @notice Emitted when the pauses role is revoked.
    /// @param pauser The address that the pauser role was revoked from.
    /// @param admin The address of the admin that triggered the change.
    event PauserRevoked(address indexed pauser, address indexed admin);

    /// @notice Emitted when the pause is triggered.
    /// @param pauser The address that triggered the change.
    event Paused(address indexed pauser);

    /// @notice Emitted when the pause is lifted.
    /// @param pauser The address that triggered the change.
    event Unpaused(address indexed pauser);

    struct ManagedStorage {
        bool isPaused;
        EnumerableSet.AddressSet pausers;
        address proposedAdmin;
    }

    /// @notice Throws if called by any caller other than the admin.
    modifier onlyAdmin() {
        require(admin() == msg.sender, "Caller not the admin");
        _;
    }

    /// @notice Throws if called by any caller other than the admin or a pauser.
    modifier onlyAdminOrPauser() {
        require(admin() == msg.sender || isPauser(msg.sender), "Caller not the admin or a pauser");
        _;
    }

    /// @notice Modifier to make a function callable only when the contract is not paused.
    modifier whenNotPaused() {
        require(!isPaused(), "Contract paused");
        _;
    }

    /// @notice Modifier to make a function callable only when the contract is paused.
    modifier whenPaused() {
        require(isPaused(), "Contract not paused");
        _;
    }

    /// @notice Initializes the contract in paused state and with no admin.
    /// The contract instance can be used only as a call delegation target for a proxy.
    constructor() {
        _managedStorage().isPaused = true;
    }

    /// @notice Returns the current implementation address.
    function implementation() public view returns (address) {
        return _getImplementation();
    }

    /// @notice Returns the address of the current admin.
    function admin() public view returns (address) {
        return _getAdmin();
    }

    /// @notice Returns the proposed address to change the admin to.
    function proposedAdmin() public view returns (address) {
        return _managedStorage().proposedAdmin;
    }

    /// @notice Proposes a change of the admin of the contract.
    /// The proposed new admin must call `acceptAdmin` to finalize the change.
    /// To cancel a proposal propose a different address, e.g. the zero address.
    /// Can only be called by the current admin.
    /// @param newAdmin The proposed admin address.
    function proposeNewAdmin(address newAdmin) public onlyAdmin {
        emit NewAdminProposed(msg.sender, newAdmin);
        _managedStorage().proposedAdmin = newAdmin;
    }

    /// @notice Applies a proposed change of the admin of the contract.
    /// Sets the proposed admin to the zero address.
    /// Can only be called by the proposed admin.
    function acceptAdmin() public {
        require(proposedAdmin() == msg.sender, "Caller not the proposed admin");
        _updateAdmin(msg.sender);
    }

    /// @notice Changes the admin of the contract to address zero.
    /// It's no longer possible to change the admin or upgrade the contract afterwards.
    /// Can only be called by the current admin.
    function renounceAdmin() public onlyAdmin {
        _updateAdmin(address(0));
    }

    /// @notice Sets the current admin of the contract and clears the proposed admin.
    /// @param newAdmin The admin address being set. Can be the zero address.
    function _updateAdmin(address newAdmin) internal {
        emit AdminChanged(admin(), newAdmin);
        _managedStorage().proposedAdmin = address(0);
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /// @notice Grants the pauser role to an address. Callable only by the admin.
    /// @param pauser The granted address.
    function grantPauser(address pauser) public onlyAdmin {
        require(_managedStorage().pausers.add(pauser), "Address already is a pauser");
        emit PauserGranted(pauser, msg.sender);
    }

    /// @notice Revokes the pauser role from an address. Callable only by the admin.
    /// @param pauser The revoked address.
    function revokePauser(address pauser) public onlyAdmin {
        require(_managedStorage().pausers.remove(pauser), "Address is not a pauser");
        emit PauserRevoked(pauser, msg.sender);
    }

    /// @notice Checks if an address is a pauser.
    /// @param pauser The checked address.
    /// @return isAddrPauser True if the address is a pauser.
    function isPauser(address pauser) public view returns (bool isAddrPauser) {
        return _managedStorage().pausers.contains(pauser);
    }

    /// @notice Returns all the addresses with the pauser role.
    /// @return pausersList The list of all the pausers, ordered arbitrarily.
    /// The list's order may change after granting or revoking the pauser role.
    function allPausers() public view returns (address[] memory pausersList) {
        return _managedStorage().pausers.values();
    }

    /// @notice Returns true if the contract is paused, and false otherwise.
    function isPaused() public view returns (bool) {
        return _managedStorage().isPaused;
    }

    /// @notice Triggers stopped state. Callable only by the admin or a pauser.
    function pause() public onlyAdminOrPauser whenNotPaused {
        _managedStorage().isPaused = true;
        emit Paused(msg.sender);
    }

    /// @notice Returns to normal state. Callable only by the admin or a pauser.
    function unpause() public onlyAdminOrPauser whenPaused {
        _managedStorage().isPaused = false;
        emit Unpaused(msg.sender);
    }

    /// @notice Calculates the quasi ERC-1967 slot pointer.
    /// @param name The name of the slot, should be globally unique
    /// @return slot The slot pointer
    function _erc1967Slot(string memory name) internal pure returns (bytes32 slot) {
        // The original ERC-1967 subtracts 1 from the hash to get 1 storage slot
        // under an index without a known hash preimage which is enough to store a single address.
        // This implementation subtracts 1024 to get 1024 slots without a known preimage
        // allowing securely storing much larger structures.
        return bytes32(uint256(keccak256(bytes(name))) - 1024);
    }

    /// @notice Returns the Managed storage.
    /// @return storageRef The storage.
    function _managedStorage() internal view returns (ManagedStorage storage storageRef) {
        bytes32 slot = _managedStorageSlot;
        // slither-disable-next-line assembly
        assembly {
            storageRef.slot := slot
        }
    }

    /// @notice Authorizes the contract upgrade. See `UUPSUpgradeable` docs for more details.
    function _authorizeUpgrade(address /* newImplementation */ ) internal view override onlyAdmin {
        return;
    }
}

/// @notice A generic proxy for contracts implementing `Managed`.
contract ManagedProxy is ERC1967Proxy {
    constructor(Managed logic, address admin) ERC1967Proxy(address(logic), new bytes(0)) {
        _changeAdmin(admin);
    }
}