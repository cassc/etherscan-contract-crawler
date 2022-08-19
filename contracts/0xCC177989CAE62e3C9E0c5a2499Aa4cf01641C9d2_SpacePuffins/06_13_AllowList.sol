// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract AllowList is Context {
    bytes32 private _allowListRoot;

    event AllowListRootUpdated(bytes32 newRoot);

    function _setAllowListRoot(bytes32 allowListRoot) internal {
      _allowListRoot = allowListRoot;
      emit AllowListRootUpdated(_allowListRoot);
    }

    function verify(bytes32[] calldata proof, address address_)
        public
        view
        returns (bool)
    {
        bytes32 hashedAddress = keccak256(abi.encodePacked(address_)); 
        return MerkleProof.verify(proof, _allowListRoot, hashedAddress);
    } 

    modifier onlyAllowList(bytes32[] calldata proof) {
        require(
            verify(proof, _msgSender()),
            "Not on AllowList"
        );
        _;
    }
}