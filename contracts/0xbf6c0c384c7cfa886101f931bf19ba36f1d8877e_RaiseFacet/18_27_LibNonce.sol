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

/**************************************

    Nonce library

    ------------------------------

    Diamond storage containing nonces

 **************************************/

/// @notice Library implementing NonceStorage and functions.
library LibNonce {
    // -----------------------------------------------------------------------
    //                              Storage pointer
    // -----------------------------------------------------------------------

    /// @dev Storage pointer.
    bytes32 constant NONCE_STORAGE_POSITION = keccak256("angelblock.fundraising.nonce");

    // -----------------------------------------------------------------------
    //                              Structs
    // -----------------------------------------------------------------------

    /// @dev Nonce diamond storage.
    /// @param nonces Mapping of address to nonce information.
    struct NonceStorage {
        mapping(address => uint256) nonces;
    }

    // -----------------------------------------------------------------------
    //                              Diamond storage
    // -----------------------------------------------------------------------

    /// @dev Function returning nonce storage at storage pointer slot.
    /// @return ns NonceStorage struct instance at storage pointer position
    function nonceStorage() internal pure returns (NonceStorage storage ns) {
        // declare position
        bytes32 position = NONCE_STORAGE_POSITION;

        // set slot to position
        assembly {
            ns.slot := position
        }

        // explicit return
        return ns;
    }

    // -----------------------------------------------------------------------
    //                              Nonce section
    // -----------------------------------------------------------------------

    /// @dev Diamond storage getter: nonce per account.
    /// @param _account Address for which nonce should be checked
    /// @return Current nonce of account
    function getLastNonce(address _account) internal view returns (uint256) {
        // return
        return nonceStorage().nonces[_account];
    }

    /// @dev Diamond storage setter: nonce per account.
    /// @param _account Address for which nonce should be set
    /// @param _nonce New value for nonce
    function setNonce(address _account, uint256 _nonce) internal {
        // get storage
        NonceStorage storage ns = nonceStorage();

        // set nonce
        ns.nonces[_account] = _nonce;
    }
}