// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

//
// ░██████╗██╗░░██╗██╗░░░██╗██╗░░░░░██╗░░░░░
// ██╔════╝██║░██╔╝██║░░░██║██║░░░░░██║░░░░░
// ╚█████╗░█████═╝░██║░░░██║██║░░░░░██║░░░░░
// ░╚═══██╗██╔═██╗░██║░░░██║██║░░░░░██║░░░░░
// ██████╔╝██║░╚██╗╚██████╔╝███████╗███████╗
// ╚═════╝░╚═╝░░╚═╝░╚═════╝░╚══════╝╚══════╝
//
// ██████╗░██╗░░░██╗███╗░░██╗░██████╗░███████╗░█████╗░███╗░░██╗
// ██╔══██╗██║░░░██║████╗░██║██╔════╝░██╔════╝██╔══██╗████╗░██║
// ██║░░██║██║░░░██║██╔██╗██║██║░░██╗░█████╗░░██║░░██║██╔██╗██║
// ██║░░██║██║░░░██║██║╚████║██║░░╚██╗██╔══╝░░██║░░██║██║╚████║
// ██████╔╝╚██████╔╝██║░╚███║╚██████╔╝███████╗╚█████╔╝██║░╚███║
// ╚═════╝░░╚═════╝░╚═╝░░╚══╝░╚═════╝░╚══════╝░╚════╝░╚═╝░░╚══╝
//

