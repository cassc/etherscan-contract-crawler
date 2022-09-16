// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

struct NftData {
    string uri;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    bool isFirstSale;
}

struct MintData {
    string uri;
    address minter;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    bool isFirstSale;
}

contract NiftySouq721V3 is ERC721Upgradeable, AccessControlUpgradeable {
    using Counters for Counters.Counter;

    event PayoutTransfer(address indexed withdrawer, uint256 indexed amount);

    string private _baseTokenURI;
    address internal _niftyMarketplace;
    address internal _owner;

    uint256 public constant PERCENT_UNIT = 1e4;

    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => NftData) public nftInfos;

    modifier isNiftyMarketplace() {
        require(msg.sender == _niftyMarketplace, "Nifty721:101A");
        _;
    }

    modifier validatePayouts(
        address[] calldata receivers_,
        uint256[] calldata percentage_
    ) {
        // make sure revenues and creators length are same.
        require(percentage_.length == receivers_.length, "Nifty721:102");

        // make sure all revenues and receivers are non zero.
        uint256 sum = 0;
        for (uint256 i = 0; i < percentage_.length; i++) {
            require(percentage_[i] > 0, "Nifty721:103");
            require(receivers_[i] != address(0), "Nifty721:104");
            sum = sum + percentage_[i];
        }

        require(sum <= PERCENT_UNIT, "Nifty721:105");
        _;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address niftySouqMarketplace_
    ) public initializer {
        __ERC721_init(name_, symbol_);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _owner = msg.sender;
        _baseTokenURI = baseURI_;
        _niftyMarketplace = niftySouqMarketplace_;
    }

    function setBaseURI(string memory baseUri_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Nifty721:101B");
        require(
            keccak256(abi.encodePacked(baseUri_)) !=
                keccak256(abi.encodePacked("")),
            "Nifty721:106"
        );
        _baseTokenURI = baseUri_;
    }

    function setNiftySouqAddress(address niftySouqMarketplace_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Nifty721:101B");
        require(niftySouqMarketplace_ != address(0), "Nifty721:100A");
        _niftyMarketplace = niftySouqMarketplace_;
    }

    function totalMinted() public view returns (uint256 totalMinted_) {
        totalMinted_ = _tokenIdCounter.current();
    }

    function getAll() public view returns (NftData[] memory nfts_) {
        for (uint256 i = 1; i < _tokenIdCounter.current(); i++) {
            nfts_[i] = nftInfos[i];
        }
    }

    function getNftInfo(uint256 tokenId_)
        public
        view
        returns (NftData memory nfts_)
    {
        nfts_ = nftInfos[tokenId_];
    }

    function exists(uint256 tokenId_) public view returns (bool exists_) {
        exists_ = _exists(tokenId_);
    }

    function tokenURI(uint256 tokenId_)
        public
        view
        override
        returns (string memory uri_)
    {
        require(_exists(tokenId_), "Nifty721:107");
        uri_ = string(abi.encodePacked(_baseTokenURI, nftInfos[tokenId_].uri));
    }

    function mint(MintData calldata mintData_)
        public
        validatePayouts(mintData_.investors, mintData_.revenues)
        validatePayouts(mintData_.creators, mintData_.royalties)
        isNiftyMarketplace
        returns (uint256 tokenId_)
    {
        require(
            keccak256(abi.encodePacked(mintData_.uri)) !=
                keccak256(abi.encodePacked("")),
            "Nifty721:106"
        );
        _tokenIdCounter.increment();
        tokenId_ = _tokenIdCounter.current();
        _safeMint(mintData_.minter, tokenId_);

        nftInfos[tokenId_] = NftData(
            mintData_.uri,
            mintData_.creators,
            mintData_.royalties,
            mintData_.investors,
            mintData_.revenues,
            mintData_.isFirstSale
        );
    }

    function transferNft(
        address from_,
        address to_,
        uint256 tokenId_
    ) public isNiftyMarketplace {
        _transfer(from_, to_, tokenId_);
        if (nftInfos[tokenId_].isFirstSale)
            nftInfos[tokenId_].isFirstSale = false;
    }

    function updateRoyalties(
        uint256 tokenId_,
        address[] calldata creators_,
        uint256[] calldata royalties_
    ) external validatePayouts(creators_, royalties_) {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                nftInfos[tokenId_].creators[0] == msg.sender,
            "Nifty721:101BD"
        );
        nftInfos[tokenId_].creators = creators_;
        nftInfos[tokenId_].royalties = royalties_;
    }

    function updateTokenURI(uint256 tokenId_, string memory uri_) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Nifty721:101B");

        nftInfos[tokenId_].uri = uri_;
    }

    function burn(uint256 tokenId_) public {
        require(ownerOf(tokenId_) == _msgSender(), "Nifty721:101C");
        delete nftInfos[tokenId_];
        _burn(tokenId_);
    }

    function supportsInterface(bytes4 interfaceId_)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return
            ERC721Upgradeable.supportsInterface(interfaceId_) ||
            AccessControlUpgradeable.supportsInterface(interfaceId_);
    }
}