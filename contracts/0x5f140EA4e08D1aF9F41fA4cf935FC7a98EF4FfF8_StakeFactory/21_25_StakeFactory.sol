// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {Factory} from "../factory/Factory.sol";
import {Stake, StakeConfig} from "./Stake.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

/// @title StakeFactory
/// @notice Factory for deploying and registering `Stake` contracts.
contract StakeFactory is Factory {
    /// Template contract to clone.
    /// Deployed by the constructor.
    address public immutable implementation;

    /// Build the reference implementation to clone for each child.
    constructor() {
        address implementation_ = address(new Stake());
        emit Implementation(msg.sender, implementation_);
        implementation = implementation_;
    }

    /// @inheritdoc Factory
    function _createChild(bytes memory data_)
        internal
        virtual
        override
        returns (address)
    {
        StakeConfig memory config_ = abi.decode(data_, (StakeConfig));
        address clone_ = Clones.clone(implementation);
        Stake(clone_).initialize(config_);
        return clone_;
    }

    /// Allows calling `createChild` with `StakeConfig` struct.
    /// Use original `Factory` `createChild` function signature if function
    /// parameters are already encoded.
    ///
    /// @param config_ `Stake` initializer configuration.
    /// @return New `Stake` child contract.
    function createChildTyped(StakeConfig memory config_)
        external
        returns (Stake)
    {
        return Stake(createChild(abi.encode(config_)));
    }
}