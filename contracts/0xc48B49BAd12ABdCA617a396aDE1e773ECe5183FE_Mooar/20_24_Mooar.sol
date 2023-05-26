// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./TransferHelper.sol";
import "./MooarNFT.sol";
import "./MooarVault.sol";


contract Mooar is AccessControl {
    struct MooarSeason {
        address voteToken;
        address vault;
        bytes32 secret;
        bytes32 revealKey;
        bytes32 refundMerkleRoot;
        uint256 voteStartingTime;
        uint256 voteEndingTime;
        uint256 redeemRefundTime;
        uint256 unitPrice;
        uint256 addressMaxVotingCost;
    }

    struct NFTInfo {
        address creator;
        bytes32 seasonId;
        uint32  maxSupply;
        uint256 votingCost;
        uint256 creatorFund;
    }

    struct NFTLaunchResult {
        bool isMooarLaunched;
        address nftAddress;
        bytes32 nftMerkleRoot;
        uint256 creatorFund;
    }

    struct Vote {
        address voter;
        bytes32 votingSecret;
        uint256 votingFee;
    }

    mapping(bytes32 => MooarSeason) public Seasons;
    mapping(address => NFTInfo) public NFTs;
    mapping(bytes32 => address) public cidNFTAddresses;

    mapping(bytes32 => Vote[]) public seasonVotes;
    mapping(bytes32 => mapping(address => uint256)) public seasonVoterCost;
    mapping(bytes32 => mapping(address => bool)) public seasonVoterRefunded;

    bytes32 public constant NFT_MANAGER = keccak256("NFT_MANAGER");

    event InitSeasonEvent(address indexed vault);
    event InitNFTEvent(address indexed nft);
    event VoteEvent(address indexed voter, bytes32 indexed seasonId, bytes32 votingSecret, uint256 votingFee);
    event RefundEvent(address indexed voter, bytes32 indexed seasonId, uint256 refundAmount);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(NFT_MANAGER, msg.sender);
    }

    function grantRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    function initSeason(
        address voteToken,
        bytes32 seasonId,
        bytes32 secret,
        uint256 voteStartingTime,
        uint256 voteEndingTime,
        uint256 unitPrice,
        uint256 addressMaxVotingCost)
    external onlyRole(NFT_MANAGER) {
        require(block.timestamp < voteStartingTime && voteStartingTime < voteEndingTime, "Invalid season duration");
        require(Seasons[seasonId].secret == bytes32(0), "Season already exists");
        require(unitPrice > 0 && addressMaxVotingCost > 0, "Invalid unitPrice or addressMaxVotingCost");

        address vault = address(new MooarVault());
        Seasons[seasonId] = MooarSeason(
            voteToken,
            vault,
            secret,
            bytes32(0),
            bytes32(0),
            voteStartingTime,
            voteEndingTime,
            0,
            unitPrice,
            addressMaxVotingCost);
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
        uint256 votingCost,
        uint256 directMintETHCost,
        address directMintBaseToken,
        uint256 directMintCost,
        uint32 nftMaxSupply)
    external {
        MooarSeason memory season = Seasons[seasonId];
        require(cidNFTAddresses[collectionId] == address(0), "Exist collectionId");
        require(block.timestamp < season.voteStartingTime, "Invalid season time");
        require(votingCost >= season.unitPrice, "Invalid cost");
        require(nftCreator != address(0), "Invalid creator");
        require(nftMaxSupply > 0, "Invalid nft max supply");

        address newNFT = address(new MooarNFT(name, symbol, baseURI, tokenSuffix, nftMaxSupply, directMintETHCost, directMintBaseToken, directMintCost));
        require(NFTs[newNFT].creator == address(0), "Exist NFT");

        NFTs[newNFT] = NFTInfo(nftCreator, seasonId, nftMaxSupply, votingCost, 0);
        cidNFTAddresses[collectionId] = newNFT;

        emit InitNFTEvent(newNFT);
    }

    function getNFTCreator(address nft) external view returns(address) {
        return NFTs[nft].creator;
    }

    function getVault(bytes32 seasonId) external view returns(address) {
        return Seasons[seasonId].vault;
    }

    function getVotesCount(bytes32 seasonId) external view returns(uint256) {
        return seasonVotes[seasonId].length;
    }

    function getVotes(bytes32 seasonId, uint32 offset, uint32 step, Vote[] memory results)
    external view returns(Vote[] memory) {
        for (uint32 i=0; i<step; i++) {
            results[i] = seasonVotes[seasonId][i+offset];
        }
        return results;
    }

    function vote(bytes32 seasonId, bytes32 votingSecret, uint256 votingCost) external {
        MooarSeason memory season = Seasons[seasonId];
        address voter = _msgSender();

        require(block.timestamp >= season.voteStartingTime && block.timestamp < season.voteEndingTime, "Out of vote duration");
        require(votingCost >= season.unitPrice, "Invalid voting cost");

        TransferHelper.safeTransferFrom(
            season.voteToken,
            voter,
            season.vault,
            votingCost
        );

        seasonVotes[seasonId].push(Vote(voter, votingSecret, votingCost));
        seasonVoterCost[seasonId][voter] += votingCost;
        require(seasonVoterCost[seasonId][voter] <= season.addressMaxVotingCost, "Out of max voting cost");

        emit VoteEvent(voter, seasonId, votingSecret, votingCost);
    }

    function reveal(
        bytes32 seasonId,
        bytes32 revealKey,
        bytes32 refundMerkleRoot,
        uint256 redeemRefundTime,
        uint256 unfreezeMintTime,
        uint256 priorityMintTime,
        uint256 directMintTime,
        NFTLaunchResult[] calldata nftLaunchResults) external onlyRole(NFT_MANAGER) {
        {
            MooarSeason memory season = Seasons[seasonId];
            require(block.timestamp >= season.voteEndingTime, "Vote duration not end");
            require(keccak256(abi.encodePacked(revealKey)) == season.secret, "Invalid reveal key");
            Seasons[seasonId].revealKey = revealKey;
            Seasons[seasonId].refundMerkleRoot = refundMerkleRoot;
            Seasons[seasonId].redeemRefundTime = redeemRefundTime;
        }

        for (uint32 i=0; i<nftLaunchResults.length; i++) {
            address nftAddress = nftLaunchResults[i].nftAddress;
            NFTInfo memory nftInfo = NFTs[nftAddress];
            require(nftInfo.seasonId == seasonId, "Invalid season");
            bytes32 nftMerkleRoot = nftLaunchResults[i].nftMerkleRoot;
            if (nftLaunchResults[i].creatorFund != 0) {
                NFTs[nftAddress].creatorFund = nftLaunchResults[i].creatorFund;
            }
            if (nftLaunchResults[i].isMooarLaunched) {
                MooarNFT(nftAddress).setMooarLaunch(nftMerkleRoot, redeemRefundTime, unfreezeMintTime);
            } else {
                MooarNFT(nftAddress).setMooarUnlaunch(nftMerkleRoot, priorityMintTime, directMintTime);
            }
            MooarNFT(nftAddress).transferOwnership(nftInfo.creator);
        }
    }

    function refund(
        bytes32 seasonId,
        uint256 refundFee,
        bytes32[] calldata proof)
    external {
        address voter = _msgSender();
        MooarSeason memory season = Seasons[seasonId];

        require(season.revealKey != bytes32(0), "Not revealed");
        require(block.timestamp >= season.redeemRefundTime, "Invalid redeem&refund time");
        require(seasonVoterRefunded[seasonId][voter] != true, "Fee refunded");
        seasonVoterRefunded[seasonId][voter] = true;

        bytes32 leaf = keccak256(abi.encodePacked(voter, refundFee));
        require(MerkleProof.verify(proof, season.refundMerkleRoot, leaf) == true, "Invalid merkle verify");

        MooarVault(season.vault).withdraw(voter, season.voteToken, refundFee);
        emit RefundEvent(voter, seasonId, refundFee);
    }

    function collectFund(bytes32 seasonId, address nft) external {
        MooarSeason memory season = Seasons[seasonId];
        NFTInfo memory nftInfo = NFTs[nft];
        require(seasonId != bytes32(0) && seasonId == nftInfo.seasonId && nftInfo.creatorFund > 0, "Invalid refund");

        NFTs[nft].creatorFund = 0;
        MooarVault(season.vault).withdraw(nftInfo.creator, season.voteToken, nftInfo.creatorFund);
    }
}