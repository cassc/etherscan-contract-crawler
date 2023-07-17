// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "./interfaces/IAltavaLandNFT.sol";

contract AltavaLandNFT721 is
    Initializable,
    IAltavaLandNFT,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ERC721BurnableUpgradeable
{
    using SafeMathUpgradeable for uint256;

    //============================================//
    //
    // Properties
    //
    //============================================//

    event mintByOwnerEvent(
        address indexed owner,
        address indexed to,
        uint256 indexed tokenId
    );
    event mintByMarketEvent(
        address indexed market,
        address indexed to,
        uint256 indexed tokenId
    );

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter internal _tokenNumCounter;

    string internal __baseURI;

    address internal _landMarket;

    struct MintUnit {
        address to;
        uint256 tokenId;
    }

    //============================================//
    //
    // Constructor
    //
    //============================================//

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory baseURI) public initializer {
        __ERC721_init("Altava Land", "AltavaLand");
        __ERC721URIStorage_init();
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();

        __baseURI = baseURI;
    }

    //============================================//
    //
    // Modifier
    //
    //============================================//

    modifier onlyMarket() {
        require(
            msg.sender == _landMarket,
            "AltavaLandNFT: caller is not the market contract"
        );
        _;
    }

    //============================================//
    //
    // Methods
    //
    //============================================//

    /**
     * 메타데이터의 URI 수정
     */
    function setBaseURI(string memory baseURI) public virtual onlyOwner {
        __baseURI = baseURI;
    }

    /**
     * market contract 설정
     */
    function setLandMarket(address landMarket) public virtual onlyOwner {
        _landMarket = landMarket;
    }

    /**
     * market에 의해 NFT 발행
     */
    function mintByMarket(
        address to,
        uint256 tokenId
    ) public virtual override onlyMarket {
        _mint(to, tokenId);
        _tokenNumCounter.increment();

        emit mintByMarketEvent(msg.sender, to, tokenId);
    }

    /**
     * 오너에 의해 NFT 발행
     */
    function mintByOwner(address to, uint256 tokenId) public virtual onlyOwner {
        _safeMint(to, tokenId);
        _tokenNumCounter.increment();

        emit mintByOwnerEvent(msg.sender, to, tokenId);
    }

    /**
     * 오너에 의해 여러개 NFT 발행
     */
    function batchMintByOwner(
        MintUnit[] memory mintUnit
    ) public virtual onlyOwner {
        for (uint256 i = 0; i < mintUnit.length; i++) {
            _safeMint(mintUnit[i].to, mintUnit[i].tokenId);
            _tokenNumCounter.increment();

            emit mintByOwnerEvent(
                msg.sender,
                mintUnit[i].to,
                mintUnit[i].tokenId
            );
        }
    }

    //============================================//
    //
    // Override Methods
    //
    //============================================//

    // PausableUpgradeable
    function pause() public virtual onlyOwner {
        _pause();
    }

    // PausableUpgradeable
    function unpause() public virtual onlyOwner {
        _unpause();
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _burn(
        uint256 tokenId
    )
        internal
        virtual
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        _tokenNumCounter.decrement();
        super._burn(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return __baseURI;
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function totalSupply() public view virtual returns (uint256) {
        return _tokenNumCounter.current();
    }

    uint256[47] private __gap;
}