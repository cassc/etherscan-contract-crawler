// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract Whitelisted {
    bytes32 private _whitelistRoot;

    modifier onlyWhitelisted(address _user, address _contract, bytes32[] calldata merkleProof) {
        bytes32 node = keccak256(abi.encodePacked(_user, _contract));

        require(MerkleProof.verify(merkleProof, _whitelistRoot, node), "You are not whitelisted!");
        _;
    }

    function _setWhitelistRoot(bytes32 root) internal {
        _whitelistRoot = root;
    }

    function getWhitelistRoot() public view returns (bytes32) {
        return _whitelistRoot;
    }

    function isWhitelisted(bytes32[] calldata merkleProof) public view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(msg.sender, address(this)));
        if (MerkleProof.verify(merkleProof, _whitelistRoot, node)) {
            return true;
        } else {
            return false;
        }
    }
}