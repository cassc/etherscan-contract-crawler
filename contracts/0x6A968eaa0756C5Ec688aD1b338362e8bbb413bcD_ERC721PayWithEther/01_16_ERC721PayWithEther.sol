// SPDX-License-Identifier: MIT
// Created by Yu-Chen Song on 2022/9/16 https://www.linkedin.com/in/yu-chen-song-08892a77/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./interfaces/IBaseGatewayEthereum.sol";
import "./interfaces/IFactoryERC721PayWithEther.sol";

contract ERC721PayWithEther is IFactoryERC721PayWithEther, Ownable, ERC721Enumerable {
    using MerkleProof for bytes32[];

    uint256 public constant MAX_TOTAL_TOKEN_MINT = 250;

    uint256 public latestMintedId;

    bytes32 immutable private PRE_WHITELIST;

    uint256 constant public PRICE = 0.1 ether;

    struct WhitelistData {
        bool isWhitelistAddress;
        uint256 amount;
    }

    mapping(address => WhitelistData) public whitelist;

    uint256 constant public WHITELIST_MINT_LIMIT = 10;

    uint256 constant private BASE_VALUE_PERCENTAGE = 70;

    uint32 constant public WHITELIST_MINT_TIME = 1664704800;
    uint32 constant public MINT_TIME = 1664715600;

    bool private isMetadataFrozen = false;
    string private contractDataURI;

    string private metadataURI;

    IBaseGatewayEthereum public gateway;

    IERC721 constant public DEMI_HUMAN_NFT = IERC721(0xa6916545A56f75ACD43fb6A1527A73a41d2b4081);
    IERC721 constant public CRYPTO_HODLERS_NFT = IERC721(0xe12a2A0Fb3fB5089A498386A734DF7060c1693b8);
    IERC721 constant public _8SIAN_NFT = IERC721(0x198478F870d97D62D640368D111b979d7CA3c38F);

    event Withdraw(address _address, uint256 balance);
    event Initialize(IBaseGatewayEthereum _gateway);
    event SetContractDataURI(string _contractDataURI);
    event SetURI(string _uri);
    event MetadataFrozen();
    event AddWhitelist(address[] _addresses);
    event RemoveWhitelist(address[] _addresses);
    event Mint(address _address, uint256 tokenId);

    constructor(
        string memory _contractDataURI,
        string memory _uri,
        bytes32 _whitelist
    ) ERC721("Demi Human NFT", "DEM") {
        require(keccak256(abi.encodePacked(_contractDataURI)) != keccak256(abi.encodePacked("")), "init from empty uri");
        require(_whitelist != 0, "init from the zero");
        contractDataURI = _contractDataURI;
        metadataURI = _uri;
        PRE_WHITELIST = _whitelist;
    }

    function _initialized() internal view returns (bool) {
        return !(address(gateway) == address(0));
    }

    function initialize(IBaseGatewayEthereum _gateway) onlyOwner external {
        require(!_initialized(), "Already initialized");
        require(address(_gateway) != address(0), "init from the zero address");
        gateway = _gateway;
        emit Initialize(_gateway);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(metadataURI, Strings.toString(_tokenId), ".json"));
    }

    /// @dev https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public view returns (string memory) {
        return contractDataURI;
    }

    function setContractDataURI(string memory _contractDataURI) external onlyOwner {
        contractDataURI = _contractDataURI;
        emit SetContractDataURI(_contractDataURI);
    }

    function setURI(string memory _uri) external onlyOwner {
        require(!isMetadataFrozen, "URI Already Frozen");
        metadataURI = _uri;
        emit SetURI(_uri);
    }

    function metadataFrozen() external onlyOwner {
        isMetadataFrozen = true;
        emit MetadataFrozen();
    }

    function withdraw(address _address, uint256 _amount) external onlyOwner override {
        require(_amount > 0, "Amount cannot be 0");
        require(payable(_address).send(_amount), "Fail to withdraw");
        emit Withdraw(_address, _amount);
    }

    function addWhitelist(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            address _address = _addresses[i];
            whitelist[_address].isWhitelistAddress = true;
        }
        emit AddWhitelist(_addresses);
    }

    function removeWhitelist(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            address _address = _addresses[i];
            whitelist[_address].isWhitelistAddress = false;
        }
        emit RemoveWhitelist(_addresses);
    }

    function mint(uint256 _numberTokens, bytes32[] memory proof) hasInitialized canMint(_numberTokens) payable external override {

        require(DEMI_HUMAN_NFT.balanceOf(msg.sender) > 0 || CRYPTO_HODLERS_NFT.balanceOf(msg.sender) > 0 || _8SIAN_NFT.balanceOf(msg.sender) > 0, "You not own specified NFT");

        if(block.timestamp < MINT_TIME) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            WhitelistData storage data = whitelist[msg.sender];
            data.amount += _numberTokens;
            
            require(block.timestamp >= WHITELIST_MINT_TIME, "Not arrive whitelist mint time");
            require(data.isWhitelistAddress || proof.verify(PRE_WHITELIST, leaf), "Not in whitelist");
            require(data.amount <= WHITELIST_MINT_LIMIT, "Total mint amount big than whitelist mint limit");
        }

        uint256 amount = _numberTokens * PRICE;
        require(amount <= msg.value, "Sent value is not enough");

        uint256 id = latestMintedId + 1;
        uint256 investPrice = amount * BASE_VALUE_PERCENTAGE / 100;
        gateway.batchDeposit{value : investPrice}(id, _numberTokens);
        latestMintedId += _numberTokens;

        for (uint256 i = 0; i < _numberTokens; i++) {
            _safeMint(msg.sender, id + i);
            emit Mint(msg.sender, id + i);
        }
    }

    modifier hasInitialized() {
        require(_initialized(), "Not initialized yet!");
        _;
    }

    modifier canMint(uint256 _amount) {
        require(_amount > 0, "Number tokens cannot be 0");
        require(latestMintedId + _amount <= MAX_TOTAL_TOKEN_MINT, "Over maximum minted amount");
        _;
    }
}