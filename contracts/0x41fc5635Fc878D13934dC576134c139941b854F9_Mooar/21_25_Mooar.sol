// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./MooarNFTHelper.sol";
import "./MooarNFT.sol";
import "./MooarVault.sol";
import "./TransferHelper.sol";


contract Mooar is AccessControl, ReentrancyGuard {
    using ECDSA for bytes32;

    struct MooarSeason {
        bytes32 secret;
        bytes32 revealKey;
        uint32  unfreezeUpdateNftTime;
        address vault;
    }

    struct NFTInfo {
        address creator;
        bytes32 seasonId;
        uint32  maxSupply;
        uint32  directMintTime;
        uint32  currentMintIdx;
        uint32  currentSupply;
        uint256 nftPrice;
        uint256 creatorFund;
    }

    struct NFTLaunchResult {
        address nftAddress;
        uint32  currentMintIdx;
        uint32  currentSupply;
        uint256 creatorFund;
    }

    mapping(bytes32 => MooarSeason) public Seasons;
    mapping(bytes32 => mapping(address => uint256)) public seasonVoterCost;

    mapping(bytes32 => uint256) private SeasonVotingInfo; // seasonId => (vault,voteEndingTime,voteStartingTime) 
    mapping(bytes32 => uint256) public SeasonRedeemInfo; // seasonId => (vault,redeemStartingTime) 
    mapping(bytes32 => bytes32) public SeasonMerkleRoot;

    mapping(bytes32 => bool) public leafRefunded;

    mapping(address => NFTInfo) public NFTs;
    mapping(bytes32 => address) public cidNFTAddresses;

    bytes32 public constant NFT_MANAGER = keccak256("NFT_MANAGER");
    bytes32 public constant MINT_SIGNER = keccak256("MINT_SIGNER");

    event InitSeasonEvent(address indexed vault);
    event InitNFTEvent(address indexed nft);
    event VoteEvent(address indexed voter, bytes32 indexed seasonId, bytes32 votingSecret, uint256 votingFee);
    event RefundEvent(address indexed voter, bytes32 indexed seasonId, uint256 refundAmount);

    address immutable private _voteToken;
    uint256 immutable private _votingBaseUnit;
    uint256 immutable private _votingMaxCostPerAddress;

    constructor(address voteToken, uint256 votingBaseUnit, uint256 votingMaxCostPerAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(NFT_MANAGER, msg.sender);
        _grantRole(MINT_SIGNER, msg.sender);

        _voteToken = voteToken;
        _votingBaseUnit = votingBaseUnit;
        _votingMaxCostPerAddress = votingMaxCostPerAddress;
    }

    function grantRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    function initSeason(
        bytes32 seasonId,
        bytes32 secret,
        uint32 voteStartingTime,
        uint32 voteEndingTime)
    external onlyRole(NFT_MANAGER) {
        require(block.timestamp < voteStartingTime && voteStartingTime < voteEndingTime, "Invalid season duration");
        require(Seasons[seasonId].secret == bytes32(0), "Season already exists");

        address vault = address(new MooarVault());
        Seasons[seasonId] = MooarSeason(
            secret,
            bytes32(0),
            0,
            vault);

        SeasonVotingInfo[seasonId] = uint256(uint160(vault))<<64 | uint256(voteEndingTime)<<32 | uint256(voteStartingTime);
        emit InitNFTEvent(vault);
    }

    function initNFT(
        bytes32 seasonId,
        bytes32 collectionId,
        string memory name,
        string memory symbol,
        string memory baseURI,
        string memory tokenSuffix,
        address nftCreator,
        uint256 nftPrice,
        uint32 nftMaxSupply)
    external {
        {
            uint32 voteStartingTime = uint32(SeasonVotingInfo[seasonId]);
            require(cidNFTAddresses[collectionId] == address(0), "Exist collectionId");
            require(block.timestamp < voteStartingTime, "Invalid season time");
            require(nftPrice >= _votingBaseUnit 
                && nftCreator != address(0)
                && nftMaxSupply > 0, "Invalid input");
        }

        address newNFT = address(new MooarNFT(name, symbol, baseURI, tokenSuffix, nftMaxSupply));
        require(NFTs[newNFT].creator == address(0), "Exist NFT");

        NFTs[newNFT] = NFTInfo(nftCreator, seasonId, nftMaxSupply, 0, 0, 0, nftPrice, 0);
        cidNFTAddresses[collectionId] = newNFT;

        emit InitNFTEvent(newNFT);
    }

    function getNFTCreator(address nft) external view returns(address) {
        return NFTs[nft].creator;
    }

    function getVault(bytes32 seasonId) external view returns(address) {
        return Seasons[seasonId].vault;
    }

    function vote(bytes32 seasonId, bytes32[] calldata votingSecrets, uint256[] calldata votingCosts) external nonReentrant {
        address voter = _msgSender();

        uint256 votingInfo = SeasonVotingInfo[seasonId];
        address vault = address(uint160(votingInfo >> 64));
        uint32 voteEndingTime = uint32(votingInfo >> 32);
        uint32 voteStartingTime = uint32(votingInfo);

        require(votingInfo != 0 && block.timestamp >= voteStartingTime && block.timestamp < voteEndingTime, "Out of vote duration");
        require(votingSecrets.length == votingCosts.length, "Invalid input");

        uint256 totalVotingCost = 0;

        for (uint32 i=0; i<votingSecrets.length; i++) {         
            uint256 votingCost = votingCosts[i];   
            uint256 tmpTotalCost = totalVotingCost + votingCost;
            require(votingCost >= _votingBaseUnit && tmpTotalCost >= totalVotingCost, "Invalid voting cost");
            totalVotingCost = tmpTotalCost;
            emit VoteEvent(voter, seasonId, votingSecrets[i], votingCost);
        }

        TransferHelper.safeTransferFrom(
            _voteToken,
            voter,
            vault,
            totalVotingCost
        );

        seasonVoterCost[seasonId][voter] += totalVotingCost;
        require(seasonVoterCost[seasonId][voter] <= _votingMaxCostPerAddress, "Out of max voting cost");
    }

    function reveal(
        bytes32 seasonId,
        bytes32 revealKey,
        bytes32 redeemMerkleRoot,
        uint32 redeemTime,
        uint32 unfreezeUpdateNftTime,
        NFTLaunchResult[] calldata nftLaunchResults) external onlyRole(NFT_MANAGER) {
        {
            uint32 voteEndingTime = uint32(SeasonVotingInfo[seasonId] >> 32);
            require(block.timestamp >= voteEndingTime, "Vote duration not end");

            MooarSeason memory season = Seasons[seasonId];
            require(keccak256(abi.encodePacked(revealKey)) == season.secret, "Invalid reveal key");
            Seasons[seasonId].revealKey = revealKey;
            Seasons[seasonId].unfreezeUpdateNftTime = unfreezeUpdateNftTime;
            SeasonRedeemInfo[seasonId] = uint256(uint160(season.vault))<<32 | uint256(redeemTime);
            SeasonMerkleRoot[seasonId] = redeemMerkleRoot;
        }

        for (uint32 i=0; i<nftLaunchResults.length; i++) {
            address nftAddress = nftLaunchResults[i].nftAddress;
            NFTInfo memory nftInfo = NFTs[nftAddress];
            require(nftInfo.seasonId == seasonId, "Invalid season");

            if (nftLaunchResults[i].creatorFund != 0) {
                NFTs[nftAddress].creatorFund = nftLaunchResults[i].creatorFund;
            }
            NFTs[nftAddress].currentMintIdx = nftLaunchResults[i].currentMintIdx;
            NFTs[nftAddress].directMintTime = redeemTime;
            NFTs[nftAddress].currentSupply = nftLaunchResults[i].currentSupply;
            MooarNFT(nftAddress).transferOwnership(nftInfo.creator);
        }
    }

    function collectFund(bytes32 seasonId, address nft) external nonReentrant {
        MooarSeason memory season = Seasons[seasonId];
        NFTInfo memory nftInfo = NFTs[nft];
        require(seasonId != bytes32(0) && seasonId == nftInfo.seasonId && nftInfo.creatorFund > 0, "Invalid refund");

        NFTs[nft].creatorFund = 0;
        MooarVault(season.vault).withdraw(nftInfo.creator, _voteToken, nftInfo.creatorFund);
    }

    function verifyLeaf(
        bytes32 seasonId,
        address voter,
        bytes32 leafId,
        uint256 refundFee,
        address[] calldata nfts,
        uint32[] calldata tokenNums,
        uint32[] calldata tokenIds, 
        bytes32[] calldata proofs) internal view {
        require(MerkleProof.verify(
            proofs, 
            SeasonMerkleRoot[seasonId], 
            keccak256(abi.encodePacked(leafId, voter, refundFee, nfts, tokenNums, tokenIds))) == true, 
            "Invalid merkle verify");
    }

    function redeem(
        bytes32 seasonId,
        bytes32 leafId,
        uint256 refundFee,
        address[] calldata nfts,
        uint32[] calldata tokenNums,
        uint32[] calldata tokenIds, 
        bytes32[] calldata proofs)
    external nonReentrant {
        address voter = _msgSender();

        uint256 redeemInfo = SeasonRedeemInfo[seasonId];
        {
            uint32 redeemTime = uint32(redeemInfo);
            require(redeemInfo > 0 && block.timestamp >= redeemTime, "Invalid redeem time");
            require(nfts.length == tokenNums.length, "Invalid input");
        }
        verifyLeaf(seasonId, voter, leafId, refundFee, nfts, tokenNums, tokenIds, proofs);
        if (refundFee > 0) {
            require(leafRefunded[leafId] != true, "Fee refunded");
            address vault = address(uint160(redeemInfo >> 32));

            MooarVault(vault).withdraw(voter, _voteToken, refundFee);
            leafRefunded[leafId] = true;
            emit RefundEvent(voter, seasonId, refundFee);
        }

        uint32 tokenIdx = 0;
        for (uint32 i=0; i<nfts.length; i++) {
            address nft = nfts[i];
            uint32 tokenNum = tokenNums[i];
            for (uint32 j=0; j<tokenNum; j++) {
                MooarNFT(nft).mooarMint(voter, tokenIds[tokenIdx]);
                tokenIdx++;
            }
        }
    }

    function directMint(
        address nftAddress,
        uint32 mintNum,
        uint256 validBefore,
        bytes memory signature
    ) external nonReentrant {
        require(mintNum > 0 && mintNum <= 10, "Invalid token number");

        address to = _msgSender();
        bytes32 messageHash = keccak256(abi.encodePacked(to, validBefore));
        address signManager = messageHash.toEthSignedMessageHash().recover(signature);
        require(hasRole(MINT_SIGNER, signManager), "Invalid signature");

        require(NFTs[nftAddress].directMintTime > 0 && block.timestamp >= NFTs[nftAddress].directMintTime, "Invalid direct mint time");
        require(NFTs[nftAddress].currentMintIdx + mintNum <= NFTs[nftAddress].currentSupply, "Out of supply");

        uint256 mintCost = NFTs[nftAddress].nftPrice * mintNum;

        // transfer gmt: optimize vault
        TransferHelper.safeTransferFrom(
            _voteToken,
            msg.sender,
            MooarNFT(nftAddress).owner(),
            mintCost
        );

        for (uint32 i=0; i<mintNum; i++) {
            MooarNFT(nftAddress).mooarMint(to, NFTs[nftAddress].currentMintIdx + i);
        }
        NFTs[nftAddress].currentMintIdx = NFTs[nftAddress].currentMintIdx + mintNum;
    }

    function updateNftInfo(address nftAddress, uint32 currentSupply, uint256 votingCost) external {
        NFTInfo memory nftInfo = NFTs[nftAddress];
        require(nftInfo.seasonId != bytes32(0), "Invalid nft");
        MooarSeason memory season = Seasons[nftInfo.seasonId];
        require(season.unfreezeUpdateNftTime > 0 && block.timestamp >= season.unfreezeUpdateNftTime, "Invalid update nft info time");
        require(MooarNFT(nftAddress).owner() == _msgSender(), "Only nft owner can update");
        
        if (currentSupply != 0) {
            require(currentSupply >= nftInfo.currentSupply && currentSupply <= nftInfo.maxSupply, "Invalid current supply");
            NFTs[nftAddress].currentSupply = currentSupply;
        }
        if (votingCost != 0) {
            NFTs[nftAddress].nftPrice = votingCost;
        }
    }
}