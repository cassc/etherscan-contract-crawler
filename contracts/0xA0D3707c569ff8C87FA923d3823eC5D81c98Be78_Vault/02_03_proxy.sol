// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Events } from "./events.sol";

contract CoreInternals is Events {
    struct AddressSlot {
        address value;
    }

    struct SigsSlot {
        bytes4[] value;
    }

    /// @dev Storage slot with the admin of the contract.
    /// This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
    /// validated in the constructor.
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /// @dev Storage slot with the address of the current dummy-implementation.
    /// This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
    /// validated in the constructor.
    bytes32 internal constant _DUMMY_IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @dev Returns the storage slot which stores the sigs array set for the implementation.
    function getSlotImplSigsSlotInternal(address implementation_) internal pure returns (bytes32) {
        return keccak256(abi.encode("eip1967.proxy.implementation", implementation_));
    }

    /// @dev Returns the storage slot which stores the implementation address for the function sig.
    function getSlotSigsImplSlotInternal(bytes4 sig_) internal pure returns (bytes32) {
        return keccak256(abi.encode("eip1967.proxy.implementation", sig_));
    }

    /// @dev Returns an `AddressSlot` with member `value` located at `slot`.
    function getAddressSlotInternal(bytes32 slot_) internal pure returns (AddressSlot storage _r) {
        assembly {
            _r.slot := slot_
        }
    }

    /// @dev Returns an `SigsSlot` with member `value` located at `slot`.
    function getSigsSlotInternal(bytes32 slot_) internal pure returns (SigsSlot storage _r) {
        assembly {
            _r.slot := slot_
        }
    }

    /// @dev Sets new implementation and adds mapping from implementation to sigs and sig to implementation.
    function setImplementationSigsInternal(address implementation_, bytes4[] memory sigs_) internal {
        require(sigs_.length != 0, "no-sigs");
        bytes32 slot_ = getSlotImplSigsSlotInternal(implementation_);
        bytes4[] memory sigsCheck_ = getSigsSlotInternal(slot_).value;
        require(sigsCheck_.length == 0, "implementation-already-exist");

        for (uint256 i; i < sigs_.length; i++) {
            bytes32 sigSlot_ = getSlotSigsImplSlotInternal(sigs_[i]);
            require(getAddressSlotInternal(sigSlot_).value == address(0), "sig-already-exist");
            getAddressSlotInternal(sigSlot_).value = implementation_;
        }

        getSigsSlotInternal(slot_).value = sigs_;
        emit LogSetImplementation(implementation_, sigs_);
    }

    /// @dev Removes implementation and the mappings corresponding to it.
    function removeImplementationSigsInternal(address implementation_) internal {
        bytes32 slot_ = getSlotImplSigsSlotInternal(implementation_);
        bytes4[] memory sigs_ = getSigsSlotInternal(slot_).value;
        require(sigs_.length != 0, "implementation-not-exist");

        for (uint256 i; i < sigs_.length; i++) {
            bytes32 sigSlot_ = getSlotSigsImplSlotInternal(sigs_[i]);
            delete getAddressSlotInternal(sigSlot_).value;
        }

        delete getSigsSlotInternal(slot_).value;
        emit LogRemoveImplementation(implementation_);
    }

    /// @dev Returns bytes4[] sigs from implementation address. If implemenatation is not registered then returns empty array.
    function getImplementationSigsInternal(address implementation_) internal view returns (bytes4[] memory) {
        bytes32 slot_ = getSlotImplSigsSlotInternal(implementation_);
        return getSigsSlotInternal(slot_).value;
    }

    /// @dev Returns implementation address from bytes4 sig. If sig is not registered then returns address(0).
    function getSigImplementationInternal(bytes4 sig_) internal view returns (address implementation_) {
        bytes32 slot_ = getSlotSigsImplSlotInternal(sig_);
        return getAddressSlotInternal(slot_).value;
    }

    /// @dev Returns the current admin.
    function getAdminInternal() internal view returns (address) {
        return getAddressSlotInternal(_ADMIN_SLOT).value;
    }

    /// @dev Returns the current dummy-implementation.
    function getDummyImplementationInternal() internal view returns (address) {
        return getAddressSlotInternal(_DUMMY_IMPLEMENTATION_SLOT).value;
    }

    /// @dev Stores a new address in the EIP1967 admin slot.
    function setAdminInternal(address newAdmin_) internal {
        address oldAdmin_ = getAdminInternal();
        require(newAdmin_ != address(0), "ERC1967: new admin is the zero address");
        getAddressSlotInternal(_ADMIN_SLOT).value = newAdmin_;
        emit LogSetAdmin(oldAdmin_, newAdmin_);
    }

    /// @dev Stores a new address in the EIP1967 implementation slot.
    function setDummyImplementationInternal(address newDummyImplementation_) internal {
        address oldDummyImplementation_ = getDummyImplementationInternal();
        getAddressSlotInternal(_DUMMY_IMPLEMENTATION_SLOT).value = newDummyImplementation_;
        emit LogSetDummyImplementation(oldDummyImplementation_, newDummyImplementation_);
    }

    /// @dev Delegates the current call to `implementation`.
    /// This function does not return to its internall call site, it will return directly to the external caller.
    function delegateInternal(address implementation_) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation_, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /// @dev Delegates the current call to the address returned by Implementations registry.
    /// This function does not return to its internall call site, it will return directly to the external caller.
    function fallbackInternal(bytes4 sig_) internal {
        address implementation_ = getSigImplementationInternal(sig_);
        require(implementation_ != address(0), "Liquidity: Not able to find implementation_");
        delegateInternal(implementation_);
    }
}

