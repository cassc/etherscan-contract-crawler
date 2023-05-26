// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "openzeppelin-contracts-v4.6.0/contracts/proxy/Proxy.sol";
import "openzeppelin-contracts-v4.6.0/contracts/utils/StorageSlot.sol";

contract SorareProxy is Proxy {
    /**
     * @dev Storage slot with the address of the contract owner.
     * This is the keccak-256 hash of "eip1967.proxy.owner" substracted by 1.
     */
    bytes32 internal constant _OWNER_SLOT =
        0xa7b53796fd2d99cb1f5ae019b54f9e024446c3d12b483f733ccc62ed04eb126a;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" substracted by 1.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Storage slot with the address of the next implementation.
     * This is the keccak-256 hash of "eip1967.proxy.newImplementation" substracted by 1.
     */
    bytes32 internal constant _NEW_IMPLEMENTATION_SLOT =
        0xb2807e65651cf78fc42f02fcff09e658fe8f4348ed4045f384b73340cc2b2ed4;

    /**
     * @dev Storage slot with the address of the previous implementation.
     * This is the keccak-256 hash of "eip1967.proxy.previousImplementation" substracted by 1.
     */
    bytes32 internal constant _PREVIOUS_IMPLEMENTATION_SLOT =
        0x3c9edc7a779f64d3f7fb0d22622f534140e56cc88c6837fb7d176db726bc545f;

    /**
     * @dev Storage slot with the upgrade delay.
     * This is the keccak-256 hash of "eip1967.proxy.upgradeDelay" substracted by 1.
     */
    bytes32 internal constant _UPGRADE_DELAY_SLOT =
        0x64e0d2a56259c33c4c94a1ff6d8155cb45e6493e62cc30b12a16babe2b94d9a7;

    /**
     * @dev Storage slot with the new upgrade delay.
     * This is the keccak-256 hash of "eip1967.proxy.newUpgradeDelay" substracted by 1.
     */
    bytes32 internal constant _NEW_UPGRADE_DELAY_SLOT =
        0x1417c2fa4abda3c661f367d5a43b88ebf17f432f83bb44dbb96ed071ab7c3c84;

    /**
     * @dev Storage slot with the the block at which new implementation was added.
     * This is the keccak-256 hash of "eip1967.proxy.enabledBlock" substracted by 1.
     */
    bytes32 internal constant _ENABLED_BLOCK_SLOT =
        0x993d3725b2c4672e0157ea7c1b648a4ef2bb2a5e6be7af409ce8093139aa3e4a;

    event ImplementationAdded(
        address indexed implementation,
        uint256 indexed upgradeDelay
    );

    event ImplementationUpgraded(
        address indexed previousImplemntation,
        address indexed implementation
    );

    event ImplementationRolledBack(
        address indexed previousImplementation,
        address indexed implementation
    );

    event PreviousImplementationPurged(address indexed previousImplementation);

    event UpgradeDelayIncreased(
        uint256 indexed previousUpgradeDelay,
        uint256 indexed upgradeDelay
    );

    constructor() {
        _setAddressSlot(_OWNER_SLOT, msg.sender);
    }

    modifier onlyOwner() {
        require(_owner() == msg.sender, "caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _setAddressSlot(_OWNER_SLOT, newOwner);
    }

    function addImplementation(
        address newImplementation,
        uint256 newUpgradeDelay
    ) public onlyOwner {
        _setAddressSlot(_NEW_IMPLEMENTATION_SLOT, newImplementation);
        _setUint256Slot(_NEW_UPGRADE_DELAY_SLOT, newUpgradeDelay);
        _setUint256Slot(_ENABLED_BLOCK_SLOT, block.number);

        emit ImplementationAdded(newImplementation, newUpgradeDelay);
    }

    function upgradeImplementation() public onlyOwner {
        require(
            block.number - _enabledBlock() >= _upgradeDelay(),
            "upgrade delay not expired"
        );
        require(
            _newImplementation() != address(0),
            "new implementation missing"
        );

        _setAddressSlot(_PREVIOUS_IMPLEMENTATION_SLOT, _implementation());
        _setAddressSlot(_IMPLEMENTATION_SLOT, _newImplementation());
        _setUint256Slot(_UPGRADE_DELAY_SLOT, _newUpgradeDelay());

        _setAddressSlot(_NEW_IMPLEMENTATION_SLOT, address(0));

        emit ImplementationUpgraded(
            _previousImplementation(),
            _implementation()
        );
    }

    function rollbackImplementation() public onlyOwner {
        require(
            _previousImplementation() != address(0),
            "previous implementation missing"
        );

        emit ImplementationRolledBack(
            _implementation(),
            _previousImplementation()
        );

        _setAddressSlot(_IMPLEMENTATION_SLOT, _previousImplementation());
        _setAddressSlot(_PREVIOUS_IMPLEMENTATION_SLOT, address(0));
    }

    function purgePreviousImplementation() public onlyOwner {
        emit PreviousImplementationPurged(_previousImplementation());

        _setAddressSlot(_PREVIOUS_IMPLEMENTATION_SLOT, address(0));
    }

    function increaseUpgradeDelay(uint256 newUpgradeDelay) public onlyOwner {
        require(
            newUpgradeDelay > _upgradeDelay(),
            "can only increase upgrade delay"
        );

        emit UpgradeDelayIncreased(_upgradeDelay(), newUpgradeDelay);

        _setUint256Slot(_UPGRADE_DELAY_SLOT, newUpgradeDelay);
    }

    function owner() public view returns (address) {
        return _owner();
    }

    function implementation() public view returns (address) {
        return _implementation();
    }

    function upgradeDelay() public view returns (uint256) {
        return _upgradeDelay();
    }

    function _owner() internal view returns (address) {
        return StorageSlot.getAddressSlot(_OWNER_SLOT).value;
    }

    function _implementation()
        internal
        view
        virtual
        override
        returns (address)
    {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function _newImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_NEW_IMPLEMENTATION_SLOT).value;
    }

    function _previousImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_PREVIOUS_IMPLEMENTATION_SLOT).value;
    }

    function _upgradeDelay() internal view returns (uint256) {
        return StorageSlot.getUint256Slot(_UPGRADE_DELAY_SLOT).value;
    }

    function _newUpgradeDelay() internal view returns (uint256) {
        return StorageSlot.getUint256Slot(_NEW_UPGRADE_DELAY_SLOT).value;
    }

    function _enabledBlock() internal view returns (uint256) {
        return StorageSlot.getUint256Slot(_ENABLED_BLOCK_SLOT).value;
    }

    function _setAddressSlot(bytes32 slot, address value) internal {
        StorageSlot.getAddressSlot(slot).value = value;
    }

    function _setUint256Slot(bytes32 slot, uint256 value) internal {
        StorageSlot.getUint256Slot(slot).value = value;
    }
}