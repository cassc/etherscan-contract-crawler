// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/[email protected]/utils/cryptography/MerkleProof.sol";
import "https://github.com/ProjectOpenSea/operator-filter-registry/blob/main/src/DefaultOperatorFilterer.sol";

contract HasbullaNFT is 
    ERC721A,
    DefaultOperatorFilterer,
    Ownable,
    ReentrancyGuard
{
    using Strings for uint256;

    mapping(address => uint256) public ClaimedWhitelist;
    mapping(address => uint256) public ClaimedPublic;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant GENESIS_HOLDERS_AMOUNT = 2000;
    uint256 public constant TEAM_AMOUNT = 250;
    uint256 public constant VIPS_AIRDROP_AMOUNT = 200;
    uint256 public constant MAX_MINTS_WALLET_WHITELIST = 3;
    uint256 public constant MAX_MINTS_WALLET_PUBLIC = 2;
    uint256 public constant PRICE_WHITELIST = 0.05 ether; 
    uint256 public constant PRICE_PUBLIC = 0.069 ether; 

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string private baseURI;
    uint256 public _minted = 0;

    bool public WhitelistMintActive = false;
    bool public PublicMintActive = false;
    bool public isTeamMintedForVIPs = false;
    bool public isTeamMintedForGenesisHolders = false;

    bytes32 public root;

    constructor() ERC721A("Hasbulla NFT", "HASBI") {}

    function WhitelistMint(uint256 amount, bytes32[] memory proof)
        public
        payable
        nonReentrant
    {
        require(WhitelistMintActive, "Whitelist Mint is not enabled!");
        require(
            isValid(proof, keccak256(abi.encodePacked(msg.sender))),
            "Not a part of Whitelist"
        );
        require(
            msg.value == amount * PRICE_WHITELIST,
            "Invalid funds provided"
        );
        require(
            amount > 0 && amount <= MAX_MINTS_WALLET_WHITELIST,
            "Must mint between the min and max."
        );
        require(_minted + amount <= MAX_SUPPLY, "Exceed max supply");
        require(
            ClaimedWhitelist[msg.sender] + amount <= MAX_MINTS_WALLET_WHITELIST,
            "Already minted Max Mints Whitelist"
        );
        ClaimedWhitelist[msg.sender] += amount;
        _minted += amount;
        _safeMint(msg.sender, amount);
    }

    function PublicMint(uint256 amount) public payable nonReentrant {
        require(PublicMintActive, "Public Mint is not enabled");
        require(msg.value == amount * PRICE_PUBLIC, "Invalid funds provided");
        require(
            amount > 0 && amount <= MAX_MINTS_WALLET_PUBLIC,
            "Must mint between the min and max."
        );
        require(_minted + amount <= MAX_SUPPLY, "Exceed max supply");
        require(
            ClaimedPublic[msg.sender] + amount <= MAX_MINTS_WALLET_PUBLIC,
            "Already minted Max Mints Public"
        );
        ClaimedPublic[msg.sender] += amount;
        _minted += amount;
        _safeMint(msg.sender, amount);
    }

    function TeamMintForVIPs() external onlyOwner {
        require(!isTeamMintedForVIPs, "Already Minted TeamMint For VIPs");
        require(
            _minted + VIPS_AIRDROP_AMOUNT <= MAX_SUPPLY,
            "Max supply exceeded"
        );
        _minted += VIPS_AIRDROP_AMOUNT;
        _safeMint(msg.sender, VIPS_AIRDROP_AMOUNT);
        isTeamMintedForVIPs = true;
    }

    function TeamMintForGenesisHolders() external onlyOwner {
        require(
            !isTeamMintedForGenesisHolders,
            "Already Minted TeamMint For Genesis Holders"
        );
        require(
            _minted + GENESIS_HOLDERS_AMOUNT <= MAX_SUPPLY,
            "Max supply exceeded"
        );
        _minted += GENESIS_HOLDERS_AMOUNT;
        _safeMint(msg.sender, GENESIS_HOLDERS_AMOUNT);
        isTeamMintedForGenesisHolders = true;
    }

    function TeamMint(uint256 amount) external onlyOwner {
        require(_minted + amount <= MAX_SUPPLY, "Max supply exceeded");
        _minted += amount;
        _safeMint(msg.sender, amount);
    }

    function setWhitelistMintActive(bool _state) public onlyOwner {
        WhitelistMintActive = _state;
    }

    function setPublicMintActive(bool _state) public onlyOwner {
        PublicMintActive = _state;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

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

    function isValid(bytes32[] memory proof, bytes32 leaf)
        public
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "WITHDRAW FAILED!");
    }

    function withdrawMoneyTo(address payoutAddress) external onlyOwner {
        (bool success, ) = payoutAddress.call{value: address(this).balance}("");
        require(success, "WITHDRAW FAILED!");
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}