// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC173} from "./../interfaces/IERC173.sol";
import {ContractOwnershipStorage} from "./../libraries/ContractOwnershipStorage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC173 Contract Ownership Standard (proxiable version).
/// @dev See https://eips.ethereum.org/EIPS/eip-173
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC165 (Interface Detection Standard).
abstract contract ContractOwnershipBase is Context, IERC173 {
    using ContractOwnershipStorage for ContractOwnershipStorage.Layout;

    /// @inheritdoc IERC173
    function owner() public view virtual override returns (address) {
        return ContractOwnershipStorage.layout().owner();
    }

    /// @inheritdoc IERC173
    function transferOwnership(address newOwner) public virtual override {
        ContractOwnershipStorage.layout().transferOwnership(_msgSender(), newOwner);
    }
}