pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract CitadelNFT is ERC721A, Ownable {
    
    mapping(uint256 => uint256) public level;
    mapping(address => bool) public whitelistClaimed;

    bytes32 public _merkleRoot = 0x5bfdd6b6ad843943a824a0024133e8e910dc1c16f21fab6b10e8f725a853ca70;

    uint256 public MAX_CITADEL = 1024;
    uint256 public MAX_LEVEL = 9;
    string private _baseTokenURI;

    constructor(string memory name, string memory symbol, string memory baseTokenURI) ERC721A(name, symbol) {
        _baseTokenURI = baseTokenURI;
    }

    function reserveCitadel(uint256 num) external onlyOwner {
        require(totalSupply() + num <= MAX_CITADEL, "MAX_SUPPLY");
        _safeMint(msg.sender, num);
    }

    function mintCitadel(bytes32[] calldata _merkleProof) external {
        require(totalSupply() + 1 <= MAX_CITADEL, "MAX_SUPPLY");
        require(!whitelistClaimed[msg.sender], "ADDRESS_CLAIMED");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, _merkleRoot, leaf), "INVALID_PROOF");
        whitelistClaimed[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function changeLevel(uint256 newLevel, uint256 tokenId) external onlyOwner {
        require(newLevel >= 0 && newLevel <= MAX_LEVEL, "MAX_LEVEL");
        level[tokenId] = newLevel;
    }

    function updateBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function updateMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}