// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "./ERC721.sol";
import "./Strings.sol";
import "./AccessControl.sol";
import "./IERC20.sol";
import "./MerkleProof.sol";
import {ReentrancyGuard} from "./ReentrancyGuard.sol";

contract MerkleTokenClaimDataManager is ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    using Strings for uint256;

    bytes32 public immutable merkleRoot;
    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimsBitMap;

    constructor(bytes32 _merkleRoot) public {
        merkleRoot = _merkleRoot;
    }

    function verifyAndSetClaimed(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external payable nonReentrant returns (uint256) {
        require(!hasClaimed(index), "Address already claimed.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "Invalid proof.");

        // Mark it claimed and send the token.
        _setClaimed(index);
    }

    function hasClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimsBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimsBitMap[claimedWordIndex] = claimsBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }
}
