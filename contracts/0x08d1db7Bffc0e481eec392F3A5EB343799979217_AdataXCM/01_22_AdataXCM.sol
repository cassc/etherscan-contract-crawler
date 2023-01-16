// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract AdataXCM is
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using StringsUpgradeable for uint256;

    uint256 public _currentIndex;
    uint256 public _maxSupply;
    address public _rareMinter;
    uint256 public _rareMintStartTime;
    uint256 public _rareMintPrice;
    string private _baseURIExtended;

    mapping(address => bool) private _minters;

    event Minted(address to, uint256 tokenId);

    modifier onlyMinter() {
        require(_minters[msg.sender], "Permission error: not minter");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC721_init("XPG Crypto Mera", "XCM");
        __ERC721Enumerable_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        _minters[msg.sender] = true;
        _maxSupply = 1001;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    // Rare Mint Section
    function rareMintPrice() public view returns (uint256) {
        return _rareMintPrice;
    }

    function rareMint(address to)
        external
        payable
        nonReentrant
    {
        require(msg.sender == tx.origin, "Runtime error: contract not allowed");
        require(msg.sender == _rareMinter, "Permission error: not rare minter");
        require(msg.value >= _rareMintPrice, "Runtime error: ether not enough");
        require(
            block.timestamp > _rareMintStartTime,
            "Runtime error: rare mint not started"
        );
        require(!_exists(1001), "Runtime error: already minted");
        _mint(to, 1001);
        emit Minted(to, 1001);
    }

    function setRareMint(
        address rareMinter_,
        uint256 rareMintStartTime_,
        uint256 rareMintPrice_
    ) external onlyOwner {
        _rareMinter = rareMinter_;
        _rareMintStartTime = rareMintStartTime_;
        _rareMintPrice = rareMintPrice_;
    }

    // Token Section
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
        require(bytes(_baseURI()).length != 0, "Runtime error: baseURI not set");
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }

    function mint(address to, uint256 quantity) external onlyMinter {
        uint256 reversed = _exists(1001) ? 0 : 1;
        require(
            totalSupply() + quantity <= _maxSupply - reversed,
            "Runtime error: exceeds max supply"
        );
        uint256 tokenId = _currentIndex + 1;
        _currentIndex += quantity;
        for (; tokenId <= _currentIndex; tokenId++) {
            _mint(to, tokenId);
            emit Minted(to, tokenId);
        }
    }

    function setMinter(address minter, bool accessible) external onlyOwner {
        _minters[minter] = accessible;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }

    function withdraw(address to) public onlyOwner {
        (bool sent, ) = to.call{value: address(this).balance}("");
        require(sent, "Runtime error: withdraw failed");
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}