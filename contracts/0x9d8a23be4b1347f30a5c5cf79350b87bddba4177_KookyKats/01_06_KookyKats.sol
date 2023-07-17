// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract KookyKats is ERC721A, Ownable {
    using Strings for uint256;

    /// @dev KooKyKats NFT max supply
    uint256 public immutable MAX_SUPPLY;

    /// @dev KooKyKats NFT Royalty 2.5%
    uint256 public immutable ROYALTY;

    /// @dev TokenId of revealting tokenURI
    uint256 public revealURITokenId;

    /// @dev KooKyKats NFT Base Token URI
    string public baseURI;

    /// @dev KookyKats NFT placeholder token URI
    string public placeholderURI;

    /// @dev Royalty receiver address
    address public royaltyReceiver;

    /// @dev KooKyKats minter addresses
    mapping(address => bool) public minters;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _royalty
    ) ERC721A(_name, _symbol) {
        MAX_SUPPLY = _maxSupply;
        ROYALTY = _royalty;
        addMinter(_msgSender());
        royaltyReceiver = _msgSender();
    }

    // ----------------- EXTERNAL -----------------

    /// @dev Add new minter
    function addMinter(address _minter) public onlyOwner {
        require(!minters[_minter], "Already added");
        minters[_minter] = true;
        emit AddedMinter(_minter);
    }

    /// @dev Remove minter
    function removeMinter(address _minter) external onlyOwner {
        require(minters[_minter], "Not added yet");
        minters[_minter] = false;
        emit RemovedMinter(_minter);
    }

    /// @dev Set base tokenURI
    function setBaseTokenURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
        emit SetBaseTokenURI(_uri);
    }

    /// @dev Set placeholder tokenURI
    function setPlaceholderTokenURI(string memory _uri) external onlyOwner {
        placeholderURI = _uri;
        emit SetPlaceholderTokenURI(_uri);
    }

    /// @dev Set tokenID of revealing tokenURI
    function setRevealURITokenId(uint256 _tokenId) external onlyOwner {
        revealURITokenId = _tokenId;
        emit SetURIRevealTokenId(_tokenId);
    }

    /// @dev Set KooKyKats Royalty receiver
    function setRoyaltyReceiver(address _receiver) external onlyOwner {
        require(_receiver != address(0), "Invalid receiver address");
        royaltyReceiver = _receiver;
    }

    /// @dev Mint KooKyKats
    function mint(address _who, uint256 _amount)
        external
        onlyMinter
        onlyUnderMaxSupply(_amount)
    {
        _safeMint(_who, _amount);
    }

    // ----------------- VIEW -----------------

    /// @dev Set starting tokenId as 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @dev Get Token URI
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();
        string memory uri;
        if (revealURITokenId >= _tokenId) {
            uri = baseURI;
        } else {
            uri = placeholderURI;
        }

        return string(abi.encodePacked(uri, _tokenId.toString()));
    }

    /// @dev KooKyKats Royalty info
    function royaltyInfo(uint256, uint256 _salePrice)
        public
        view
        virtual
        returns (address, uint256)
    {
        uint256 royaltyAmount = (_salePrice * ROYALTY) / 10000;
        return (royaltyReceiver, royaltyAmount);
    }

    // ----------------- MODIFIER -----------------

    modifier onlyMinter() {
        require(minters[_msgSender()], "Only minter");
        _;
    }

    modifier onlyUnderMaxSupply(uint256 _amount) {
        require(totalSupply() + _amount <= MAX_SUPPLY, "Overflow Max Supply");
        _;
    }

    // ----------------- EVENTS -----------------
    event AddedMinter(address minter);
    event RemovedMinter(address minter);
    event SetBaseTokenURI(string baseURI);
    event SetPlaceholderTokenURI(string placeholderURI);
    event SetURIRevealTokenId(uint256 tokenId);
}