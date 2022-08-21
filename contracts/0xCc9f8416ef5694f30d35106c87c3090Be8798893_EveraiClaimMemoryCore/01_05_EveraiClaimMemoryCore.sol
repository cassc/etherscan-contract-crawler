// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IEveraiMemoryCore {
    function mint(address to, uint256 quantity) external;
}

contract EveraiClaimMemoryCore is Ownable {
    using SafeMath for uint256;

    IEveraiMemoryCore public memoryCore;
    bytes32 public merkleRoot;
    mapping(address => uint256) public claimed;

    event Claim(uint256 _id);

    constructor(address memoryCoreAddress) {
        memoryCore = IEveraiMemoryCore(memoryCoreAddress);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "the caller is another contract");
        _;
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function _leaf(address account, uint256 amount)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, amount));
    }

    function claim(
        uint256 id, // merkleTreeId
        bytes32[] calldata proof,
        uint256 quantity,
        uint256 allowance
    ) external callerIsUser {
        require(
            claimed[msg.sender].add(quantity) <= allowance,
            "reached max allowance"
        );

        require(
            _verify(_leaf(msg.sender, allowance), proof),
            "invalid merkle proof"
        );

        claimed[msg.sender] = claimed[msg.sender].add(quantity);
        memoryCore.mint(msg.sender, quantity);
        emit Claim(id);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setClaimed(address addr, uint256 value) external onlyOwner {
        claimed[addr] = value;
    }
}