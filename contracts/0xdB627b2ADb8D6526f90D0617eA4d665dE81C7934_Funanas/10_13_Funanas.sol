//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./OperatorFilterer.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol"; // ERC2981 NFT Royalty Standard

contract Funanas is
    ERC721A("Funs Pack", "FPCK"),
    Ownable,
    Pausable,
    ERC2981,
    OperatorFilterer
{
    using SafeMath for uint256;

    event PermanentURI(string _value, uint256 indexed _id);

    uint256 public MINT_SESSION_BEGIN = 0;
    bool public overrideTime = false;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public PRICE = 0.0027 ether;
    mapping(address => uint256) MINTED_SNAPSHOT;
    bytes32 public snapshotMerkleRoot =
        0xcd1875e63ecbd6152096ed8b4f1ddf77179f9dd80fffb582e52b085d956b9aa2;
    string public _contractBaseURI;

    constructor(string memory baseURI) {
        _contractBaseURI = baseURI;
        _pause();
        // Set royalty receiver to the contract creator,
        // at 7.5% (default denominator is 10000).
        _setDefaultRoyalty(msg.sender, 750);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function reserveNFTs(address to, uint256 quantity) external onlyOwner {
        require(quantity > 0, "Quantity cannot be zero");
        uint256 totalMinted = totalSupply();
        require(
            totalMinted.add(quantity) <= MAX_SUPPLY,
            "No more reserved NFTs left"
        );
        _safeMint(to, quantity);
    }

    function mint(uint256 quantity, address to) external payable whenNotPaused {
        require(
            block.timestamp >= MINT_SESSION_BEGIN + 604800 || overrideTime,
            "PUBLIC MINT CLOSED"
        );
        require(quantity > 0, "Quantity cannot be zero");
        require(quantity <= 10, "Quantity cannot be greater than 10");
        uint256 totalMinted = totalSupply();
        require(
            totalMinted.add(quantity) <= MAX_SUPPLY,
            "Not enough NFTs left to mint"
        );
        require(PRICE * quantity <= msg.value, "Insufficient funds sent");
        totalMinted = totalMinted.add(quantity);
        _safeMint(to, quantity);
    }

    function snapshotMint(
        uint256 quantity,
        uint256 maxQuantity,
        bytes32[] calldata _merkleProof
    ) external whenNotPaused {
        require(
            block.timestamp <= MINT_SESSION_BEGIN + 604800 && !overrideTime,
            "SNAPSHOT MINT CLOSED"
        );
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, maxQuantity));
        require(
            MerkleProof.verify(_merkleProof, snapshotMerkleRoot, leaf),
            "Invalid Merkle Proof."
        );
        require(quantity > 0, "Quantity cannot be zero");
        uint256 totalMinted = totalSupply();
        require(
            MINTED_SNAPSHOT[msg.sender] + quantity <= maxQuantity,
            "Max mint reached"
        );
        MINTED_SNAPSHOT[msg.sender] += quantity;
        require(
            totalMinted.add(quantity) <= MAX_SUPPLY,
            "Not enough NFTs left to mint"
        );
        totalMinted = totalMinted.add(quantity);
        _safeMint(msg.sender, quantity);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function beginMintingSession() public onlyOwner {
        require(MINT_SESSION_BEGIN == 0, "MINT ALREADY BEGUN");
        MINT_SESSION_BEGIN = block.timestamp;
        _unpause();
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setSnapshot(bytes32 snapshot) public onlyOwner {
        snapshotMerkleRoot = snapshot;
    }

    function OverrideTime() public onlyOwner {
        overrideTime = true;
    }

    function setBaseURI(string memory baseURI) public {
        require(msg.sender == owner());
        _contractBaseURI = baseURI;
    }

    // OpenSea metadata initialization
    function contractURI() public pure returns (string memory) {
        return "openseametadata.com/metadata.json";
    }

    function _baseURI() internal view override returns (string memory) {
        return _contractBaseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setPrice(uint256 _price) public onlyOwner {
        PRICE = _price;
    }
}