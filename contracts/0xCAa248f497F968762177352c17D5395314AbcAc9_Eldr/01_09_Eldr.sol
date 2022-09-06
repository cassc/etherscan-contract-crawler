// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721AV4.sol";

contract Eldr is ERC721A, Ownable, ReentrancyGuard {
    uint256 public MAX_SUPPLY = 420;
    uint256 public WL_SUPPLY = 320;

    uint256 public WL_MINT_LIMIT = 1;
    uint256 public FREE_MINT_LIMIT = 1;

    uint256 public WL_PRICE = 0.142 ether;

    bool public isWlSaleActive = false;
    bool public isFreeActive = false;

    bool _revealed = false;

    string private baseURI = "";

    bytes32 freeRoot;
    bytes32 wlRoot;

    mapping(address => uint256) addressBlockBought;

    address public constant RL_ADDRESS = 0xc9b5553910bA47719e0202fF9F617B8BE06b3A09; 
    address public constant PROJECT_ADDRESS = 0x27D24a8Ecb3D32844E48DDF567c41B919522BC92; 
    
    mapping(bytes32 => bool) public usedDigests;

    constructor(bytes32 _wlRoot, bytes32 _freeRoot) ERC721A("Eldr", "ELDR") {
            wlRoot = _wlRoot;
            freeRoot = _freeRoot;
        }

    modifier isSecured(uint8 mintType) {
        require(addressBlockBought[msg.sender] < block.timestamp, "CANNOT_MINT_ON_THE_SAME_BLOCK");
        require(tx.origin == msg.sender,"CONTRACTS_NOT_ALLOWED_TO_MINT");

        if(mintType == 1) {
            require(isWlSaleActive, "WL_MINT_IS_NOT_YET_ACTIVE");
        }

        if(mintType == 2) {
            require(isFreeActive, "WL_MINT_IS_NOT_YET_ACTIVE");
        }
        _;
    }

    function freeMint(bytes32[] memory proof) external isSecured(2) payable{
        require(MerkleProof.verify(proof, freeRoot, keccak256(abi.encodePacked(msg.sender))),"PROOF_INVALID");
        require(1 + totalSupply() <= MAX_SUPPLY,"NOT_ENOUGH_SUPPLY");
        require(numberMinted(msg.sender) + 1 <= FREE_MINT_LIMIT,"EXCEED_PRAFFLE_MINT_LIMIT");

        addressBlockBought[msg.sender] = block.timestamp;
        _safeMint(msg.sender, 1);
    }

    function allowMint(bytes32[] memory proof) external isSecured(1) payable{
        require(MerkleProof.verify(proof, wlRoot, keccak256(abi.encodePacked(msg.sender))),"PROOF_INVALID");
        require(totalSupply() + 1 <= WL_SUPPLY,"EXCEED_WL_MINT_SUPPLY");
        require(numberMinted(msg.sender) + 1 <= WL_MINT_LIMIT,"EXCEED_PRAFFLE_MINT_LIMIT");
        require(msg.value == WL_PRICE * 1, "WRONG_ETH_VALUE");

        addressBlockBought[msg.sender] = block.timestamp;
        _safeMint(msg.sender, 1);
    }

    // URI
    function setBaseURI(string calldata URI) external onlyOwner {
        baseURI = URI;
    }

    function reveal(bool revealed, string calldata _baseURI) public onlyOwner {
        _revealed = revealed;
        baseURI = _baseURI;
    }

    // LIVE TOGGLES

    function toggleWlMintStatus() external onlyOwner {
        isWlSaleActive = !isWlSaleActive;
    }

    function toggleFreeMintStatus() external onlyOwner {
        isFreeActive = !isFreeActive;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (_revealed) {
            return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
        } else {
            return string(abi.encodePacked(baseURI));
        }
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    // ROOT SETTERS

    function setWLSaleRoot(bytes32 _wlRoot) external onlyOwner {
        wlRoot = _wlRoot;
    }

    function setFreeRoot(bytes32 _freeRoot) external onlyOwner {
        freeRoot = _freeRoot;
    }

    // LIMIT SETTERS
    function setWLMintLimit(uint256 _mintLimit) external onlyOwner {
        WL_MINT_LIMIT = _mintLimit;
    }

    // PRICE SETTERS
    function setWlPrice(uint256 _price) external onlyOwner {
        WL_PRICE = _price;
    }

    // SUPPLY SETTERS
    function setMaxSupply(uint256 _supply) external onlyOwner {
        MAX_SUPPLY = _supply;
    }

    // withdraw
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(RL_ADDRESS).transfer((balance * 2000) / 10000);
        payable(PROJECT_ADDRESS).transfer(address(this).balance);
    }
}