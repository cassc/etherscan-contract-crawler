// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Grug is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // ============ PRIVATE ============
    Counters.Counter private _tokenIdCounter;

    // ============ PUBLIC ============
    string public baseURI;
    uint256 public maxGrugs;
    uint256 public startTime;
    uint256 public constant PUBLIC_SALE_PRICE = 0.1 ether;
    uint256 public constant OG_MINT_TIME = 2 days;
    uint256 public constant WHITELIST_MINT_TIME = OG_MINT_TIME + 5 days;
    bool public isOGSaleActive;

    // ============ MERKLE ROOTS ============
    bytes32 public oGMerkleRoot;
    bytes32 public whiteListMerkleRoot;

    // ============ MAPS ============ 
    mapping(address => bool) public hasMinted;

    // ============ ACCESS CONTROL ============

    modifier oGSaleActive() {
        require(isOGSaleActive, "OG sale is not open");
        _;
    }

    modifier canMintGrugs(uint256 numberOfTokens) {
        require(
            _tokenIdCounter.current() + numberOfTokens <= maxGrugs,
            "No Grugs Left"
        );
        _;
    }
    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist on list"
        );
        _;
    }
    modifier hasNotMinted() {
        require(
            !hasMinted[msg.sender],
            "Already Minted"
        );
        _;
    }
    constructor(uint256 _maxGrugs) ERC721("GrugsLair", "GRUG") { 
        maxGrugs = _maxGrugs;
    }

    // ============ MINT FUNCTIONS ==================

    function OGMint(bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
        oGSaleActive
        canMintGrugs(1)
        hasNotMinted
        isValidMerkleProof(merkleProof, oGMerkleRoot)
    {
        hasMinted[msg.sender] = true;
        _safeMint(msg.sender, nextTokenId());

    }

    function whiteListMint(bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
        oGSaleActive
        canMintGrugs(1)
        hasNotMinted
        isCorrectPayment(PUBLIC_SALE_PRICE, 1)
        isValidMerkleProof(merkleProof, whiteListMerkleRoot)
    {
        require(block.timestamp > startTime + OG_MINT_TIME, "whitelist mint not started");
        hasMinted[msg.sender] = true;
        _safeMint(msg.sender, nextTokenId());
    }

    function mint(uint8 numberOfTokens)
        external
        payable
        nonReentrant
        oGSaleActive
        canMintGrugs(numberOfTokens)
        isCorrectPayment(PUBLIC_SALE_PRICE, numberOfTokens)
    {
        require(block.timestamp > startTime + WHITELIST_MINT_TIME, "public mint not started");
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    function ownerMint(uint8 numberOfTokens)
        external
        payable
        nonReentrant
        oGSaleActive
        canMintGrugs(numberOfTokens)
        onlyOwner
    {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    // ============ SUPPORTING FUNCTIONS ============
    function setMaxGrugs(uint256 _value) external onlyOwner {
        maxGrugs = _value;
    }

    function setIsOgSaleActive(bool _value) external onlyOwner {
        isOGSaleActive = _value;
        startTime = block.timestamp;
    }

    function setOgMerkleRoot(bytes32 _merkleRoot)
        external
        onlyOwner
    {
        oGMerkleRoot = _merkleRoot;
    }

    function setWhiteListMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whiteListMerkleRoot = _merkleRoot;
    }

    function setTokenURI(string memory _tokenURI) external onlyOwner {
        baseURI = _tokenURI;
    }

    function nextTokenId() private returns (uint256) {
        _tokenIdCounter.increment();
        return _tokenIdCounter.current();
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    // ============ OVERRIDES ============

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        return
            string(abi.encodePacked(baseURI, "/", Strings.toString(tokenId)));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}