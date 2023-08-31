//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import './lib/ERC721X.sol';

contract ShinobiBunny is ERC721X, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    event SaleStateUpdate(bool active);

    string public baseURI = "ipfs://none";
    string public unrevealedURI = 'ipfs://QmQgDNbcGnPNiPdYDiJou9RsawaSSHrm6pQFjHrFkRTFAP/';

    bool public publicSaleActive;
    bool public whitelistActive;
    bool public diamondlistActive;

    uint256 public totalSupply;
    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public constant PREMINT_AMOUNT = 3;
    uint256 public RESERVED_AMOUNT = 1500;

    uint256 public price = 0.12 ether;
    uint256 public purchaseLimit = 1;

    uint256 public whitelistPrice = 0.1 ether;
    uint256 public whitelistPurchaseLimit = 1;

    mapping(address => uint256) public _publicMinted;
    mapping(address => uint256) public _whitelistMinted;
    mapping(address => bool) public _diamondlistUsed;

    address private _signerAddress = 0xc6EC711aDdFb8FFC9f7561f065F698f8606691AA;

    uint256 private constant SIGNED_DATA_WHITELIST = 69;
    uint256 private constant SIGNED_DATA_DIAMONDLIST = 1337;

    bool public revealed = false;

    constructor() ERC721X('Shinobi Bunny', 'SNB') {
        // premint first 3 tokenIds to the owner
        _mintBatch(msg.sender, PREMINT_AMOUNT);
    }

    // ------------- External -------------

    function mint(uint256 amount) external payable whenPublicSaleActive noContract {
        require(_publicMinted[msg.sender] + amount <= purchaseLimit, 'EXCEEDS_LIMIT');
        require(msg.value == price * amount, 'INCORRECT_VALUE');

        _publicMinted[msg.sender] = _publicMinted[msg.sender] + amount;
        _mintBatch(msg.sender, amount);
    }

    function whitelistMint(uint256 amount, bytes memory signature)
        external
        payable
        whenWhitelistActive
        onlyWhitelisted(signature)
        noContract
    {
        require(_whitelistMinted[msg.sender] + amount <= whitelistPurchaseLimit, 'EXCEEDS_LIMIT');
        require(msg.value == whitelistPrice * amount, 'INCORRECT_VALUE');

        _whitelistMinted[msg.sender] = _whitelistMinted[msg.sender] + amount;
        _mintBatch(msg.sender, amount);
    }

    function diamondlistMint(bytes memory signature)
        external
        payable
        whenDiamondlistActive
        onlyDiamondlisted(signature)
        noContract
    {
        _mintBatch(msg.sender, 1);
    }

    function ownMint(uint256 amount) external onlyOwner {
        _mintBatch(msg.sender, amount);
    } 

    // ------------- Private -------------

    function _mintBatch(address to, uint256 amount) private {
        uint256 tokenId = totalSupply;
        require(tokenId + amount <= MAX_SUPPLY - RESERVED_AMOUNT, 'MAX_SUPPLY_REACHED');
        require(amount > 0, 'MUST_BE_GREATER_0');

        for (uint256 i; i < amount; i++) _mint(to, tokenId + i);
        totalSupply += amount;
    }

    function _validSignature(bytes memory signature, bytes32 data) private view returns (bool) {
        bytes32 msgHash = keccak256(abi.encode(address(this), data, msg.sender));
        return msgHash.toEthSignedMessageHash().recover(signature) == _signerAddress;
    }

    // ------------- View -------------

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        if (!revealed) return unrevealedURI;
        return string(abi.encodePacked(baseURI, tokenId.toString(), '.json'));
    }

    // ------------- Admin -------------
    
        
    function setReserve(uint256 value) external onlyOwner {
        RESERVED_AMOUNT = value;
    }

    function reveal(bool value) external onlyOwner {
        revealed = value;
    }

    function giveAway(address[] calldata accounts) external onlyOwner {
        for (uint256 i; i < accounts.length; i++) _mintBatch(accounts[i], 1);
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setWhitelistPrice(uint256 price_) external onlyOwner {
        whitelistPrice = price_;
    }

    function setPurchaseLimit(uint256 limit) external onlyOwner {
        purchaseLimit = limit;
    }

    function setWhitelistPurchaseLimit(uint256 limit) external onlyOwner {
        whitelistPurchaseLimit = limit;
    }

    function setSignerAddress(address address_) external onlyOwner {
        _signerAddress = address_;
    }

    function setWhitelistActive(bool active) external onlyOwner {
        whitelistActive = active;
    }

    function setDiamondlistActive(bool active) external onlyOwner {
        diamondlistActive = active;
    }

    function setPublicSaleActive(bool active) external onlyOwner {
        publicSaleActive = active;
        emit SaleStateUpdate(active);
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setUnrevealedURI(string memory _uri) external onlyOwner {
        unrevealedURI = _uri;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function recoverToken(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner(), balance);
    }

    // ------------- Modifier -------------

    modifier whenDiamondlistActive() {
        require(diamondlistActive, 'DIAMONDLIST_NOT_ACTIVE');
        _;
    }

    modifier whenWhitelistActive() {
        require(whitelistActive, 'WHITELIST_NOT_ACTIVE');
        _;
    }

    modifier whenPublicSaleActive() {
        require(publicSaleActive, 'PUBLIC_SALE_NOT_ACTIVE');
        _;
    }

    modifier noContract() {
        require(tx.origin == msg.sender, 'CONTRACT_CALL');
        _;
    }

    modifier onlyDiamondlisted(bytes memory signature) {
        require(_validSignature(signature, bytes32(SIGNED_DATA_DIAMONDLIST)), 'NOT_WHITELISTED');
        require(!_diamondlistUsed[msg.sender], 'DIAMONDLIST_USED');
        _diamondlistUsed[msg.sender] = true;
        _;
    }

    modifier onlyWhitelisted(bytes memory signature) {
        require(_validSignature(signature, bytes32(SIGNED_DATA_WHITELIST)), 'NOT_WHITELISTED');
        _;
    }

    // ------------- ERC721 -------------

    function tokenIdsOf(address owner) external view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](balanceOf(owner));
        uint256 count;
        for (uint256 i; i < balanceOf(owner); ++i) ids[count++] = tokenOfOwnerByIndex(owner, i);
        return ids;
    }
}