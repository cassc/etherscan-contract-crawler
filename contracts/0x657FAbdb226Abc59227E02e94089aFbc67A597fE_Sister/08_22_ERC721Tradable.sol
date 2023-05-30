// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";

import "./RandomlyAssigned.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is
    ContextMixin,
    ERC721Enumerable,
    NativeMetaTransaction,
    Ownable,
    RandomlyAssigned
{
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public CONSTRUCTED_AT;
    uint256 public FULL_METADATA_REVEAL_TIMESTAMP;
    uint256 public DEFAULT_DAYS_UNTIL_FULL_METADATA_REVEAL = 4;

    /// @dev The initial content identifier of the folder containing image-only metadata
    string public initialCID;

    /// @dev The final content identifier of the folder containing full metadata
    string public finalCID;

    /// @dev The master content identifier, referenced in baseURI
    string public masterCID;

    /// @dev Prevents baseURI metadata from ever being changed again.
    bool public metadataIsPermanentlyFrozen;

    address proxyRegistryAddress;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        string memory _initialCID,
        string memory _finalCID,
        uint256 amount,
        uint256 startFrom
    ) ERC721(_name, _symbol) RandomlyAssigned(amount, startFrom) {
        proxyRegistryAddress = _proxyRegistryAddress;

        CONSTRUCTED_AT = block.timestamp;
        FULL_METADATA_REVEAL_TIMESTAMP =
            CONSTRUCTED_AT +
            (86400 * DEFAULT_DAYS_UNTIL_FULL_METADATA_REVEAL);

        metadataIsPermanentlyFrozen = false;
        initialCID = _initialCID;
        finalCID = _finalCID;
        masterCID = _initialCID;

        _initializeEIP712(_name);
    }

    function nextToken() internal override(RandomlyAssigned) returns (uint256) {
        return RandomlyAssigned.nextToken();
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to, uint256 amount) public onlyOwner {
        for (uint256 index = 0; index < amount; index++) {
            _safeMint(_to, nextToken());
        }

        uint256 nowInEpochSeconds = block.timestamp;
        if (
            availableTokenCount() == 0 ||
            nowInEpochSeconds >= FULL_METADATA_REVEAL_TIMESTAMP
        ) {
            _setMasterCIDAsFinalCID();
        }
    }

    function setFullMetadataRevealTimestamp(uint256 _revealTimestampOverride)
        public
        onlyOwner
    {
        FULL_METADATA_REVEAL_TIMESTAMP = _revealTimestampOverride;
    }

    function emergencyOverrideMasterCID(string memory _metadataCID)
        public
        onlyOwner
    {
        require(
            !metadataIsPermanentlyFrozen,
            "Metadata is permanently frozen."
        );
        masterCID = _metadataCID;
    }

    /*
     * After we are sure metadata is sound, prevent changing it forever.
     */
    function freezeMetadataPermanently() public onlyOwner {
        require(
            !metadataIsPermanentlyFrozen,
            "Metadata is already permanently frozen."
        );
        metadataIsPermanentlyFrozen = true;
    }

    // called after last token is minted
    function _setMasterCIDAsFinalCID() internal virtual {
        require(
            !metadataIsPermanentlyFrozen,
            "Metadata is permanently frozen."
        );
        masterCID = finalCID;
    }

    function totalSupply()
        public
        view
        override(ERC721Enumerable, WithLimitedSupply)
        returns (uint256)
    {
        return WithLimitedSupply.totalSupply();
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return string(abi.encodePacked("ipfs://", masterCID));
    }

    function baseTokenURI() public view virtual returns (string memory);

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return string(abi.encodePacked(_baseURI(), "/", tokenId.toString()));
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }
}