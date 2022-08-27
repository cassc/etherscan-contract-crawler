//SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./interfaces/IERC721Minter.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract EpikoMarket721 is ERC721, IERC2981, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter private _tokenIds;

    uint256 private constant PERCENTAGE_DENOMINATOR = 10000;
    address private mediaContract;

    struct Royalty {
        address receiver;
        uint256 royaltyFraction;
    }

    //mapping from token id to artists address
    mapping(uint256 => address) private _artist;
    //mapping from id to Royalty info
    mapping(uint256 => Royalty) private _tokenRoyaltyInfo;
    //mapping from id to tokenUri
    mapping(uint256 => string) private _tokenUris;
    //mapping from uri to bool
    mapping(string => bool) private _isUriExist;

    constructor() ERC721("Epiko NFT", "EPIKO") {}

    function mint(
        address to,
        uint256 royaltyFraction,
        string memory _uri
    ) external returns (uint256 _id) {
        require(msg.sender == mediaContract, "ERC721: Not authorised");
        require(to != address(0), "ERC721: Please provide valid address");
        require(_isUriExist[_uri] != true, "ERC721: uri already exist");

        _tokenIds.increment();
        _mint(to, _tokenIds.current());
        _artist[_tokenIds.current()] = to;
        _tokenRoyaltyInfo[_tokenIds.current()].receiver = to;
        _tokenRoyaltyInfo[_tokenIds.current()]
            .royaltyFraction = royaltyFraction;
        _tokenUris[_tokenIds.current()] = _uri;
        _isUriExist[_uri] = true;

        return (_tokenIds.current());
    }

    function burn(uint256 tokenId) public {
        require(owner() == msg.sender, "Only admin can burn");
        require(_isExist(tokenId), "ERC721: token not exist");

        _burn(tokenId);

        delete _isUriExist[_tokenUris[tokenId]];
        delete _tokenUris[tokenId];
    }

    function isApprovedOrOwner(address spender, uint256 tokenId)
        public
        view
        returns (bool)
    {
        return _isApprovedOrOwner(spender, tokenId);
    }

    function getArtist(uint256 tokenId) public view returns (address) {
        require(_isExist(tokenId), "ERC721: Token not Exist");
        return _artist[tokenId];
    }

    function showDetailOfNFT(uint256 tokenId)
        public
        view
        returns (address receiver_, uint256 royaltyFraction_)
    {
        require(_isExist(tokenId), "ERC721: Token not Exist");

        uint256 _royaltyFraction = _tokenRoyaltyInfo[tokenId].royaltyFraction;
        address _receiver = _tokenRoyaltyInfo[tokenId].receiver;

        return (_receiver, _royaltyFraction);
    }

    function tokenURI(uint tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_isExist(tokenId), "ERC721: Query for non Existance token");

        return _tokenUris[tokenId];
    }

    function _isExist(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function configureMedia(address _mediaContract) external onlyOwner {
        require(_mediaContract != address(0), "address zero provided");
        require(
            mediaContract == address(0),
            "media contract already configured"
        );

        mediaContract = _mediaContract;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        override
        returns (address receiver, uint256 royaltyAmount_)
    {
        // require(_isExist(tokenId), "ERC721: Token not Exist");

        Royalty memory royalty = _tokenRoyaltyInfo[tokenId];
        uint256 _royaltyAmount = salePrice.mul(royalty.royaltyFraction).div(
            PERCENTAGE_DENOMINATOR
        );

        return (royalty.receiver, _royaltyAmount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }
}