contract SkullDungeon is ERC721, Pausable, Ownable, ReentrancyGuard, VRFConsumerBase {
    using Strings for uint256;
    using ECDSA for bytes32;

    /// ============ Structs / Enums ============
    ///
    enum SaleState {
        NotStarted,
        WhitelistOnly,
        Regular
    }

    /// ============ Immutable storage ============
    ///
    uint256 public constant MAX_SUPPLY = 3777;

    uint256 public constant RESERVED_SUPPLY = 66;

    uint256 public constant WHITELIST_TIER1 = 1;

    uint256 public constant WHITELIST_TIER2 = 2;

    bytes32 internal immutable LINK_KEY_HASH;

    uint256 internal immutable LINK_FEE;

    uint256 internal TOKEN_OFFSET;

    string internal PROVENANCE_HASH;

    /// ============ Mutable storage ============
    ///
    address public signerAddress;

    string internal metadataBaseURI;
    bool public metadataRevealed;
    bool public metadataFinalised;

    SaleState public saleState;

    uint256 public regularPrice;
    uint256 public whitelistPrice;

    uint256 public regularMaxPerTransaction;
    uint256 public whitelistTier1MaxPerWallet;
    uint256 public whitelistTier2MaxPerWallet;

    mapping(address => uint256) private _whitelistMintedPerAddress;

    uint256 public tokenCounter;

    /// ============ Events ============
    ///
    event MetadataBaseURIUpdated(string oldBaseURI, string newBaseURI);

    constructor(
        address signer,
        string memory baseURI,
        address vrfCoordinator,
        address linkToken,
        bytes32 keyHash,
        uint256 linkFee
    ) ERC721("Skull Dungeon", "SXD") VRFConsumerBase(vrfCoordinator, linkToken) {
        LINK_KEY_HASH = keyHash;
        LINK_FEE = linkFee;

        signerAddress = signer;
        metadataBaseURI = baseURI;
        metadataRevealed = false;
        metadataFinalised = false;

        saleState = SaleState.NotStarted;

        regularPrice = 0.079 ether;
        whitelistPrice = 0.069 ether;

        regularMaxPerTransaction = 2;
        whitelistTier1MaxPerWallet = 3;
        whitelistTier2MaxPerWallet = 2;

        tokenCounter = 0;

        ownerMint(RESERVED_SUPPLY);
    }

    function mint(uint256 numTokens) public payable nonReentrant {
        require(saleState == SaleState.Regular, "Regular sale not active");
        require(
            numTokens > 0 && numTokens <= regularMaxPerTransaction,
            "Incorrect number of tokens requested"
        );
        require(tokenCounter + numTokens <= MAX_SUPPLY, "Max supply exceeded");
        require(numTokens * regularPrice == msg.value, "Incorrect ETH sent");

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(_msgSender(), tokenCounter);
            tokenCounter++;
        }
    }

    function whitelistMint(
        uint256 numTokens,
        uint256 tier,
        bytes calldata signature
    ) public payable nonReentrant {
        require(saleState == SaleState.WhitelistOnly, "Whitelist sale not active");
        require(numTokens > 0, "Incorrect number of tokens requested");
        require(tokenCounter + numTokens <= MAX_SUPPLY, "Max supply exceeded");
        require(numTokens * whitelistPrice == msg.value, "Incorrect ETH sent");

        require(_validateSignature(signature, tier, _msgSender()), "Wallet not whitelisted");
        uint256 maxPerWallet = whitelistMaxPerWallet(tier);
        require(
            _whitelistMintedPerAddress[_msgSender()] + numTokens <= maxPerWallet,
            "Max tokens per wallet exceeded"
        );
        _whitelistMintedPerAddress[_msgSender()] += numTokens;

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(_msgSender(), tokenCounter);
            tokenCounter++;
        }
    }

    function whitelistMaxPerWallet(uint256 tier) public view returns (uint256) {
        require(tier == WHITELIST_TIER1 || tier == WHITELIST_TIER2, "Unknown whitelist tier");
        return tier == WHITELIST_TIER1 ? whitelistTier1MaxPerWallet : whitelistTier2MaxPerWallet;
    }

    function isWhitelisted(
        bytes calldata signature,
        uint256 tier,
        address caller
    ) public view returns (bool) {
        return _validateSignature(signature, tier, caller);
    }

    function _validateSignature(
        bytes calldata signature,
        uint256 tier,
        address caller
    ) internal view returns (bool) {
        bytes32 dataHash = keccak256(abi.encodePacked(tier, caller));
        bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);

        address receivedAddress = ECDSA.recover(message, signature);
        return (receivedAddress != address(0) && receivedAddress == signerAddress);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (!metadataRevealed) return metadataBaseURI;
        return string(abi.encodePacked(metadataBaseURI, tokenId.toString()));
    }

    function tokenOffset() public view returns (uint256) {
        require(TOKEN_OFFSET != 0, "Offset is not set");
        return TOKEN_OFFSET;
    }

    function provenanceHash() public view returns (string memory) {
        require(bytes(PROVENANCE_HASH).length != 0, "Provenance hash is not set");
        return PROVENANCE_HASH;
    }

    /// ============ ADMIN functions ============

    function ownerMint(uint256 numTokens) public onlyOwner {
        require(numTokens > 0, "Incorrect number of tokens requested");
        require(tokenCounter + numTokens <= MAX_SUPPLY, "Max supply exceeded");

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(_msgSender(), tokenCounter);
            tokenCounter++;
        }
    }

    function setSignerAddress(address signer) public onlyOwner {
        require(signer != address(0), "Signer address cannot be 0");
        signerAddress = signer;
    }

    function startRegularSale() public onlyOwner {
        require(saleState != SaleState.Regular, "Regular sale already active");
        saleState = SaleState.Regular;
    }

    function startWhitelistSale() public onlyOwner {
        require(saleState != SaleState.WhitelistOnly, "Whitelist sale already active");
        saleState = SaleState.WhitelistOnly;
    }

    function setRegularPrice(uint256 price) public onlyOwner {
        regularPrice = price;
    }

    function setWhitelistPrice(uint256 price) public onlyOwner {
        whitelistPrice = price;
    }

    function setRegularMaxPerTransaction(uint256 limit) public onlyOwner {
        regularMaxPerTransaction = limit;
    }

    function setWhitelistTier1MaxPerWallet(uint256 limit) public onlyOwner {
        whitelistTier1MaxPerWallet = limit;
    }

    function setWhitelistTier2MaxPerWallet(uint256 limit) public onlyOwner {
        whitelistTier2MaxPerWallet = limit;
    }

    function setTokenOffset() public onlyOwner {
        require(TOKEN_OFFSET == 0, "Offset is already set");
        require(LINK.balanceOf(address(this)) >= LINK_FEE, "Not enough LINK");
        provenanceHash();

        requestRandomness(LINK_KEY_HASH, LINK_FEE);
    }

    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        TOKEN_OFFSET = randomness % (MAX_SUPPLY - RESERVED_SUPPLY);
    }

    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        require(bytes(PROVENANCE_HASH).length == 0, "Provenance hash is already set");
        PROVENANCE_HASH = _provenanceHash;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function revealMetadata() public onlyOwner {
        require(!metadataRevealed, "Metadata already revealed");
        metadataRevealed = true;
    }

    function finaliseMetadata() public onlyOwner {
        require(metadataRevealed, "Metadata not revealed");
        require(!metadataFinalised, "Metadata already finalised");
        metadataFinalised = true;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        require(!metadataFinalised, "Metadata already finalised");
        string memory oldBaseURI = metadataBaseURI;
        metadataBaseURI = baseURI;
        emit MetadataBaseURIUpdated(oldBaseURI, baseURI);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(_msgSender()), balance);
    }

    function withdrawLINK(uint256 amount) external onlyOwner {
        LINK.transfer(_msgSender(), amount);
    }
}