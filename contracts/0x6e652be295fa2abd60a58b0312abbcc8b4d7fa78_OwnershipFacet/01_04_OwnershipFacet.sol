// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {LibDiamond} from "src/libraries/diamond-core/LibDiamond.sol";
import {IERC173} from "src/interfaces/access/IERC173.sol";

/**
 * @title OwnershipFacet
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * @notice Required ownership management to support EIP-2535
 */
contract OwnershipFacet is IERC173 {
    /**
     * @notice Transfers ownership of the diamond to the provided owner
     *
     * @dev    Throws if caller is not the current owner
     *
     * @dev    <h4>Postconditions</h4>
     * @dev    1. The provided address is the new owner
     * @dev    2. The previous owner is no longer the owner
     *
     * @param  _newOwner address of the new owner
     */
    function transferOwnership(address _newOwner) external override {
        LibDiamond.requireContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    /// @notice Returns the current owner of the diamond
    function owner() external view override returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}