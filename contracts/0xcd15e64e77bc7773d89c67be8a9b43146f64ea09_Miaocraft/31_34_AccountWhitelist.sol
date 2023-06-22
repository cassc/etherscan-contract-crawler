//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract AccountWhitelist is Ownable {
    bytes32 public whitelistMerkleRoot;
    string public whitelistURI;

    /*
  READ FUNCTIONS
  */

    function verifyAccount(address account, bytes32[] memory proof)
        public
        view
        returns (bool)
    {
        return _verify(proof, _hash(account));
    }

    function _verify(bytes32[] memory proof, bytes32 addressHash)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, whitelistMerkleRoot, addressHash);
    }

    function _hash(address _address) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_address));
    }

    /*
  OWNER FUNCTIONS
  */

    function setWhitelist(bytes32 root, string calldata uri)
        external
        onlyOwner
    {
        whitelistMerkleRoot = root;
        whitelistURI = uri;
    }

    /*
  MODIFIER
  */
    modifier onlyWhitelisted(address account, bytes32[] memory proof) {
        require(verifyAccount(account, proof), "Not whitelisted");
        _;
    }
}