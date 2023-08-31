// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IVestable {
    function vest(
        bool vest,
        address _receiver,
        uint256 _amount
    ) external;
}

contract AirDrop is Ownable {
    struct DropInfo {
        bytes32 root;
        uint128 total;
        uint128 remaining;
        bool vest;
    }

    mapping(uint256 => DropInfo) public drops;
    uint256 public tranches;

    mapping(uint256 => mapping(address => bool)) private claimed;
    IVestable public vesting;

    event LogNewDrop(uint256 trancheId, bytes32 merkleRoot, uint128 totalAmount);
    event LogClaim(address indexed account, bool vest, uint256 trancheId, uint128 amount);
    event LogExpireDrop(uint256 trancheId, bytes32 merkleRoot, uint128 totalAmount, uint128 remaining);

    function setVesting(address _vesting) public onlyOwner {
        vesting = IVestable(_vesting);
    }

    function newDrop(
        bytes32 merkleRoot,
        uint128 totalAmount,
        bool vest
    ) external onlyOwner returns (uint256 trancheId) {
        trancheId = tranches;
        DropInfo memory di = DropInfo(merkleRoot, totalAmount, totalAmount, vest);
        drops[trancheId] = di;
        tranches += 1;

        emit LogNewDrop(trancheId, merkleRoot, totalAmount);
    }

    function expireDrop(uint256 trancheId) external onlyOwner {
        require(trancheId < tranches, "expireDrop: !trancheId");
        DropInfo memory di = drops[trancheId];
        delete drops[trancheId];

        emit LogExpireDrop(trancheId, di.root, di.total, di.remaining);
    }

    function isClaimed(uint256 trancheId, address account) public view returns (bool) {
        return claimed[trancheId][account];
    }

    function claim(
        bool vest,
        uint256 trancheId,
        uint128 amount,
        bytes32[] calldata merkleProof
    ) external {
        require(trancheId < tranches, "claim: !trancheId");
        require(!isClaimed(trancheId, msg.sender), "claim: Drop already claimed");
        DropInfo storage di = drops[trancheId];
        bytes32 root = di.root;
        require(root != 0, "claim: Drop expired");
        uint128 remaining = di.remaining;
        require(amount <= remaining, "claim: Not enough remaining");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(msg.sender, amount));
        require(MerkleProof.verify(merkleProof, root, node), "claim: Invalid proof");

        // Mark it claimed and send the token.
        claimed[trancheId][msg.sender] = true;
        di.remaining = remaining - amount;
        if (di.vest) {
            vest = true;
        }
        vesting.vest(vest, msg.sender, amount);

        emit LogClaim(msg.sender, vest, trancheId, amount);
    }

    function verifyDrop(
        uint256 trancheId,
        uint128 amount,
        bytes32[] calldata merkleProof
    ) external view returns (bool) {
        require(trancheId < tranches, "verifyDrop: !trancheId");
        require(!isClaimed(trancheId, msg.sender), "verifyDrop: Drop already claimed");
        DropInfo storage di = drops[trancheId];
        bytes32 root = di.root;
        require(root != 0, "verifyDrop: Drop expired");
        require(amount <= di.remaining, "verifyDrop: Not enough remaining");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(msg.sender, amount));
        return MerkleProof.verify(merkleProof, root, node);
    }
}