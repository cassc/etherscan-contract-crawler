/**
 *Submitted for verification at Etherscan.io on 2023-04-25
*/

// SPDX-License-Identifier: MIT

// Helper contract to allow Bulk Renewal of Wrapped EtherID Domains.

// Written by Callum Quin @callumquin

pragma solidity ^0.8.0;

interface EtherIDWrapper {
    function renewDomain(uint domain) external;
}

contract EtherIDWrapperBulkRenew {
    EtherIDWrapper wrapperContract;

    constructor(address etherIDWrapperAddress) {
        wrapperContract = EtherIDWrapper(etherIDWrapperAddress);
    }

    function bulkRenew(uint[] calldata domains) public {
        uint length = domains.length;
        for (uint i = 0; i < length; i++) {
            wrapperContract.renewDomain(domains[i]);
        }
    }
}