// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

/**************************************

    Nonce library

    ------------------------------

    Diamond storage containing nonces

 **************************************/

library LibNonce {

    // storage pointer
    bytes32 constant NONCE_STORAGE_POSITION = keccak256("angelblock.fundraising.nonce");

    // structs: data containers
    struct NonceStorage {
        mapping (address => uint256) nonces;
    }

    // diamond storage getter
    function nonceStorage() internal pure
    returns (NonceStorage storage ns) {

        // declare position
        bytes32 position = NONCE_STORAGE_POSITION;

        // set slot to position
        assembly {
            ns.slot := position
        }

        // explicit return
        return ns;

    }

    // diamond storage getter: nonces
    function getLastNonce(address _account) internal view
    returns (uint256) {

        // return
        return nonceStorage().nonces[_account];

    }

    /**************************************

        Increment nonce

     **************************************/

    function setNonce(address _account, uint256 _nonce) internal {

        // get storage
        NonceStorage storage ns = nonceStorage();

        // set nonce
        ns.nonces[_account] = _nonce;

    }

}