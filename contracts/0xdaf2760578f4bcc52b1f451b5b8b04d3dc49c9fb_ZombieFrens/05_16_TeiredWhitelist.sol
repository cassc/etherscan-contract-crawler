// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @author tempest-sol
abstract contract TeiredWhitelist {

    enum WhitelistTeir {
        INACTIVE,
        OG,
        OG_OG,
        CONCLUDED
    }

    WhitelistTeir public currentWhitelistSale;

    mapping(address => uint8) public claimedWhitelistMints;

    mapping(WhitelistTeir => bytes32) public merkleRoots;

    mapping(WhitelistTeir => uint8) public teiredWhitelistMintAmount;

    event WhitelistMerkleRootUpdated(WhitelistTeir teir, bytes32 oldMerkleRoot, bytes32 newMerkleRoot);

    event WhitelistSaleChanged(WhitelistTeir oldTeir, WhitelistTeir newTeir);

    event WhitelistClaimed(address claimee, uint8 amount);

    constructor() {
        teiredWhitelistMintAmount[WhitelistTeir.OG] = 3;
        teiredWhitelistMintAmount[WhitelistTeir.OG_OG] = 5;
    }

    function getClaimableAmount(WhitelistTeir teir) public view returns (uint8 amount) {
        uint8 mintable = teiredWhitelistMintAmount[teir];
        uint8 claimed = claimedWhitelistMints[msg.sender];
        amount = mintable > claimed ? mintable - claimed : 0;
    }

    function _claimWhitelist(bytes32[] calldata merkleProof, uint8 amount) internal virtual _canMintWhitelist(merkleProof, amount) {
        claimedWhitelistMints[msg.sender] += amount;
    }

    function updateWhitelistMerkle(WhitelistTeir teir, bytes32 _merkleRoot) external {
        require(teir > WhitelistTeir.INACTIVE && teir <= WhitelistTeir.OG_OG, "invalid_whitelist_teir");
        require(_merkleRoot != 0x0, "invalid_merkle_root");
        bytes32 currentRoot = merkleRoots[teir];
        merkleRoots[teir] =_merkleRoot;

        emit WhitelistMerkleRootUpdated(teir, currentRoot, _merkleRoot);
    }

    function whitelistData(bytes32[] calldata _merkleProof) private view returns (WhitelistTeir teir, bool valid) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        valid = MerkleProof.verify(_merkleProof, merkleRoots[currentWhitelistSale], leaf);
        teir = currentWhitelistSale;
    }

    modifier _canMintWhitelist(bytes32[] calldata merkleProof, uint8 amount) {
        (WhitelistTeir teir, bool isValid) = whitelistData(merkleProof);
        require(isValid, "not_whitelisted");
        uint8 claimable = getClaimableAmount(teir);
        require(amount > 0 && amount <= claimable, "amount_exceeds_claimable");
        _;
    }

}