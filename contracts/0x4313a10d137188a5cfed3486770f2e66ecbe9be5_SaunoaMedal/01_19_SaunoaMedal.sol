// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";

/**
 * @title SaunoaMedal NFT
 */
contract SaunoaMedal is
    ERC721URIStorage,
    ERC2981,
    RevokableDefaultOperatorFilterer,
    Ownable
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIds;
    string public baseTokenURI;
    uint256 public royaltyRate = 20;

    /**
     * @dev Constractor of SaunoaMedal contract.
     * @param _baseTokenURI Initial setting of base token URI.
     */
    constructor(string memory _baseTokenURI)
        ERC721("SaunoaMedal", "SAUNOAMEDAL")
    {
        setBaseTokenURI(_baseTokenURI);
    }

    /**
     * @dev Setter of base token URI.
     * @param _baseTokenURI base token URI
     */
    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /**
     * @dev Setter of meta id.
     * @param _tokenId token id
     * @param _tokenUri tokenURI
     */
    function setTokenUri(uint256 _tokenId, string memory _tokenUri)
        public
        onlyOwner
    {
        _setTokenURI(_tokenId, _tokenUri);
    }

    /**
     * @dev Setter of royalty rate.
     * @param _royaltyRate royalty rate
     */
    function setRoyaltyRate(uint256 _royaltyRate) public onlyOwner {
        royaltyRate = _royaltyRate;
    }

    /**
     * @dev Getter of base token URI. Override ERC721.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev Getter of current total mint count.
     */
    function totalMint() public view returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * @dev Mint SaunoaMedal NFT. Transfer it to the specified address.
     */
    function mint(address _to, string memory _tokenUri) public onlyOwner {
        _tokenIds.increment();
        uint256 nextTokenId = _tokenIds.current();
        _safeMint(_to, nextTokenId);
        _setTokenURI(nextTokenId, _tokenUri);
    }

    /**
     * @dev ERC2981 royalty info.
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        virtual
        override
        returns (address, uint256)
    {
        return (owner(), (_salePrice * royaltyRate) / 100);
    }

    /**
     * @dev override owner.
     */
    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    /**
     * @dev override supportsInterface.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}