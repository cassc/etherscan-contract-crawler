// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./vendors/ERC721Initializable.sol";
import "./vendors/access/ManagerLikeOwner.sol";
import "./vendors/utils/CompareStrings.sol";
import "./interfaces/IWinePool.sol";
import "./interfaces/IWineManager.sol";
import "./interfaces/IWineFactory.sol";
import "./interfaces/IBordeauxCityBondIntegration.sol";
import "./WinePoolParts/WineStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract WinePoolCode is
    ERC721Initializable,
    ManagerLikeOwner,
    Pausable,
    IWinePool,
    WineStorage
{
    using CompareStrings for string;
    using Strings for uint256;

//////////////////////////////////////// DescriptionFields


    function updateAllDescriptionFields(
        string memory wineName,
        string memory wineProductionCountry,
        string memory wineProductionRegion,
        string memory wineProductionYear,
        string memory wineProducerName,
        string memory wineBottleVolume,
        string memory linkToDocuments
    )
        public override
        onlyManager
    {
        setStorage(WINE_NAME, wineName);
        setStorage(WINE_PRODUCTION_COUNTRY, wineProductionCountry);
        setStorage(WINE_PRODUCTION_REGION, wineProductionRegion);
        setStorage(WINE_PRODUCTION_YEAR, wineProductionYear);
        setStorage(WINE_PRODUCTION_NAME, wineProducerName);
        setStorage(WINE_PRODUCTION_VOLUME, wineBottleVolume);
        setStorage(LINK_TO_DOCUMENTS, linkToDocuments);
    }

    function editDescriptionField(bytes32 param, string memory value)
        public override
        onlyManager
    {
        if (param == "wineName") {
            setStorage(WINE_NAME, value);
        } else if (param == "wineProductionCountry") {
            setStorage(WINE_PRODUCTION_COUNTRY, value);
        } else if (param == "wineProductionRegion") {
            setStorage(WINE_PRODUCTION_REGION, value);
        } else if (param == "wineProductionYear") {
            setStorage(WINE_PRODUCTION_YEAR, value);
        } else if (param == "wineProducerName") {
            setStorage(WINE_PRODUCTION_NAME, value);
        } else if (param == "wineBottleVolume") {
            setStorage(WINE_PRODUCTION_VOLUME, value);
        } else if (param == "linkToDocuments") {
            setStorage(LINK_TO_DOCUMENTS, value);
        } else revert("editDescriptionField: unrecognized-param");
    }

//////////////////////////////////////// System fields

    uint256 public override getPoolId;
    uint256 public override getMaxTotalSupply;
    uint256 public override getWinePrice;

    function _initializeSystemFields(
        uint256 poolId,
        uint256 maxTotalSupply,
        uint256 winePrice
    ) internal {
        getPoolId = poolId;
        getMaxTotalSupply = maxTotalSupply;
        getWinePrice = winePrice;
    }

    function editMaxTotalSupply(uint256 value)
        override
        public
        onlyManager enabled
    {
        require(value >= tokensCount, "editMaxTotalSupply: tokensCount > value");
        getMaxTotalSupply = value;
    }
    function editWinePrice(uint256 value)
        override
        public
        onlyManager
    {
        getWinePrice = value;
    }

//////////////////////////////////////// Pausable

    function pause()
        public override
        onlyOwner
    {
        _pause();
    }

    function unpause()
        public override
        onlyOwner
    {
        _unpause();
    }

    function _transfer(address from, address to, uint256 tokenId)
        internal virtual override
        whenNotPaused()
    {
        super._transfer(from, to, tokenId);
    }

    function _mint(address to, uint256 tokenId)
        internal virtual override
        whenNotPaused()
    {
        super._mint(to, tokenId);
        IBordeauxCityBondIntegration(IWineManager(manager()).bordeauxCityBond()).onMint(getPoolId, tokenId);
    }

    function _burn(uint256 tokenId)
        internal virtual override
        whenNotPaused()
    {
        super._burn(tokenId);
    }

//////////////////////////////////////// Initialize

    function initialize(
        string memory name,
        string memory symbol,

        address manager,

        uint256 poolId,
        uint256 maxTotalSupply,
        uint256 winePrice
    )
        override
        public payable
        initializer
        returns (bool)
    {
        _initializeManager(manager);

        _initializeInheritedOwner(_msgSender());
        _initializeERC721(name, symbol);
        _initializeSystemFields(
            poolId,
            maxTotalSupply,
            winePrice
        );
        disabled = false;
        return true;
    }

//////////////////////////////////////// Disable

    bool public override disabled;

    modifier onlyFactory() {
        require(IWineManager(manager()).factory() == _msgSender(), "OnlyFactory: caller is not the factory");
        _;
    }

    modifier enabled() {
        require(disabled == false, "enabled: contract is disabled");
        _;
    }

    function disablePool()
        override
        public
        onlyFactory
    {
        getMaxTotalSupply = tokensCount;
        if (tokensCount == 0) {
            _pause();
        }
        disabled = true;
    }

//////////////////////////////////////// ERC721

    function _baseURI()
        virtual override
        internal view
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                IWineFactory(IWineManager(manager()).factory()).baseUri(),
                getPoolId.toString(),
                "/"
            )
        );
    }

