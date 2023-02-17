// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "./libraries/BeaconClones.sol";
import "./access/Ownable.sol";
import "./interfaces/IEnsoWallet.sol";

contract EnsoWalletFactory is Ownable, UUPSUpgradeable {
    using StorageAPI for bytes32;
    using BeaconClones for address;

    address public immutable ensoBeacon;

    event Deployed(IEnsoWallet instance, string label, address deployer);

    error AlreadyInit();
    error NoLabel();

    constructor(address ensoBeacon_) {
        ensoBeacon = ensoBeacon_;
        // Set owner to 0xff so that the implementation cannot be initialized
        OWNER.setAddress(address(type(uint160).max));
    }

    // @notice A function to initialize state on the proxy the delegates to this contract
    // @param newOwner The new owner of this contract
    function initialize(address newOwner) external {
        if (newOwner == address(0)) revert InvalidAccount();
        if (OWNER.getAddress() != address(0)) revert AlreadyInit();
        OWNER.setAddress(newOwner);
    }

    // @notice Deploy a wallet using the msg.sender as the salt
    // @param shortcutId The bytes32 value representing a shortcut
    // @param commands The optional commands for executing a shortcut after deployment
    // @param state The optional state for executing a shortcut after deployment
    function deploy(
        bytes32 shortcutId,
        bytes32[] calldata commands,
        bytes[] calldata state
    ) public payable returns (IEnsoWallet) {
        bytes32 salt = bytes32(uint256(uint160(msg.sender)));
        return _deploy(salt, "", shortcutId, commands, state);
    }

    // @notice Deploy a wallet using a hash of the msg.sender and a label as the salt
    // @param label The label to identify deployment
    // @param shortcutId The bytes32 value representing a shortcut
    // @param commands The optional commands for executing a shortcut after deployment
    // @param state The optional state for executing a shortcut after deployment
    function deployCustom(
        string memory label,
        bytes32 shortcutId,
        bytes32[] calldata commands,
        bytes[] calldata state
    ) public payable returns (IEnsoWallet) {
        if (bytes(label).length == 0) revert NoLabel();
        bytes32 salt = _customSalt(msg.sender, label);
        return _deploy(salt, label, shortcutId, commands, state);
    }

    // @notice Get the deployment address for the msg.sender
    function getAddress() public view returns (address payable) {
        return getUserAddress(msg.sender);
    }

    // @notice Get the deployment address for the user
    // @param user The address of the user that is used to determine the deployment address
    function getUserAddress(address user) public view returns (address payable) {
        bytes32 salt = bytes32(uint256(uint160(user)));
        return _predictDeterministicAddress(salt);
    }

    // @notice Get the deployment address for a user and label
    // @param user The address of the user that is used to determine the deployment address
    // @param label The label that is used to determine the deployment address
    function getCustomAddress(address user, string memory label) external view returns (address payable) {
        if (bytes(label).length == 0) revert NoLabel();
        bytes32 salt = _customSalt(user, label);
        return _predictDeterministicAddress(salt);
    }

    // @notice The internal function for deploying a new wallet
    // @param salt The salt for deploy the address deterministically
    // @param label The label to identify deployment in the emitted event
    // @param shortcutId The bytes32 value representing a shortcut
    // @param commands The optional commands for executing a shortcut after deployment
    // @param state The optional state for executing a shortcut after deployment
    function _deploy(
        bytes32 salt,
        string memory label,
        bytes32 shortcutId,
        bytes32[] calldata commands,
        bytes[] calldata state
    ) internal returns (IEnsoWallet instance) {
        instance = IEnsoWallet(payable(ensoBeacon.cloneDeterministic(salt)));
        instance.initialize{value: msg.value}(msg.sender, salt, shortcutId, commands, state);
        emit Deployed(instance, label, msg.sender);
    }

    // @notice Internal function to generate a custom salt using a user address and label
    // @param user The address of the user
    // @param label The label to identify the deployment
    function _customSalt(address user, string memory label) internal pure returns (bytes32) {
        return keccak256(abi.encode(user, label));
    }

    // @notice Internal function to derive the deployment address from a salt
    // @param salt The bytes32 salt to generate the deployment address
    function _predictDeterministicAddress(bytes32 salt) internal view returns (address payable) {
        return payable(ensoBeacon.predictDeterministicAddress(salt, address(this)));
    }

    // @notice Internal function to support UUPS upgrades of the implementing proxy
    // @notice newImplementation Address of the new implementation
    function _authorizeUpgrade(address newImplementation) internal view override {
        (newImplementation);
        if (msg.sender != OWNER.getAddress()) revert NotOwner();
    }
}