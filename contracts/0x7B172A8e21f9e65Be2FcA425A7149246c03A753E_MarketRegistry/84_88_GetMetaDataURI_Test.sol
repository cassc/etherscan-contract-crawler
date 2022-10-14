// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@mangrovedao/hardhat-test-solidity/test.sol";

import "./Testable.sol";
import "../TellerV2.sol";

contract GetMetaDataURI_Test is Testable, TellerV2 {
    constructor() TellerV2(address(0)) {}

    function setup_beforeAll() public {
        // Old depreciated _metadataURI on bid struct
        bids[0]
            ._metadataURI = 0x0000000000000000000000000000000086004f3f419f88be1cab574b4bd01b6d;
        // New metadataURI from uris mapping
        uris[59] = "ipfs://QmMyDataHash";
    }

    function getMetaDataURI_test() public {
        string memory oldURI = getMetadataURI(0);
        Test.eq(
            oldURI,
            "0x0000000000000000000000000000000086004f3f419f88be1cab574b4bd01b6d",
            "Expected URI does not match stored depreciated value in the Bid struct"
        );
        string memory newURI = getMetadataURI(59);
        Test.eq(
            newURI,
            "ipfs://QmMyDataHash",
            "Expected URI does not match new value in uri mapping"
        );
    }
}