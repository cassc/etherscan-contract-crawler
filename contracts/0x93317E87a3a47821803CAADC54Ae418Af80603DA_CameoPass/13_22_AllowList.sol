// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleVerifier} from "./MerkleVerifier.sol";
import {IAllowList} from "./IAllowList.sol";

///@notice Smart contract that verifies and tracks allow list redemptions against a configurable Merkle root, up to a max number configured at deploy
contract AllowList is MerkleVerifier, Ownable {
    uint256 public immutable MAX_REDEMPTIONS_PER_ADDRESS;
    bytes32 public merkleRoot;
    mapping(address => uint256) addressRedemptions;

    error NotAllowListed();
    error MaxAllowListRedemptions();

    constructor(uint256 _maxRedemptions, bytes32 _merkleRoot) {
        MAX_REDEMPTIONS_PER_ADDRESS = _maxRedemptions;
        merkleRoot = _merkleRoot;
    }

    ///@notice Checks if msg.sender is included in AllowList, revert otherwise
    ///@param _proof Merkle proof
    modifier onlyAllowListed(bytes32[] calldata _proof) {
        if (!isAllowListed(_proof, msg.sender)) {
            revert NotAllowListed();
        }
        _;
    }

    ///@notice atomically check and increase allowlist redemptions
    ///@param _quantity number of redemptions
    function _ensureAllowListRedemptionsAvailableAndIncrement(uint256 _quantity)
        internal
    {
        // do the modifier stuff here
        if (
            (addressRedemptions[msg.sender] + _quantity) >
            MAX_REDEMPTIONS_PER_ADDRESS
        ) {
            revert MaxAllowListRedemptions();
        }
        unchecked {
            addressRedemptions[msg.sender] += _quantity;
        }
    }

    ///@notice Given a Merkle proof, check if an address is AllowListed against the root
    ///@param _proof Merkle proof
    ///@param _address address to check against allow list
    ///@return boolean isAllowListed
    function isAllowListed(bytes32[] calldata _proof, address _address)
        public
        view
        returns (bool)
    {
        return
            verify(_proof, merkleRoot, keccak256(abi.encodePacked(_address)));
    }

    ///@notice set the Merkle root in the contract. OnlyOwner.
    ///@param _merkleRoot the new Merkle root
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
}