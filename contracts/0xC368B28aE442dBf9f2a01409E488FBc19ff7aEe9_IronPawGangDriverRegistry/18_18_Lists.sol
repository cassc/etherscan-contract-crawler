// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

import {Strings} from "openzeppelin/utils/Strings.sol";
import {MerkleProof} from "openzeppelin/utils/cryptography/MerkleProof.sol";

library Lists {
    using Strings for uint256;

    struct Store {
        mapping(string => bytes32) roots;
        mapping(string => bool) active;
        mapping(bytes32 => uint256) usageCounts;
    }

    function verify(
        Store storage store,
        string calldata list,
        bytes32[] calldata merkleProof,
        address sender,
        uint256 maxAmount
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(sender, maxAmount.toString()));
        return MerkleProof.verify(merkleProof, store.roots[list], leaf);
    }

    function usageCount(Store storage store, string calldata list, address account) internal view returns (uint256) {
        return store.usageCounts[countKey(list, account)];
    }

    function incrementUsageCount(Store storage store, string calldata list, address account, uint256 amount) internal {
        store.usageCounts[countKey(list, account)] += amount;
    }

    function countKey(string calldata list, address account) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(list, account));
    }
}