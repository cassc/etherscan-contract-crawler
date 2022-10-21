// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library GluwacoinModels {
    /**
     * @dev Enum of the different domains of signature.
     */
    enum SigDomain {
        /*0*/
        Nothing,
        /*1*/
        Burn,
        /*2*/
        Mint,
        /*3*/
        Transfer,
        /*4*/
        Reserve
    }
}