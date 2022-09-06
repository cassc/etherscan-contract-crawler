// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract THT is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public ogMerkleRoot;
    bytes32 public wlMerkleRoot;

    mapping(address => uint256) public ogMintedByAddr;
    mapping(address => uint256) public wlMintedByAddr;
    mapping(address => uint256) public mintedByAddr;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    uint256 public cost = 0.00969 ether;
    uint256 public maxSupply = 3333;
    uint256 public ogSupply = 1111;
    uint256 public wlSupply = 2222;

    uint256 public minted;
    uint256 public ogMinted;
    uint256 public wlMinted;

    uint256 public mintMax = 5;
    uint256 public ogMintMax = 2;
    uint256 public wlMintMax = 1;

    // 0 to pause all mint, 1 for og mint only, 2 for wl mint only, 3 for public mint
    uint256 public mintStatus = 0;

    bool public revealed = false;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _hiddenMetadataUri
    ) ERC721A(_tokenName, _tokenSymbol) {
        setHiddenMetadataUri(_hiddenMetadataUri);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(minted + _mintAmount <= maxSupply, "Max supply exceeded!");
        _;
    }

    function ogMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public mintCompliance(_mintAmount) {
        // Verify whitelist requirements
        require(mintStatus == 1, "The OG sale is not enabled!");
        require(ogMinted + _mintAmount <= ogSupply, "Max OG supply exceeded!");
        require(ogMintedByAddr[_msgSender()] + _mintAmount <= ogMintMax, "Mint amount exceeds maximum allowed per address!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, ogMerkleRoot, leaf), "Invalid proof!");

        _safeMint(_msgSender(), _mintAmount);
        ogMintedByAddr[_msgSender()] += _mintAmount;
        minted += _mintAmount;
        ogMinted += _mintAmount;
    }

    function wlMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public mintCompliance(_mintAmount) {
        // Verify whitelist requirements
        require(mintStatus == 2, "The whitelist sale is not enabled!");
        require(wlMinted + _mintAmount <= wlSupply, "Max WL supply exceeded!");
        require(wlMintedByAddr[_msgSender()] + _mintAmount <= wlMintMax, "Mint amount exceeds maximum allowed per address!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, wlMerkleRoot, leaf), "Invalid proof!");

        _safeMint(_msgSender(), _mintAmount);
        wlMintedByAddr[_msgSender()] += _mintAmount;
        minted += _mintAmount;
        wlMinted += _mintAmount;        
    }

    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
        require(mintStatus == 3, "the public sale is not enabled!");
        require(mintedByAddr[_msgSender()] + _mintAmount <= mintMax, "Mint amount exceeds maximum allowed per address!");
        require(msg.value == cost * _mintAmount, "Insufficient balance");

        _safeMint(_msgSender(), _mintAmount);
        mintedByAddr[_msgSender()] += _mintAmount;
        minted += _mintAmount;
    }

    function devMint(uint256 _mintAmount) public mintCompliance(_mintAmount) onlyOwner {
        _safeMint(_msgSender(), _mintAmount);
        mintedByAddr[_msgSender()] += _mintAmount;
        minted += _mintAmount;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return hiddenMetadataUri;
        }

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

    function getMinted() public view returns (uint256) {
        return minted;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setOGMerkleRoot(bytes32 _ogMerkleRoot) public onlyOwner {
        ogMerkleRoot = _ogMerkleRoot;
    }

    function setWLMerkleRoot(bytes32 _wlMerkleRoot) public onlyOwner {
        wlMerkleRoot = _wlMerkleRoot;
    }

    function setMintStatus(uint256 _status) public onlyOwner {
        mintStatus = _status;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Transfer failed!");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}