//////////////////////////////////////// default methods

    uint256 public override tokensCount;
    modifier tokenIdExists(uint256 tokenId) {
        require(_exists(tokenId), "tokenIdExists: tokenId is not exists");
        _;
    }

    modifier onlyMinter() {
        require(IWineManager(manager()).allowMint(_msgSender()), "onlyMinter: caller is not the minter");
        _;
    }

    modifier onlyAllowInternalTransfers() {
        require(IWineManager(manager()).allowInternalTransfers(_msgSender()), "onlyAllowInternalTransfers: caller is not the minter");
        _;
    }

    modifier onlyAllowBurn() {
        require(IWineManager(manager()).allowBurn(_msgSender()), "onlyMinter: caller is not the minter");
        _;
    }

    function mint(address to)
        override
        public
        onlyMinter
    {
        uint256 tokenId = tokensCount;
        ++tokensCount;

        require(tokensCount <= getMaxTotalSupply, "mint: maxTotalSupply limit");

        _mint(to, tokenId);
        emit WinePoolMintToken(to, tokenId, getPoolId);
    }

    function burn(uint256 tokenId)
        override
        public
        onlyAllowBurn tokenIdExists(tokenId)
    {
        require(ownerOf(tokenId) == _msgSender(), "ERC721: burn of token that is not own");
        _burn(tokenId);
    }

//////////////////////////////////////// internal users and tokens

    mapping(address => bool) public override internalUsersExists;
    mapping(uint256 => address) public override internalOwnedTokens;

    function mintToInternalUser(address internalUser)
        override
        public
        onlyMinter
    {
        uint256 tokenId = tokensCount;
        ++tokensCount;

        require(tokensCount <= getMaxTotalSupply, "mint: maxTotalSupply limit");

        _mint(address(this), tokenId);

        internalOwnedTokens[tokenId] = internalUser;
        internalUsersExists[internalUser] = true;

        emit WinePoolMintTokenToInternal(internalUser, tokenId, getPoolId);
    }

    function transferInternalToInternal(address internalFrom, address internalTo, uint256 tokenId)
        override
        public
        tokenIdExists(tokenId) onlyManager whenNotPaused
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "_transferInternalToInternal - transfer caller is not owner nor approved");
        require(internalOwnedTokens[tokenId] == internalFrom, "_transferInternalToInternal - transfer of token that is not owned this innerUser");
        require(internalUsersExists[internalTo], "_transferInternalToInternal - innerUser is not exists");

        internalOwnedTokens[tokenId] = internalTo;
        emit InternalToInternalTransfer(internalFrom, internalTo, tokenId, getPoolId);
    }

    function transferOuterToInternal(address outerFrom, address internalTo, uint256 tokenId)
        override
        public
        tokenIdExists(tokenId)
    {
        require(internalUsersExists[internalTo], "_transferOuterToInternal - innerUser is not exists");

        transferFrom(outerFrom, address(this), tokenId);
        internalOwnedTokens[tokenId] = internalTo;
        emit OuterToInternalTransfer(outerFrom, internalTo, tokenId, getPoolId);
    }

    function transferInternalToOuter(address internalFrom, address outerTo, uint256 tokenId)
        override
        public
        tokenIdExists(tokenId) onlyAllowInternalTransfers
    {
        require(internalOwnedTokens[tokenId] == internalFrom, "_transferInternalToOuter - transfer of token that is not owned this innerUser");

        safeTransferFrom(address(this), outerTo, tokenId);
        internalOwnedTokens[tokenId] = address(0);
        emit InternalToOuterTransfer(internalFrom, outerTo, tokenId, getPoolId);
    }


////////////////////////////////////////

    function isApprovedForAll(address owner, address operator)
        virtual override
        public view
        returns (bool)
    {
        if (owner == address(this) && IWineManager(manager()).allowInternalTransfers(operator)) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

}