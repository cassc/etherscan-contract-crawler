//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
    @author based upon https://github.com/Uniswap/merkle-distributor
**/
contract SundayClubWhitelist {
    bytes32 public whitelistRoot;

    constructor(bytes32 whitelistRoot_) {
        whitelistRoot = whitelistRoot_;
    }

    function isWhitelisted(address toCheck, bytes32[] calldata proof)
        public
        view
        returns (bool _isWhitelisted)
    {
        bytes32 node = keccak256(abi.encodePacked(toCheck, uint256(1)));
        MerkleProof.verify(proof, whitelistRoot, node)
            ? (_isWhitelisted = true)
            : (_isWhitelisted = false);
        return _isWhitelisted;
    }
}