contract AdminInternals is CoreInternals {
    /// @dev Only admin guard
    modifier onlyAdmin() {
        require(msg.sender == getAdminInternal(), "only-admin");
        _;
    }

    constructor(address admin_, address dummyImplementation_) {
        setAdminInternal(admin_);
        setDummyImplementationInternal(dummyImplementation_);
    }

    /// @dev Sets new admin.
    function setAdmin(address newAdmin_) external onlyAdmin {
        setAdminInternal(newAdmin_);
    }

    /// @dev Sets new dummy-implementation.
    function setDummyImplementation(address newDummyImplementation_) external onlyAdmin {
        setDummyImplementationInternal(newDummyImplementation_);
    }

    /// @dev Adds new implementation address.
    function addImplementation(address implementation_, bytes4[] calldata sigs_) external onlyAdmin {
        setImplementationSigsInternal(implementation_, sigs_);
    }

    /// @dev Removes an existing implementation address.
    function removeImplementation(address implementation_) external onlyAdmin {
        removeImplementationSigsInternal(implementation_);
    }
}

/// @title Proxy
/// @notice This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
abstract contract Proxy is AdminInternals {
    constructor(address admin_, address dummyImplementation_) AdminInternals(admin_, dummyImplementation_) {}

    /// @dev Returns admin's address.
    function getAdmin() external view returns (address) {
        return getAdminInternal();
    }

    /// @dev Returns dummy-implementations's address.
    function getDummyImplementation() external view returns (address) {
        return getDummyImplementationInternal();
    }

    /// @dev Returns bytes4[] sigs from implementation address If not registered then returns empty array.
    function getImplementationSigs(address impl_) external view returns (bytes4[] memory) {
        return getImplementationSigsInternal(impl_);
    }

    /// @dev Returns implementation address from bytes4 sig. If sig is not registered then returns address(0).
    function getSigsImplementation(bytes4 sig_) external view returns (address) {
        return getSigImplementationInternal(sig_);
    }

    /// @dev Fallback function that delegates calls to the address returned by Implementations registry.
    fallback() external payable {
        fallbackInternal(msg.sig);
    }

    /// @dev Fallback function that delegates calls to the address returned by Implementations registry.
    receive() external payable {
        if (msg.sig != 0x00000000) {
            fallbackInternal(msg.sig);
        }
    }
}