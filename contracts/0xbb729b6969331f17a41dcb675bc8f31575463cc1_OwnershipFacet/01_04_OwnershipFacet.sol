// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

// Diamond imports
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { IERC173 } from "../interfaces/IERC173.sol";

/**************************************

    Ownership facet

    ------------------------------

    @author Nick Mudge

 **************************************/

/// @notice Ownership facet for Diamond Proxy.
contract OwnershipFacet is IERC173 {
    // -----------------------------------------------------------------------
    //                              External
    // -----------------------------------------------------------------------

    /**************************************

        Transfer ownership

     **************************************/

    /// @dev Transfer ownership to another user.
    /// @dev Validation: can be called only by current owner.
    /// @param _newOwner address of new owner
    function transferOwnership(address _newOwner) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    /**************************************

        Get owner

     **************************************/

    /// @dev Return current owner of diamond.
    /// @return owner_ current owner address
    function owner() external view override returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}