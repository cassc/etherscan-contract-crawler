// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

library ConceptStruct {
    struct Concept {
        uint256 _editionTokenRangeStart;
        uint256 _editionSize;
        bytes32 _title;
        bytes32[] _bodyText;
        bytes32[] _smallPrintText;
        bytes32[] _statusText;
    }
}