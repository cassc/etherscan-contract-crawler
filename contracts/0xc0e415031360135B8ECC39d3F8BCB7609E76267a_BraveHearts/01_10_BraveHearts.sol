// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";


contract BraveHearts is ERC721A, Ownable, DefaultOperatorFilterer {
    bool public isWLSale = false;
    bool public isPublicSale = false;
    uint256 public max_supply = 3333;
    uint256 public priceWL = 0.01 ether;
    uint256 public price = 0.0129 ether;
    uint256 public per_wallet = 3;
    bytes32 private merkleRoot;
    string private baseUri;

    constructor(string memory _baseUri, bytes32 _merkleRoot) ERC721A("BraveHearts", "BRH") {
        merkleRoot = _merkleRoot;
        baseUri = _baseUri;
        _mint(msg.sender, 1);
    }

    //////////////////////////////////
    //Public mint
    //////////////////////////////////

    function mint(uint256 quantity) external payable {
        require(isPublicSale, "Public sale has not started yet");
        require(msg.sender == tx.origin, "No contracts allowed");
        unchecked {
            require(balanceOf(msg.sender) + quantity <= per_wallet, "Exceeds max per wallet");
            require(totalSupply() + quantity <= max_supply, "Exceeds max supply");
            require(price * quantity <= msg.value, "Insufficient funds sent");
        }
        _mint(msg.sender, quantity);
    }

    //////////////////////////////////
    //WL mint
    //////////////////////////////////

    function WLMint(uint256 quantity, bytes32[] calldata _merkleProof) external payable {
        require(isWLSale, "WL sale has not started yet");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "You are not on the BraveList"
        );
        unchecked {
            require(balanceOf(msg.sender) + quantity <= per_wallet, "Exceeds max per wallet");
            require(totalSupply() + quantity <= max_supply, "Exceeds max supply");

            if (balanceOf(msg.sender) == 0) {
                require(priceWL * (quantity - 1) <= msg.value, "Insufficient funds sent");
            } else {
                require(priceWL * quantity <= msg.value, "Insufficient funds sent");
            }
        }
        _mint(msg.sender, quantity);
    }

    //////////////////////////////////
    //internal
    //////////////////////////////////

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    //////////////////////////////////
    //Only Owner
    //////////////////////////////////

    function airdrop(uint256 quantity, address to) external onlyOwner {
        require(
            totalSupply() + quantity <= max_supply,
            "Exceeds max supply"
        );
        _mint(to, quantity);
    }

    function ownerMint(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity < max_supply,
            "Exceeds max supply"
        );
        _mint(msg.sender, quantity);
    }

    function flipPublicSale() external onlyOwner {
        isPublicSale = !isPublicSale;
    }

    function flipWLSale() external onlyOwner {
        isWLSale = !isWLSale;
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setPerWallet(uint256 _per_wallet) external onlyOwner {
        per_wallet = _per_wallet;
    }

    function setBaseURI(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    //////////////////////////////////
    //Operator
    //////////////////////////////////

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
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
}