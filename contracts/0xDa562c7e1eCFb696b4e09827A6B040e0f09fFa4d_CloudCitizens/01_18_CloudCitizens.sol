//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

///    _____ _                 _  _____ _ _   _
///   / ____| |               | |/ ____(_) | (_)
///  | |    | | ___  _   _  __| | |     _| |_ _ _______ _ __  ___
///  | |    | |/ _ \| | | |/ _` | |    | | __| |_  / _ \ '_ \/ __|
///  | |____| | (_) | |_| | (_| | |____| | |_| |/ /  __/ | | \__ \
///   \_____|_|\___/ \__,_|\__,_|\_____|_|\__|_/___\___|_| |_|___/
///
/// By the team behind CloudCitadel.com

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract CloudCitizens is ERC721A, ERC721AQueryable, Ownable, AccessControl {
    using SafeMath for uint256;
    using Strings for uint256;

    // Airdrop constants
    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");

    // Total amounts constants
    uint256 public constant PRIVATE_SALE_AMOUNT = 1000;
    uint256 public constant PUBLIC_SALE_AMOUNT = 900;
    uint256 public constant TEAM_AMOUNT = 100;
    uint256 public constant TOTAL_SUPPLY = PRIVATE_SALE_AMOUNT + PUBLIC_SALE_AMOUNT + TEAM_AMOUNT;

    // Public maps/counters
    bytes32 public privateSaleMerkleRoot;
    mapping(string => bool) public codeUsedMap;
    mapping(address => uint256) public publicSaleCountMap;
    string public baseTokenURI;
    uint256 public privateSaleAmount = 0;
    uint256 public publicSaleAmount = 0;
    uint256 public publicSaleMaxPerWallet = 1;
    uint256 public price = 0;
    bool public privateSaleActive = false;
    bool public claimed = false;
    bool public publicSaleActive = false;

    constructor(string memory _tokenURI, bytes32 _privateSaleMerkleRoot) ERC721A("CloudCitizens", "CLOUDCITIZENS") {
        baseTokenURI = _tokenURI;
        privateSaleMerkleRoot = _privateSaleMerkleRoot;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(AIRDROP_ROLE, msg.sender);
    }

    // @dev internal views
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), '.json')) : '';
    }
    // @dev end of general views

    // @dev private sale functions
    function validClaim(
        string calldata code,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(code, amount.toString()));
        return MerkleProof.verify(merkleProof, privateSaleMerkleRoot, node);
    }

    function airdropClaimWithProof(address to, uint256 amount, string calldata code, bytes32[] calldata merkleProof) external onlyRole(AIRDROP_ROLE) {
        _claim(to, amount, code, merkleProof);
    }

    function claimWithProof(uint256 amount, string calldata code, bytes32[] calldata merkleProof) external isPrivateSaleActive {
        _claim(msg.sender, amount, code, merkleProof);
    }
    // @dev end of private sale functions

    // @dev public sale functions
    function getPublicSalePrice(uint256 amount) public view returns (uint256) {
        return price.mul(amount);
    }

    function mint(uint256 amount) external payable isPublicSaleActive {
        uint256 total = totalSupply();
        require(total <= TOTAL_SUPPLY, "CloudCitizens: max limit");
        require(total + amount <= TOTAL_SUPPLY, "CloudCitizens: max limit");
        require(publicSaleAmount + amount <= PUBLIC_SALE_AMOUNT, "CloudCitizens: max public sale amount reached");
        require(publicSaleCountMap[msg.sender] + amount <= publicSaleMaxPerWallet, "CloudCitizens: max per wallet reached");
        require(msg.value >= getPublicSalePrice(amount), "EthGamesEntry: value below price");

        publicSaleAmount = publicSaleAmount + amount;
        publicSaleCountMap[msg.sender] = publicSaleCountMap[msg.sender] + amount;
        _mint(msg.sender, amount);
    }
    // @dev end of public sale functions

    // @dev private functions
    function _claim(address to, uint256 amount, string calldata code, bytes32[] calldata merkleProof) private {
        require(codeUsedMap[code] == false, "CloudCitizens: code already used");
        require(privateSaleAmount + amount <= PRIVATE_SALE_AMOUNT, "CloudCitizens: max private sale amount reached");
        require(privateSaleMerkleRoot != 0x0, "CloudCitizens: merkle root must be set");
        require(validClaim(code, amount, merkleProof), "CloudCitizens: invalid proof");

        codeUsedMap[code] = true;
        privateSaleAmount = privateSaleAmount + amount;
        _mint(to, amount);
    }

    function _payout(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "CloudCitizens: Transfer failed");
    }
    // @dev end of private functions

    // @dev owner functions
    function claimTokensForTeam() external onlyOwner {
        require(!claimed, "CloudCitizens: can only claim once");
        claimed = true;
        _mint(msg.sender, TEAM_AMOUNT);
    }

    function setPrivateSaleActive(bool _privateSaleActive) external onlyOwner {
        privateSaleActive = _privateSaleActive;
    }

    function setPublicSaleActive(bool _publicSaleActive) external onlyOwner {
        publicSaleActive = _publicSaleActive;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setPrivateSaleMerkleRoot(bytes32 _privateSaleMerkleRoot) external onlyOwner {
        privateSaleMerkleRoot = _privateSaleMerkleRoot;
    }

    function setPublicSaleMaxPerWallet(uint256 _publicSaleMaxPerWallet) external onlyOwner {
        publicSaleMaxPerWallet = _publicSaleMaxPerWallet;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "CloudCitizens: Balance should be above 0");
        _payout(msg.sender, address(this).balance);
    }
    // @dev end of owner functions

    // @dev modifiers
    modifier isPrivateSaleActive() {
        require(privateSaleActive, "CloudCitizens: private sale not active");
        _;
    }

    modifier isPublicSaleActive() {
        require(publicSaleActive, "CloudCitizens: public sale not active");
        _;
    }
    // @dev end of modifiers

    // @dev supports interface
    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    // @dev end of supports interface
}