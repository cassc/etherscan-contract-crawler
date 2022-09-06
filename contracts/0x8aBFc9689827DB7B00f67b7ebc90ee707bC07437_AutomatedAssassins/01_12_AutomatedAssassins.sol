// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract AutomatedAssassins is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant maxWhitelistMint = 2;
    uint256 public constant maxPreMint = 1;
    uint256 public constant maxPublicMint = 3;
    uint256 public constant whitelistSalePrice = .029 ether;
    uint256 public constant preSalePrice = .029 ether;
    uint256 public constant publicSalePrice = .039 ether;

    string private  baseTokenUri = "https://automatedassassins.com/files/metadata/";

    bool public isWhiteListSaleActive = false;
    bool public isPreSaleActive = false;
    bool public isPublicSaleActive = false;
    bool public hasTeamMinted;

    bytes32 private merkleRoot;

    mapping(address => uint256) public totalWhitelistMint;
    mapping(address => uint256) public totalPreSaleMint;
    mapping(address => uint256) public totalPublicMint;

    constructor() ERC721A("Automated Assassins", "AA"){}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Automated Assassins :: Cannot be called by a contract");
        _;
    }

    function whitelistMint(bytes32[] memory _merkleProof, uint256 _quantity) external payable callerIsUser {
        require(isWhiteListSaleActive, "Automated Assassins :: Minting is on Pause");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Automated Assassins :: Cannot mint beyond max supply");
        require((totalWhitelistMint[msg.sender] + _quantity) <= maxWhitelistMint, "Automated Assassins :: Cannot mint beyond whitelist max mint!");
        require(msg.value >= (whitelistSalePrice * _quantity), "Automated Assassins :: Payment is below the price");
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, sender), "Automated Assassins :: You are not whitelisted");
        totalWhitelistMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function preMint(bytes32[] memory _merkleProof, uint256 _quantity) external payable callerIsUser {
        require(isPreSaleActive, "Automated Assassins :: Minting is on Pause");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Automated Assassins :: Cannot mint beyond max supply");
        require((totalPreSaleMint[msg.sender] + _quantity) <= maxPreMint, "Automated Assassins :: Cannot mint beyond presale max mint!");
        require(msg.value >= (preSalePrice * _quantity), "Automated Assassins :: Payment is below the price");
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, sender), "Automated Assassins :: You are not whitelisted");
        totalPreSaleMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function mint(uint256 _quantity) external payable callerIsUser {
        require(isPublicSaleActive, "Automated Assassins :: Not Yet Active.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Automated Assassins :: Beyond Max Supply");
        require((totalPublicMint[msg.sender] + _quantity) <= maxPublicMint, "Automated Assassins :: Already minted!");
        require(msg.value >= (publicSalePrice * _quantity), "Automated Assassins :: Below ");
        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721AMetadata: URI query for nonexistent token");
        uint256 trueId = tokenId + 1;

        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function getMerkleRoot() external view returns (bytes32){
        return merkleRoot;
    }

    function toggleWhiteListSale() external onlyOwner {
        isWhiteListSaleActive = !isWhiteListSaleActive;
    }

    function togglePreSale() external onlyOwner {
        isPreSaleActive = !isPreSaleActive;
    }

    function togglePublicSale() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function withdraw() external onlyOwner {
        uint256 tempBalance = address(this).balance;
        payable(0x3c1E66D6Fe004B581aCe44612726164AD34Dbd7f).transfer(tempBalance / 1000 * 475);
        payable(0xb7C8D69703289bdaF21D7A419B7Af95B32D8ca40).transfer(tempBalance / 1000 * 475);
        payable(0x67eF43A7b0FDC38DB0990413a86f7B0dc0220f7F).transfer(tempBalance / 1000 * 50);
    }
}