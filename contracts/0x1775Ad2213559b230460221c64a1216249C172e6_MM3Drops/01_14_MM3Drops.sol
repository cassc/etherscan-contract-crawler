// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@divergencetech/ethier/contracts/utils/OwnerPausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IMM {
    function totalSupply() external view returns (uint256);

    function mint(address to, uint256 tokenId) external;
}

contract MM3Drops is OwnerPausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    Counters.Counter private _tokenIdTracker;

    address payable public beneficiary;

    bytes32 public merkleRootHash;

    uint256 public allowListMintTime;
    uint256 public allowListMaxNum;
    uint256 public singlePriceForAllowList;
    uint256 public publicMintTime;
    uint256 public publicMaxNum;
    uint256 public singlePriceForPublicSale;

    uint256 public ogMaxNum;

    mapping(address => bool) public proofClaimed;

    uint256 public constant MaxAvailable = 6226;

    IMM private immutable MM;

    constructor(address mm) {
        MM = IMM(mm);
        beneficiary = payable(0x7D7Fdd631D04a60b1d349CE55de74459e70C099D);
        merkleRootHash = 0x0d6ff6c4956bd7e00cb07050653721580e5164f7e2e136e6b0e37034413e34b8;

        allowListMintTime = 1659441600;
        allowListMaxNum = 2;
        singlePriceForAllowList = 0.15 ether;

        publicMintTime = 1661907600;
        publicMaxNum = 5;
        singlePriceForPublicSale = 0.25 ether;

        ogMaxNum = 109;
    }

    function setBeneficiary(address payable _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    function setMerkleRootHash(bytes32 _hash) public onlyOwner {
        merkleRootHash = _hash;
    }

    function setPublicMint(
        uint256 mintTime,
        uint256 num,
        uint256 price
    ) public onlyOwner {
        publicMintTime = mintTime;
        publicMaxNum = num;
        singlePriceForPublicSale = price;
    }

    function setAllowListMint(
        uint256 mintTime,
        uint256 num,
        uint256 price,
        uint256 maxNum
    ) public onlyOwner {
        allowListMintTime = mintTime;
        allowListMaxNum = num;
        singlePriceForAllowList = price;
        ogMaxNum = maxNum;
    }

    function mintPublic(uint256 num) external payable whenNotPaused nonReentrant {
        require(tx.origin == msg.sender, "only EOA");
        require(block.timestamp >= publicMintTime && publicMintTime > 0, "not start yet");
        require(publicMaxNum == 0 || num <= publicMaxNum, "invalid mint num");
        require(MM.totalSupply() + num <= MaxAvailable, "insufficient remaining");
        require(msg.value == num * singlePriceForPublicSale, "fund not enough");

        Address.sendValue(beneficiary, msg.value);

        for (uint256 i = 0; i < num; i++) {
            _tokenIdTracker.increment();
            MM.mint(msg.sender, _tokenIdTracker.current());
        }
    }

    function mintAllowList(uint256 num, bytes32[] calldata proof) external payable whenNotPaused nonReentrant {
        require(tx.origin == msg.sender, "only EOA");
        require(!proofClaimed[msg.sender], "already proof minted");
        require(block.timestamp >= allowListMintTime && allowListMintTime > 0, "not start yet");
        require(allowListMaxNum == 0 || num <= allowListMaxNum, "invalid mint num");
        require(ogMaxNum == 0 || MM.totalSupply() + num <= ogMaxNum, "insufficient og remaining");
        require(MM.totalSupply() + num <= MaxAvailable, "insufficient remaining");
        require(msg.value == num * singlePriceForAllowList, "fund not enough");
        require(MerkleProof.verify(proof, merkleRootHash, keccak256(abi.encodePacked(_msgSender()))), "invalid proof");

        proofClaimed[msg.sender] = true;
        Address.sendValue(beneficiary, msg.value);

        for (uint256 i = 0; i < num; i++) {
            _tokenIdTracker.increment();
            MM.mint(msg.sender, _tokenIdTracker.current());
        }
    }
}