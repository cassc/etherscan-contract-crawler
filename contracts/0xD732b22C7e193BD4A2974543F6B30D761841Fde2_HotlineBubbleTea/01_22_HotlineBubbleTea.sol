// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract HotlineBubbleTea is
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using StringsUpgradeable for uint256;

    address public _minter;
    uint256 public _currentIndex;
    uint256 public _maxSupply;
    string private _baseURIExtended;
    string private _blindboxImageURI;

    mapping(uint256 => bool) private _shown;

    event Minted(address to, uint256 tokenId);

    modifier onlyMinter() {
        require(msg.sender == _minter, "Permission error: not minter");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC721_init("Hotline Bubble Tea", "HBT");
        __ERC721Enumerable_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        _minter = msg.sender;
        _maxSupply = 304;

        // Reserved tokens
        _currentIndex = 50;
        for (uint256 i = 1; i <= 50; i++) {
            _mint(msg.sender, i);
            emit Minted(msg.sender, i);
        }
    }

    function mint(address to, uint256 quantity) external onlyMinter {
        require(
            totalSupply() + quantity <= _maxSupply,
            "Runtime error: exceeds max supply"
        );
        uint256 tokenId = _currentIndex + 1;
        _currentIndex += quantity;
        for (; tokenId <= _currentIndex; tokenId++) {
            _mint(to, tokenId);
            emit Minted(to, tokenId);
        }
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return _shown[tokenId] ? _tokenURI(tokenId) : _blindboxURI(tokenId);
    }

    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        string memory base = _baseURI();
        require(bytes(base).length != 0, "Runtime error: baseURI not set");
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function _blindboxURI(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        require(
            bytes(_blindboxImageURI).length != 0,
            "Runtime error: blindboxImageURI not set"
        );
        string memory json = Base64Upgradeable.encode(
            abi.encodePacked(
                '{"name":"Bubble Tea #',
                tokenId.toString(),
                '","description":"Hotline is the first Taiwanese NGO focus on LGBTQ+ right. For the past 25 years, it had been working to enhance the overall LGBTQ+ right in Taiwan and now we are stepping into the metaverse!","image":"',
                _blindboxImageURI,
                '"}'
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function setMinter(address minter) external onlyOwner {
        _minter = minter;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }

    function setBlindboxImageURI(string memory blindboxImageURI_)
        external
        onlyOwner
    {
        _blindboxImageURI = blindboxImageURI_;
    }

    function hide(uint256[] calldata tokenIds) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++)
            _shown[tokenIds[i]] = false;
    }

    function show(uint256[] calldata tokenIds) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++)
            _shown[tokenIds[i]] = true;
    }

    function withdraw() public onlyOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Runtime error: withdraw failed");
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}