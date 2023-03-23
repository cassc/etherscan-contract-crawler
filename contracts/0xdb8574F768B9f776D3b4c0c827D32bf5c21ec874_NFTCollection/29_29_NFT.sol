// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./IERC4906.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFTCollection is
    Initializable,
    IERC721MetadataUpgradeable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    OwnableUpgradeable,
    ERC721RoyaltyUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC4906
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    uint public price; // Price

    uint public maxSupply; // Max supply of NFTs
    address payable public fundReceiver; // Address to receive the minting amount

    //Base URI
    string baseURI_;

    // contractURI
    string public contractURI;

    string _hiddenURI;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address payable _fundReceiver,
        address receiver,
        uint96 feeNumerator,
        uint _maxSupply,
        uint _price,
        string calldata _contractURI,
        string calldata hiddenURI_
    ) public initializer {
        __ERC721_init("AL FARES", "SAKA");
        __ERC721Enumerable_init();
        __ERC721Burnable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        _setDefaultRoyalty(receiver, feeNumerator);
        maxSupply = _maxSupply;
        price = _price;
        contractURI = _contractURI;
        _hiddenURI = hiddenURI_;
        fundReceiver = _fundReceiver;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }

    function setMaxSupply(uint _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setBaseURI(string memory _baseURI_) external onlyOwner {
        baseURI_ = _baseURI_;
        // Opensea metadata refresh
        emit BatchMetadataUpdate(1, type(uint256).max);
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    function totalMinted() external view returns (uint) {
        return _tokenIdCounter.current();
    }

    function mint(uint _quantity) external payable nonReentrant {
        // Check if the quantity allowed
        require(
            _tokenIdCounter.current() + _quantity <= maxSupply,
            "NFT supply exausted"
        );
        if (msg.sender != owner()) {
            // check for price
            require(msg.value >= _quantity * price, "Insufficient fund");
        }

        // Mint the NFTs
        for (uint i = 0; i < _quantity; i++) {
            _tokenIdCounter.increment();
            _mint(msg.sender, _tokenIdCounter.current());
        }
        // Transfer the ETH to fundReceiver
        fundReceiver.transfer(msg.value);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721RoyaltyUpgradeable) {
        super._burn(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            ERC721RoyaltyUpgradeable,
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            IERC165Upgradeable
        )
        returns (bool)
    {
        return
            interfaceId == bytes4(0x49064906) ||
            super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI_;
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, IERC721MetadataUpgradeable)
        returns (string memory)
    {
        _requireMinted(tokenId);

        // If there is no base URI, return the token URI.
        if (bytes(baseURI_).length == 0) {
            return _hiddenURI;
        } else {
            return
                string(
                    abi.encodePacked(
                        baseURI_,
                        Strings.toString(tokenId),
                        ".json"
                    )
                );
        }
    }
}