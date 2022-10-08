// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OwnableUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {Enum, Executor} from "../../lib/safe-contracts/contracts/base/Executor.sol";

import {GlobalAccessControlManaged} from "./GlobalAccessControlManaged.sol";

/// Avatar
/// Forwards calls from the owner
contract BaseAvatar is OwnableUpgradeable, Executor {
    ////////////////////////////////////////////////////////////////////////////
    // INITIALIZATION
    ////////////////////////////////////////////////////////////////////////////

    function __BaseAvatar_init(address _owner) public onlyInitializing {
        __Ownable_init();

        transferOwnership(_owner);
    }

    ////////////////////////////////////////////////////////////////////////////
    // PUBLIC: Owner
    ////////////////////////////////////////////////////////////////////////////

    /// @dev Make arbitrary Ethereum call
    /// @param to Address to call
    /// @param value ETH value
    /// @param data TX data
    function doCall(address to, uint256 value, bytes memory data)
        public
        payable
        virtual
        onlyOwner
        returns (bool success)
    {
        success = execute(to, value, data, Enum.Operation.Call, gasleft());
    }
}