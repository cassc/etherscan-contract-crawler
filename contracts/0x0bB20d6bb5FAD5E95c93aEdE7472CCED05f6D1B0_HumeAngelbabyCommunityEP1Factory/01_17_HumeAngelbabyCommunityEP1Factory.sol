// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./HumeAngelbabyCommunityEP1.sol";
import "@beehiveinnovation/rain-protocol/contracts/factory/Factory.sol";

/// @title HumeAngelbabyCommunityEP1Factory
/// @notice Standard non-cloning Rain Factory with additional ownership access
/// control as per Open Zeppelin. Only owner may create children. The factory
/// owner is distinct from the owners/admins passed as config to the children.
contract HumeAngelbabyCommunityEP1Factory is Factory, Ownable {
    /// @inheritdoc Factory
    function _createChild(bytes calldata data_)
        internal
        virtual
        override
        returns (address child_)
    {
        require(
            // Called internally via `createChild`.
            msg.sender == owner() ||
            // Called externally via `createChildTyped`.
            msg.sender == address(this),
            "Ownable: caller is not the owner"
        );
        ConstructorConfig memory config_ = abi.decode(
            data_,
            (ConstructorConfig)
        );
        child_ = address(new HumeAngelbabyCommunityEP1(config_));
    }

    /// Typed wrapper around IFactory.createChild.
    function createChildTyped(ConstructorConfig calldata config_)
        external
        onlyOwner
        returns (HumeAngelbabyCommunityEP1 child_)
    {
        child_ = HumeAngelbabyCommunityEP1(
            this.createChild(abi.encode(config_))
        );
    }
}