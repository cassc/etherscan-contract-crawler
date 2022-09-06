// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

error MetaTrekkers__InvalidMintAmount();
error MetaTrekkers__MaxSupplyExceeded();
error MetaTrekkers__InsufficientFunds();
error MetaTrekkers__AllowlistSaleClosed();
error MetaTrekkers__AddressAlreadyClaimed();
error MetaTrekkers__InvalidProof();
error MetaTrekkers__PublicSaleClosed();
error MetaTrekkers__TransferFailed();
error MetaTrekkers__NonexistentToken();

/// @title An NFT collection example with ERC721A
/// @notice This contract reduces gas for minting NFTs
/// @dev This contract includes allowlist mint
contract MetaTrekkers is ERC721AQueryable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bool appendJson = false;

    /// Type declarations
    enum SaleState {
        Closed,
        AllowlistOnly,
        PublicOpen
    }

    /// State variables
    SaleState private sSaleState;

    uint256 private constant START_TOKEN_ID = 1;
    uint256 private immutable iMaxSupply;
    uint256 private sMintPrice;
    uint256 private sMaxMintAmountPerTx;
    string private sHiddenMetadataUri;
    string private sBaseUri;
    bytes32 private sMerkleRoot;
    bool private sRevealed;

    mapping(address => bool) private sAllowlistClaimed;

    /// Events
    event Mint(address indexed minter, uint256 amount);

    constructor(
        string memory nftName,
        string memory nftSymbol,
        string memory hiddenMetadataUri,
        uint256 maxSupply,
        uint256 mintPrice,
        uint256 maxMintAmountPerTx
    ) ERC721A(nftName, nftSymbol) {
        iMaxSupply = maxSupply;
        sMintPrice = mintPrice;
        sMaxMintAmountPerTx = maxMintAmountPerTx;
        sHiddenMetadataUri = hiddenMetadataUri;
        sSaleState = SaleState.Closed;
    }

    /// Modifiers
    modifier mintCompliance(uint256 _mintAmount, uint256 _maxMintAmount) {
        if (_mintAmount < 1 || _mintAmount > _maxMintAmount)
            revert MetaTrekkers__InvalidMintAmount();

        if (totalSupply() + _mintAmount > iMaxSupply)
            revert MetaTrekkers__MaxSupplyExceeded();

        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        if (msg.value < sMintPrice * _mintAmount)
            revert MetaTrekkers__InsufficientFunds();

        _;
    }

    /// Functions
    function allowlistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        mintCompliance(_mintAmount, sMaxMintAmountPerTx)
        mintPriceCompliance(_mintAmount)
    {
        if (sSaleState != SaleState.AllowlistOnly)
            revert MetaTrekkers__AllowlistSaleClosed();

        if (sAllowlistClaimed[_msgSender()])
            revert MetaTrekkers__AddressAlreadyClaimed();

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

        if (!MerkleProof.verify(_merkleProof, sMerkleRoot, leaf))
            revert MetaTrekkers__InvalidProof();

        sAllowlistClaimed[_msgSender()] = true;

        _safeMint(_msgSender(), _mintAmount);

        emit Mint(_msgSender(), _mintAmount);
    }

    function publicMint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount, sMaxMintAmountPerTx)
        mintPriceCompliance(_mintAmount)
    {
        if (sSaleState != SaleState.PublicOpen)
            revert MetaTrekkers__PublicSaleClosed();

        _safeMint(_msgSender(), _mintAmount);

        emit Mint(_msgSender(), _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount, sMaxMintAmountPerTx)
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ''
        );
        if (!success) revert MetaTrekkers__TransferFailed();
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert MetaTrekkers__NonexistentToken();

        if (sRevealed == false) return sHiddenMetadataUri;

        if (appendJson) {
            return
                bytes(_baseURI()).length > 0
                    ? string(
                        abi.encodePacked(_baseURI(), _tokenId.toString(), '.json')
                    )
                    : '';
        }
        else {
            return string(abi.encodePacked(_baseURI(), _tokenId.toString()));
        }

    }

    function toggleJson(bool _status) public onlyOwner {
        appendJson = _status;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return sBaseUri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return START_TOKEN_ID;
    }

    /// Getter Functions
    function getSaleState() public view returns (SaleState) {
        return sSaleState;
    }

    function getMaxSupply() public view returns (uint256) {
        return iMaxSupply;
    }

    function getMintPrice() public view returns (uint256) {
        return sMintPrice;
    }

    function getMaxMintAmountPerTx() public view returns (uint256) {
        return sMaxMintAmountPerTx;
    }

    function getHiddenMetadataUri() public view returns (string memory) {
        return sHiddenMetadataUri;
    }

    function getBaseUri() public view returns (string memory) {
        return sBaseUri;
    }

    function getMerkleRoot() public view returns (bytes32) {
        return sMerkleRoot;
    }

    function getRevealed() public view returns (bool) {
        return sRevealed;
    }

    /// Setter Functions
    function setAllowlistOnly() public onlyOwner {
        sSaleState = SaleState.AllowlistOnly;
    }

    function setPublicOpen() public onlyOwner {
        sSaleState = SaleState.PublicOpen;
    }

    function setClosed() public onlyOwner {
        sSaleState = SaleState.Closed;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        sMintPrice = _mintPrice;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        sMaxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        sHiddenMetadataUri = _hiddenMetadataUri;
    }

    function setBaseUri(string memory _baseUri) public onlyOwner {
        sBaseUri = _baseUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        sMerkleRoot = _merkleRoot;
    }

    function setRevealed(bool _state) public onlyOwner {
        sRevealed = _state;
    }
}