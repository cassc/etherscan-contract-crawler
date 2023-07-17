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

// OpenZeppelin
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

// Interfaces
import { Configurable } from "../../utils/Configurable.sol";

/**************************************

    Escrow library

    ------------------------------

    Diamond storage containing escrows data.

 **************************************/

/// @notice Library containing EscrowStorage and low level functions.
library LibEscrow {
    // -----------------------------------------------------------------------
    //                              Constants
    // -----------------------------------------------------------------------

    /// @dev Escrow storage pointer.
    bytes32 constant ESCROW_STORAGE_POSITION = keccak256("angelblock.fundraising.escrow");

    // -----------------------------------------------------------------------
    //                              Events
    // -----------------------------------------------------------------------

    event EscrowCreated(string raiseId, address instance, address source);

    // -----------------------------------------------------------------------
    //                                  Errors
    // -----------------------------------------------------------------------

    error SourceNotSet(); // 0x5646f850

    // -----------------------------------------------------------------------
    //                              Structs
    // -----------------------------------------------------------------------

    /// @dev Escrow diamond storage.
    /// @param source Address of contract with source implementation for cloning Escrows.
    /// @param escrows Mapping of raise id to cloned Escrow instance address.
    struct EscrowStorage {
        address source;
        mapping(string => address) escrows;
    }

    // -----------------------------------------------------------------------
    //                              Diamond storage
    // -----------------------------------------------------------------------

    /// @dev Function returning escrow storage at storage pointer slot.
    /// @return es EscrowStorage struct instance at storage pointer position
    function escrowStorage() internal pure returns (EscrowStorage storage es) {
        // declare position
        bytes32 position = ESCROW_STORAGE_POSITION;

        // set slot to position
        assembly {
            es.slot := position
        }

        // explicit return
        return es;
    }

    // -----------------------------------------------------------------------
    //                              Source section
    // -----------------------------------------------------------------------

    /// @dev Allows to set Escrows source contract address.
    /// @param _source New Escrow source contract address.
    function setSource(address _source) internal {
        // set source address
        escrowStorage().source = _source;
    }

    // -----------------------------------------------------------------------
    //                              Escrow section
    // -----------------------------------------------------------------------

    /// @dev Allows to fetch Escrow address for the given Raise id.
    /// @param _raiseId Id of the Raise.
    /// @return Escrow address.
    function getEscrow(string memory _raiseId) internal view returns (address) {
        // get escrow address
        return escrowStorage().escrows[_raiseId];
    }

    /// @dev Allows to create new Escrow contract.
    /// @dev Events: EscrowCreated(string raiseId, address instance, address source).
    /// @param _raiseId Id of the Raise for which Escrow will be created.
    /// @return escrow_ Newly created Escrow contract address
    function createEscrow(string memory _raiseId) internal returns (address escrow_) {
        // get storage
        EscrowStorage storage es = escrowStorage();

        // get Escrow source address
        address source_ = es.source;

        // validate if source is set
        if (source_ == address(0)) {
            revert SourceNotSet();
        }

        // create new Escrow - clone
        escrow_ = Clones.clone(source_);

        // configure Escrow
        Configurable(escrow_).configure(abi.encode(address(this)));

        // assing created Escrow address for given raise id
        es.escrows[_raiseId] = escrow_;

        // emit
        emit EscrowCreated(_raiseId, escrow_, source_);
    }
}