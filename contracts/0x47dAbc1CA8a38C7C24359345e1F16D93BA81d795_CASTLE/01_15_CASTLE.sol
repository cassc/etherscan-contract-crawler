// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract CASTLE is ERC721Enumerable, Ownable, ReentrancyGuard {

    uint16 public constant LIMIT = 1666;

    bytes32 public merkleRoot;
    uint256 public price;
    bool public publicSaleActive;
    bool public URILocked;

    string private URI;

    mapping(address => uint8) public claimed;

    event Mint(uint16 amount, uint256 totalSupply);
    event Reveal();

    constructor(string memory _uri) ERC721("Transylvania Castle","CASTLE") {
        URI = _uri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function enablePublicSale() external onlyOwner {
        publicSaleActive = true;
    }

    function reveal() external onlyOwner {
        emit Reveal();
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function getETH() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function setURI(string calldata _uri) external onlyOwner {
        require(!URILocked, "URI locked");
        URI = _uri;
    }

    function lockURI() external onlyOwner {
        URILocked = true;
    }

    function mint(uint16 amount, bytes32[] calldata proof) external payable nonReentrant {
        require(publicSaleActive || MerkleProof.verifyCalldata(proof, merkleRoot, keccak256(abi.encodePacked(_msgSender()))), "Invalid merkle proof");
        require(publicSaleActive || amount + claimed[_msgSender()] < 2, "Exceeds limit per user");
        require(totalSupply() + amount <= LIMIT, "Exceeds collection limit");
        require(msg.value == price * amount, "Wrong payment amount");
        if (!publicSaleActive) {
            claimed[_msgSender()] += uint8(amount);
        }
        for (uint16 i; i < amount; i++) {
            _safeMint(_msgSender(), totalSupply());
        }
        emit Mint(amount, totalSupply());
    }

    function _baseURI() internal view override returns (string memory) {
        return URI;
    }
}