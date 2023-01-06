// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import "./openzeppelin/contracts/access/Ownable.sol";
import "./openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./interfaces/ICapsuleFactory.sol";
import "./interfaces/ICapsule.sol";
import "./interfaces/IMetadataProvider.sol";

contract Capsule is ERC721URIStorage, ERC721Enumerable, Ownable, ICapsule {
    // solhint-disable-next-line var-name-mixedcase
    string public VERSION;
    string public constant LICENSE = "www.capsulenft.com/license";
    ICapsuleFactory public immutable factory;
    /// @notice Token URI owner can change token URI of any NFT.
    address public tokenURIOwner;
    string public baseURI;
    uint256 public counter;
    /// @notice The Token URI owner is also able to deflect tokenURI calls to an external contract, address specified here
    address public metadataProvider;
    /// @notice Max possible NFT id of this collection
    uint256 public maxId = type(uint256).max;
    /// @notice Flag indicating whether this collection is private.
    bool public immutable isCollectionPrivate;
    /// @notice Address which can receive NFT royalties using the EIP-2981 standard
    address public royaltyReceiver;
    /// @notice Percentage amount of royalties (using 2 decimals: 10000 = 100) using the EIP-2981 standard
    uint256 public royaltyRate = 0;

    uint256 internal constant MAX_BPS = 10_000; // 100%

    event RoyaltyConfigUpdated(
        address indexed oldReceiver,
        address indexed newReceiver,
        uint256 oldRate,
        uint256 newRate
    );
    event TokenURIOwnerUpdated(address indexed oldOwner, address indexed newOwner);
    event TokenURIUpdated(uint256 indexed tokenId, string oldTokenURI, string newTokenURI);
    event BaseURIUpdated(string oldBaseURI, string newBaseURI);
    event CollectionLocked(uint256 nftCount);
    event MetadataProviderUpdated(address metadataProvider);

    constructor(
        string memory _name,
        string memory _symbol,
        address _tokenURIOwner,
        bool _isCollectionPrivate
    ) ERC721(_name, _symbol) {
        isCollectionPrivate = _isCollectionPrivate;
        factory = ICapsuleFactory(_msgSender());
        // Address zero as tokenURIOwner is valid
        tokenURIOwner = _tokenURIOwner;
        VERSION = ICapsuleFactory(_msgSender()).VERSION();
    }

    modifier onlyMinter() {
        require(factory.capsuleMinter() == _msgSender(), "!minter");
        _;
    }

    modifier onlyTokenURIOwner() {
        require(tokenURIOwner == _msgSender(), "caller is not tokenURI owner");
        _;
    }

    /******************************************************************************
     *                              Read functions                                *
     *****************************************************************************/

    /// @notice Check whether given tokenId exists.
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /// @notice Check if the Capsule collection is locked.
    /// @dev This is checked by ensuring the counter is greater than the maxId.
    function isCollectionLocked() public view returns (bool) {
        return counter > maxId;
    }

    /// @notice Check whether given address is owner of this collection.
    function isCollectionMinter(address _account) external view returns (bool) {
        if (isCollectionPrivate) {
            return owner() == _account;
        }
        return true;
    }

    /// @notice Returns tokenURI of given tokenId.
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        if (metadataProvider != address(0)) {
            return IMetadataProvider(metadataProvider).tokenURI(tokenId);
        }
        
        return ERC721URIStorage.tokenURI(tokenId);
    }

    /// @inheritdoc IERC2981
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltyReceiver, (_salePrice * royaltyRate) / MAX_BPS);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return (interfaceId == type(IERC2981).interfaceId || ERC721Enumerable.supportsInterface(interfaceId));
    }

    /******************************************************************************
     *                             Minter functions                               *
     *****************************************************************************/

    /// @notice onlyMinter:: Burn Capsule with given tokenId from given account
    function burn(address _account, uint256 _tokenId) external onlyMinter {
        require(ERC721.ownerOf(_tokenId) == _account, "not NFT owner");
        _burn(_tokenId);
    }

    /// @notice onlyMinter:: Mint new Capsule to given account
    function mint(address _account, string calldata _uri) external onlyMinter {
        require(!isCollectionLocked(), "collection is locked");
        _mint(_account, counter);
        // If baseURI exists then do not use incoming url.
        if (bytes(baseURI).length == 0) {
            _setTokenURI(counter, _uri);
        }
        counter++;
    }

    /******************************************************************************
     *                             Owner functions                                *
     *****************************************************************************/

    /**
     * @notice onlyOwner:: Lock collection at provided NFT count (the collection total NFT count),
     * preventing any further minting past the given NFT count.
     * @dev Max id of this collection will be provided NFT count minus one.
     */
    function lockCollectionCount(uint256 _nftCount) external virtual onlyOwner {
        require(maxId == type(uint256).max, "collection is already locked");
        require(_nftCount > 0, "_nftCount is zero");
        require(_nftCount >= counter, "_nftCount is less than counter");

        maxId = _nftCount - 1;
        emit CollectionLocked(_nftCount);
    }

    /// @notice onlyTokenURIOwner:: Set new token URI for given tokenId.
    function setTokenURI(uint256 _tokenId, string calldata _newTokenURI) external onlyTokenURIOwner {
        emit TokenURIUpdated(_tokenId, tokenURI(_tokenId), _newTokenURI);
        _setTokenURI(_tokenId, _newTokenURI);
    }

    /// @notice onlyTokenURIOwner:: Set new base URI for the collection.
    function setBaseURI(string calldata baseURI_) external onlyTokenURIOwner {
        emit BaseURIUpdated(baseURI, baseURI_);
        baseURI = baseURI_;
    }

    /// @notice onlyTokenURIOwner:: Set a contract to be in charge of tokenURI calls.
    function setMetadataProvider(address _metadataProvider) external onlyTokenURIOwner {
        emit MetadataProviderUpdated(metadataProvider);
        metadataProvider = _metadataProvider;
    }

    /**
     * @notice onlyOwner:: Update royalty receiver and rate.
     * @param _royaltyReceiver Address of royalty receiver
     * @param _royaltyRate Royalty rate in Basis Points. ie. 100 = 1%, 10_000 = 100%
     */
    function updateRoyaltyConfig(address _royaltyReceiver, uint256 _royaltyRate) external onlyOwner {
        require(_royaltyReceiver != address(0), "Royalty receiver is null");
        require(_royaltyRate <= MAX_BPS, "Royalty rate too high");
        emit RoyaltyConfigUpdated(royaltyReceiver, _royaltyReceiver, royaltyRate, _royaltyRate);
        royaltyReceiver = _royaltyReceiver;
        royaltyRate = _royaltyRate;
    }

    /// @notice onlyTokenURIOwner:: Update token URI owner.
    function updateTokenURIOwner(address _newTokenURIOwner) external onlyTokenURIOwner {
        emit TokenURIOwnerUpdated(tokenURIOwner, _newTokenURIOwner);
        tokenURIOwner = _newTokenURIOwner;
    }

    /// @inheritdoc Ownable
    function renounceOwnership() public override onlyOwner {
        super.renounceOwnership();
        factory.updateCapsuleCollectionOwner(_msgSender(), address(0));
    }

    /// @inheritdoc Ownable
    function transferOwnership(address _newOwner) public override onlyOwner {
        super.transferOwnership(_newOwner);
        if (_msgSender() != address(factory)) {
            factory.updateCapsuleCollectionOwner(_msgSender(), _newOwner);
        }
    }

    /******************************************************************************
     *                            Internal functions                              *
     *****************************************************************************/
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        ERC721URIStorage._burn(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}