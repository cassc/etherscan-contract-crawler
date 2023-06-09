// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IBlockverse.sol";
import "./interfaces/IBlockverseStaking.sol";
import "./interfaces/IBlockverseMetadata.sol";

contract Blockverse is IBlockverse, ERC721Enumerable, Ownable, ReentrancyGuard {
    using MerkleProof for bytes32[];

    IBlockverseStaking staking;
    IBlockverseMetadata metadata;

    uint256 public constant price = 0.05 ether;
    uint256 constant mintLimit = 4;
    uint256 constant presaleMintLimit = 3;
    uint256 constant supplyLimit = 10000;
    bytes32 whitelistMerkelRoot;

    // Sale Stages
    // 0 - Nothing enabled
    // 1 - Whitelist
    // 2 - Public sale
    uint8 public saleStage = 0;

    mapping(address => uint256) public minted;
    mapping(address => BlockverseFaction) public walletAssignedMintFaction;
    mapping(BlockverseFaction => uint256) public mintedByFaction;
    mapping(uint256 => BlockverseFaction) public tokenFaction;

    constructor() ERC721("Blockverse", "BLCK")  {}

    // MINT
    function remainingMint(address user) public view returns (uint256) {
        return (saleStage == 1 ? presaleMintLimit : mintLimit) - minted[user];
    }

    function mint(uint256 num, bool autoStake) external override payable nonReentrant requireContractsSet {
        uint256 supply = totalSupply();
        require(tx.origin == _msgSender(), "Only EOA");
        require(saleStage == 2 || _msgSender() == owner(), "Sale not started");
        require(remainingMint(_msgSender()) >= num || _msgSender() == owner(), "Hit mint limit");
        require(supply + num < supplyLimit, "Exceeds maximum supply");
        require(msg.value >= price * num || _msgSender() == owner(), "Ether sent is not correct");
        require(num > 0, "Can't mint 0");

        if (walletAssignedMintFaction[_msgSender()] == BlockverseFaction.UNASSIGNED) {
            BlockverseFaction minFaction = BlockverseFaction.APES;
            uint256 minCount = mintedByFaction[minFaction];

            for (uint256 i = 1; i <= uint256(BlockverseFaction.ALIENS); i++) {
                uint256 iCount = mintedByFaction[BlockverseFaction(i)];
                if (iCount < minCount) {
                    minFaction = BlockverseFaction(i);
                    minCount = iCount;
                }
            }

            walletAssignedMintFaction[_msgSender()] = minFaction;
        }

        minted[_msgSender()] += num;
        mintedByFaction[walletAssignedMintFaction[_msgSender()]] += num;

        for (uint256 i; i < num; i++) {
            address recipient = autoStake && i == 0 ? address(staking) : _msgSender();
            _safeMint(recipient, supply + i + 1);
            tokenFaction[supply + i + 1] = walletAssignedMintFaction[_msgSender()];
        }

        if (autoStake && staking.stakedByUser(_msgSender()) == 0) {
            staking.stake(_msgSender(), supply + 1);
        }
    }

    function whitelistMint(uint256 num, bytes32[] memory proof, bool autoStake) external override payable nonReentrant requireContractsSet {
        uint256 supply = totalSupply();
        require(tx.origin == _msgSender(), "Only EOA");
        require(saleStage == 1 || _msgSender() == owner(), "Pre-sale not started or has ended");
        require(remainingMint(_msgSender()) >= num, "Hit mint limit");
        require(supply + num < supplyLimit, "Exceeds maximum supply");
        require(msg.value >= num * price, "Ether sent is not correct");
        require(whitelistMerkelRoot != 0, "Whitelist not set");
        require(
            proof.verify(whitelistMerkelRoot, keccak256(abi.encodePacked(_msgSender()))),
            "You aren't whitelisted"
        );
        require(num > 0, "Can't mint 0");

        minted[_msgSender()] += num;

        for (uint256 i; i < num; i++) {
            address recipient = autoStake ? address(staking) : _msgSender();
            _safeMint(recipient, supply + i + 1);
            tokenFaction[supply + i + 1] = walletAssignedMintFaction[_msgSender()];
        }

        if (autoStake) {
            staking.stake(_msgSender(), supply + 1);
        }
    }

    // UI LINK/METADATA
    function walletOfUser(address user) public view override returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(user);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(user, i);
        }
        return tokensId;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return metadata.tokenURI(tokenId, tokenFaction[tokenId]);
    }

    function getTokenFaction(uint256 tokenId) external view override returns (BlockverseFaction) {
        return tokenFaction[tokenId];
    }

    // ADMIN
    function setSaleStage(uint8 val) public onlyOwner {
        saleStage = val;
    }

    function setWhitelistRoot(bytes32 val) public onlyOwner {
        whitelistMerkelRoot = val;
    }

    function withdrawAll(address payable a) public onlyOwner {
        a.transfer(address(this).balance);
    }

    // ALLOW STAKING TO MODIFY
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) {
        // allow admin contracts to be send without approval
        if(_msgSender() != address(staking) && _msgSender() != owner()) {
            require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        }
        _transfer(from, to, tokenId);
    }

    // SETUP
    modifier requireContractsSet() {
        require(address(staking) != address(0) && address(metadata) != address(0)
        , "Contracts not set");
        _;
    }

    function setContracts(address _staking, address _metadata) external onlyOwner {
        staking = IBlockverseStaking(_staking);
        metadata = IBlockverseMetadata(_metadata);
    }
}