// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract CBOYS is ERC721Enumerable, Ownable, ReentrancyGuard {

    uint256 public constant LIMIT = 5000;

    bytes32 public merkleRoot;
    uint256 public price = 25000000000000000;
    uint256 public stage;
    uint256[2] public limitPerStage = [2, 3];
    bool public URILocked;

    string private URI;

    mapping(address => uint256[2]) public claimed;

    event Mint(uint256 amount, uint256 totalSupply);
    event Reveal();

    constructor(string memory _uri) ERC721("Chill Boys","CBOYS") {
        URI = _uri;
    }

    function mint(uint256 amount, bytes32[] calldata proof) external payable nonReentrant {
        require(stage == 1 || MerkleProof.verifyCalldata(proof, merkleRoot, keccak256(abi.encodePacked(_msgSender()))), "Invalid merkle proof");
        require(totalSupply() + amount <= LIMIT, "Exceeds collection limit");
        require(msg.value == price * amount, "Wrong payment amount");
        claimed[_msgSender()][stage] += amount;
        require(claimed[_msgSender()][stage] <= limitPerStage[stage], "Exceeds limit per stage");
        for (uint256 i; i < amount; i++) {
            _safeMint(_msgSender(), totalSupply());
        }
        emit Mint(amount, totalSupply());
    }

    function gift(address account, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= LIMIT, "Exceeds collection limit");
        for (uint256 i; i < amount; i++) {
            _safeMint(account, totalSupply());
        }
        emit Mint(amount, totalSupply());
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function enablePublicSale() external onlyOwner {
        stage = 1;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function reveal() external onlyOwner {
        emit Reveal();
    }

    function setURI(string calldata _uri) external onlyOwner {
        require(!URILocked, "URI locked");
        URI = _uri;
    }

    function lockURI() external onlyOwner {
        URILocked = true;
    }

    function getETH() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return URI;
    }
}