// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./operator-filter-registry/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TheMotherPlant is ERC721A, Ownable, DefaultOperatorFilterer {
    constructor(
        string memory _baseURI
    ) ERC721A("TheMotherPlant", "MOTHERPLANT") {
        baseURI = _baseURI;
    }

    using Strings for uint256;

    // Sale config
    uint256 public maxSupply = 122;
    uint256 public price = 220000000000000000;
    uint256 public maxPerWalletWLSale = 2;
    uint256 public maxPerWalletPubSale = 10;
    bool public pubActive = false;
    bool public wlActive = false;

    // WL
    bytes32 private merkleRoot;

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function verify(
        bytes32[] calldata merkleProof,
        address sender
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(sender));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    // Claim tracker
    mapping(address => uint256) public greenlistClaimed;
    mapping(address => uint256) public publicClaimed;

    // Metadata

    string private baseURI;
    string public uriSuffix = ".json";

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Cannot query non-existent token");
        return
            string(abi.encodePacked(baseURI, _tokenId.toString(), uriSuffix));
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // Sale config

    function setPubActive(bool _state) external onlyOwner {
        pubActive = _state;
    }

    function setWlActive(bool _state) external onlyOwner {
        wlActive = _state;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    // Minting logic

    function greenlistMint(
        uint256 quantity,
        address _to,
        bytes32[] calldata _merkleProof
    ) external payable {
        uint256 currentSupply = totalSupply();
        bytes32 leaf = keccak256(abi.encodePacked(_to));
        require(quantity > 0);
        require(wlActive, "greenlist minting not active");
        require(
            currentSupply + quantity <= maxSupply,
            "Requested quantity would exceed total supply."
        );
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "User is not in the greenlist"
        );
        require(price * quantity <= msg.value, "ETH sent is incorrect.");
        require(
            greenlistClaimed[_to] + quantity <= maxPerWalletWLSale,
            "Max amount minted per wallet for greenlist"
        );
        unchecked {
            greenlistClaimed[_to] += quantity;
        }
        _safeMint(_to, quantity);
        delete currentSupply;
    }

    function publicMint(uint256 quantity, address _to) external payable {
        uint256 currentSupply = totalSupply();
        require(quantity > 0);
        require(pubActive, "Public minting not active");
        require(
            currentSupply + quantity <= maxSupply,
            "Requested quantity would exceed total supply."
        );
        require(price * quantity <= msg.value, "ETH sent is incorrect.");
        require(
            publicClaimed[_to] + quantity <= maxPerWalletPubSale,
            "Max amount minted per wallet for public sale"
        );
        unchecked {
            publicClaimed[_to] += quantity;
        }
        _safeMint(_to, quantity);
        delete currentSupply;
    }

    function withdraw() external onlyOwner {
        (bool rr, ) = payable(0xad8076DcaC7d6FA6F392d24eE225f4d715FAa363).call{
            value: address(this).balance
        }("");
        require(rr, "Transfer failed");
    }
    // Operator filterer OS

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