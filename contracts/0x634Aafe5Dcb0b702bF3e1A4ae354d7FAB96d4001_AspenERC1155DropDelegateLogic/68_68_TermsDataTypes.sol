// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

interface TermsDataTypes {
    /**
     *  @notice The criteria that make up terms.
     *
     *  @param termsActivated       Indicates whether the terms are activated or not.
     *
     *  @param termsVersion         The version of the terms.
     *
     *  @param termsURI             The URI of the terms.
     *
     *  @param acceptedVersion      Mapping with the address of the acceptor and the version of the terms accepted.
     *
     *  @param termsAccepted        Mapping with the address of the acceptor and the status of the terms accepted.
     *
     */
    struct Terms {
        bool termsActivated;
        uint8 termsVersion;
        string termsURI;
        mapping(address => uint8) acceptedVersion;
        mapping(address => bool) termsAccepted;
    }
}