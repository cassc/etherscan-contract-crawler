// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ClonesWithImmutableArgs} from "clones-with-immutable-args/ClonesWithImmutableArgs.sol";
import {MerklePropertyChecker} from "./MerklePropertyChecker.sol";
import {RangePropertyChecker} from "./RangePropertyChecker.sol";

contract PropertyCheckerFactory {
    using ClonesWithImmutableArgs for address;

    event NewMerklePropertyChecker(address indexed a, bytes32 indexed root);
    event NewRangePropertyChecker(address indexed a, uint256 indexed startInclusive, uint256 indexed endInclusive);

    MerklePropertyChecker immutable merklePropertyCheckerImplementation;
    RangePropertyChecker immutable rangePropertyCheckerImplementation;

    constructor(
        MerklePropertyChecker _merklePropertyCheckerImplementation,
        RangePropertyChecker _rangePropertyCheckerImplementation
    ) {
        merklePropertyCheckerImplementation = _merklePropertyCheckerImplementation;
        rangePropertyCheckerImplementation = _rangePropertyCheckerImplementation;
    }

    function createMerklePropertyChecker(bytes32 root) public returns (MerklePropertyChecker) {
        bytes memory data = abi.encodePacked(root);
        MerklePropertyChecker checker = MerklePropertyChecker(address(merklePropertyCheckerImplementation).clone(data));
        emit NewMerklePropertyChecker(address(checker), root);
        return checker;
    }

    function createRangePropertyChecker(uint256 startInclusive, uint256 endInclusive)
        public
        returns (RangePropertyChecker)
    {
        bytes memory data = abi.encodePacked(startInclusive, endInclusive);
        RangePropertyChecker checker = RangePropertyChecker(address(rangePropertyCheckerImplementation).clone(data));
        emit NewRangePropertyChecker(address(checker), startInclusive, endInclusive);
        return checker;
    }
}