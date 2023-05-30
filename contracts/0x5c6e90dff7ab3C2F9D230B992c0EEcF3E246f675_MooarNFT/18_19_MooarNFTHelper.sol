// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

struct MooarNFTLaunchStatus {
    bool isMooarLaunched;
    bool isMooarUnlaunched;

    bytes32 tokenMerkleRoot;
    uint256 redeemMintStartTime;
    uint256 unfreezeMintStartTime;

    bytes32 priorityMerkleRoot;
    uint256 priorityMintStartTime;
    uint256 directMintStartTime;
}

library MooarNFTHelper {
    
    function onlyRedeemMinting(MooarNFTLaunchStatus storage self) public view {
        require(self.isMooarLaunched, "Only for mooar launched NFT");
        require(self.redeemMintStartTime > 0 && block.timestamp >= self.redeemMintStartTime, "Not redeem minting");
    }

    function onlyUnfreezeMinting(MooarNFTLaunchStatus storage self) public view {
        require(self.isMooarLaunched, "Only for mooar launched NFT");
        require(self.unfreezeMintStartTime > 0 && block.timestamp >= self.unfreezeMintStartTime, "Not unfreeze minting");
    }

    function onlyPriorityMinting(MooarNFTLaunchStatus storage self) private view {
        require(self.isMooarUnlaunched, "Only for mooar unlaunched NFT");
        require(self.priorityMintStartTime > 0 && block.timestamp >= self.priorityMintStartTime && block.timestamp < self.directMintStartTime, "Not priority minting");
    }
    
    function onlyDirectMinting(MooarNFTLaunchStatus storage self) private view {
        require(self.isMooarUnlaunched, "Only for mooar unlaunched NFT");
        require(self.directMintStartTime > 0 && block.timestamp >= self.directMintStartTime, "Not direct minting");
    }

    function onlyMintByETH(uint256 ethMintCost) private view {
        require(ethMintCost > 0, "Can't mint by ETH");
        require(msg.value == ethMintCost, "Invalid ETH value");
    }

    function onlyMintByToken(address tokenMintBaseToken, uint256 tokenMintCost) private pure {
        require(tokenMintBaseToken != address(0), "Can't mint by token");
        require(tokenMintCost > 0, "Can't mint by token");
    }
    
    function verifyTokenMerkleProof(address account, bytes32 tokenMerkleRoot, uint256 tokenId, bytes32[] calldata merkleProof) internal pure {
        require(tokenMerkleRoot != bytes32(0), "No merkle root");
        bytes32 node = keccak256(abi.encodePacked(tokenId, account));
        require(MerkleProof.verify(merkleProof, tokenMerkleRoot, node) == true, "Fail to verify proof");
    }

    function verifyAccountMerkleProof(address account, bytes32 accountMerkleRoot, bytes32[] calldata merkleProof) internal pure {
        require(accountMerkleRoot != bytes32(0), "No priority merkle root");
        bytes32 node = keccak256(abi.encodePacked(account));
        require(MerkleProof.verify(merkleProof, accountMerkleRoot, node) == true, "Fail to verify proof");
    }

    function verifyRedeemMint(address account, MooarNFTLaunchStatus storage status, uint256 tokenId, bytes32[] calldata merkleProof) public view {
        onlyRedeemMinting(status);
        verifyTokenMerkleProof(account, status.tokenMerkleRoot, tokenId, merkleProof);
    }

    function verifyUnfreezeMintByETH(uint256 ethMintCost, MooarNFTLaunchStatus storage status, uint256 tokenId, bytes32[] calldata merkleProof) public view {
        onlyUnfreezeMinting(status);
        onlyMintByETH(ethMintCost);
        verifyTokenMerkleProof(address(0), status.tokenMerkleRoot, tokenId, merkleProof);
    }

    function verifyUnfreezeMintByToken(address tokenMintBaseToken, uint256 tokenMintCost, MooarNFTLaunchStatus storage status, uint256 tokenId, bytes32[] calldata merkleProof) public view {
        onlyUnfreezeMinting(status);
        onlyMintByToken(tokenMintBaseToken, tokenMintCost);
        verifyTokenMerkleProof(address(0), status.tokenMerkleRoot, tokenId, merkleProof);
    }

    function verifyPriorityMintByETH(address account, uint256 ethMintCost, MooarNFTLaunchStatus storage status, bytes32[] calldata merkleProof) public view {
        onlyPriorityMinting(status);
        onlyMintByETH(ethMintCost);
        verifyAccountMerkleProof(account, status.priorityMerkleRoot, merkleProof);
    }

    function verifyPriorityMintByToken(address account, address tokenMintBaseToken, uint256 tokenMintCost, MooarNFTLaunchStatus storage status, bytes32[] calldata merkleProof) public view {
        onlyPriorityMinting(status);
        onlyMintByToken(tokenMintBaseToken, tokenMintCost);
        verifyAccountMerkleProof(account, status.priorityMerkleRoot, merkleProof);
    }

    function verifyDirectMintByETH(uint256 ethMintCost, MooarNFTLaunchStatus storage status) public view {
        onlyDirectMinting(status);
        onlyMintByETH(ethMintCost);
    }

    function verifyDirectMintByToken(address tokenMintBaseToken, uint256 tokenMintCost, MooarNFTLaunchStatus storage status) public view {
        onlyDirectMinting(status);
        onlyMintByToken(tokenMintBaseToken, tokenMintCost);
    }
}