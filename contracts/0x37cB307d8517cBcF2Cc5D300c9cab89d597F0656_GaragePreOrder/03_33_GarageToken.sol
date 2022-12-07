// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./strings.sol";
import "./opensea/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

/// @custom:security-contact [email protected]
contract GarageToken is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    DefaultOperatorFiltererUpgradeable
{
    using strings for *;

    // ===============
    // == Variables ==

    address public factory;
    uint256 private counter;

    // ==============
    // == Mappings ==

    mapping(uint16 => uint256) public categoryCount;
    mapping(uint256 => uint16) public categoryForToken;
    mapping(uint256 => uint256) public tokenIdToCategoryId;
    mapping(uint16 => mapping(uint256 => uint256)) categoryIdToToken;

    // ===============
    // == Modifiers ==

    modifier onlyFactory() {
        require(msg.sender == factory, "Not authorized");
        _;
    }

    // =============================
    // == Initalization Functions ==

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function categoryTypeToId(uint16 category, uint256 categoryId)
        external
        view
        returns (uint256)
    {
        return categoryIdToToken[category][categoryId];
    }

    function initialize(address _factory) public initializer {
        __ERC721_init("MyToken", "MTK");
        __ERC721Enumerable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        __DefaultOperatorFilterer_init();

        factory = _factory;
    }

    // ====================
    // == Internal Hooks ==

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // =============
    // == Minting ==

    function mintFor(
        address owner,
        uint256 size,
        uint16 category
    ) public onlyFactory {
        for (uint256 i = 0; i < size; i++) {
            counter++;
            uint256 tokenId = counter;
            _mint(owner, tokenId);

            categoryForToken[tokenId] = category;
            categoryCount[category] += 1;

            uint256 categoryId = categoryCount[category];
            tokenIdToCategoryId[tokenId] = categoryId;
            categoryIdToToken[category][categoryId] = tokenId;
        }
    }

    // =================================
    // == Functions for querying data ==

    function _baseURI() internal pure override returns (string memory) {
        return "https://vault.warriders.com/garageTitles/";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(exists(tokenId), "Token doesn't exist!");
        //Predict the token URI
        uint16 category = categoryForToken[tokenId];
        uint256 _categoryId = tokenIdToCategoryId[tokenId];

        string memory id = Strings
            .toString(category)
            .toSlice()
            .concat("/".toSlice())
            .toSlice()
            .concat(
                Strings
                    .toString(_categoryId)
                    .toSlice()
                    .concat(".json".toSlice())
                    .toSlice()
            );

        string memory _base = _baseURI();

        //Final URL: https://vault.warriders.com/guns/<category>/<category_id>.json
        string memory _metadata = _base.toSlice().concat(id.toSlice());

        return _metadata;
    }

    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](balanceOf(owner));

        for (uint256 i = 0; i < result.length; i++) {
            result[i] = tokenOfOwnerByIndex(owner, i);
        }

        return result;
    }

    function allTokens() external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](totalSupply());

        for (uint256 i = 0; i < result.length; i++) {
            result[i] = tokenByIndex(i);
        }

        return result;
    }

    // ====================================
    // == Functions required for OpenSea ==

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(IERC721Upgradeable, ERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(IERC721Upgradeable, ERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        override(IERC721Upgradeable, ERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}