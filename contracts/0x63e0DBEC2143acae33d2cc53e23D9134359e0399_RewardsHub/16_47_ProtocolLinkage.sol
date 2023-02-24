// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "../interfaces/ILinkageLeaf.sol";
import "../interfaces/ILinkageRoot.sol";
import "./ErrorCodes.sol";

abstract contract LinkageRoot is ILinkageRoot {
    /// @notice Store self address to prevent context changing while delegateCall
    ILinkageRoot internal immutable _self = this;
    /// @notice Owner address
    address public immutable _linkage_owner;

    constructor(address owner_) {
        require(owner_ != address(0), ErrorCodes.ADMIN_ADDRESS_CANNOT_BE_ZERO);
        _linkage_owner = owner_;
    }

    /// @inheritdoc ILinkageRoot
    function switchLinkageRoot(ILinkageRoot newRoot) external {
        require(msg.sender == _linkage_owner, ErrorCodes.UNAUTHORIZED);

        emit LinkageRootSwitch(newRoot);

        Address.functionDelegateCall(
            address(newRoot),
            abi.encodePacked(LinkageRoot.interconnect.selector),
            "LinkageRoot: low-level delegate call failed"
        );
    }

    /// @inheritdoc ILinkageRoot
    function interconnect() external {
        emit LinkageRootInterconnected();
        interconnectInternal();
    }

    function interconnectInternal() internal virtual;
}

abstract contract LinkageLeaf is ILinkageLeaf {
    /// @inheritdoc ILinkageLeaf
    function switchLinkageRoot(ILinkageRoot newRoot) public {
        require(address(newRoot) != address(0), ErrorCodes.LL_NEW_ROOT_CANNOT_BE_ZERO);

        StorageSlot.AddressSlot storage slot = getRootSlot();
        address oldRoot = slot.value;
        if (oldRoot == address(newRoot)) return;

        require(oldRoot == address(0) || oldRoot == msg.sender, ErrorCodes.UNAUTHORIZED);
        slot.value = address(newRoot);

        emit LinkageRootSwitched(newRoot, LinkageRoot(oldRoot));
    }

    /**
     * @dev Gets current root contract address
     */
    function getLinkageRootAddress() internal view returns (address) {
        return getRootSlot().value;
    }

    /**
     * @dev Gets current root contract storage slot
     */
    function getRootSlot() private pure returns (StorageSlot.AddressSlot storage) {
        // keccak256("minterest.slot.linkageRoot")
        return StorageSlot.getAddressSlot(0xc34f336ef21a27e6cdbefdb1e201a57e5e6cb9d267e34fc3134d22f9decc8bbf);
    }
}