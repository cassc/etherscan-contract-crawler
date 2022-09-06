//SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./interfaces/IERC1155Minter.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract EpikoMarket1155 is ERC1155, IERC2981, IERC1155Minter, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    uint256 private constant PERCENTAGE_DENOMINATOR = 10000;
    address private mediaContract;
    string public name;
    string public symbol;

    struct Royalty {
        address receiver;
        uint256 royaltyFraction;
    }

    //mapping from id to royaltyinfo
    mapping(uint256 => Royalty) private _tokenRoyaltyInfo;
    //mapping from id to artist address
    mapping(uint256 => address) private _artist;
    //mapping from id to tokenUri
    mapping(uint256 => string) private _tokenUris;
    //mapping from uri to bool
    mapping(string => bool) private _isUriExist;

    constructor(string memory _name, string memory _symbol) ERC1155("") {
        name = _name;
        symbol = _symbol;
    }

    function mint(
        address to,
        uint256 amount,
        uint256 royaltyFraction,
        string memory _uri,
        bytes memory data
    ) public override returns (uint256 _id) {
        require(msg.sender == mediaContract, "ERC1155: Not authorised");
        require(to != address(0), "ERC1155: Please provide valid address");
        // require(bytes(_tokenUris[tokenId]).length <= 0, "token already minted");
        require(_isUriExist[_uri] != true, "ERC1155: uri already exist");

        _tokenIds.increment();

        _mint(to, _tokenIds.current(), amount, data);

        _tokenRoyaltyInfo[_tokenIds.current()].receiver = to;
        _tokenRoyaltyInfo[_tokenIds.current()]
            .royaltyFraction = royaltyFraction;

        _artist[_tokenIds.current()] = to;
        _tokenUris[_tokenIds.current()] = _uri;
        _isUriExist[_uri] = true;

        return _tokenIds.current();
    }

    function burn(
        address from,
        uint256 tokenId,
        uint256 amounts
    ) public override {
        require(owner() == msg.sender, "ERC1155: Only admin can burn");
        require(from != address(0), "ERC1155: burn from zero address");
        require(_isExist(tokenId), "ERC1155: Query for non Existance token");

        _burn(from, tokenId, amounts);

        delete _isUriExist[_tokenUris[tokenId]];
        delete _tokenUris[tokenId];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 value,
        bytes memory data
    ) public override(ERC1155, IERC1155) {
        require(from != address(0), "ERC1155: Transfer from zero address");
        require(to != address(0), "ERC1155: Transfer to zero address");

        _safeTransferFrom(from, to, tokenId, value, data);
    }

    function getArtist(uint256 tokenId) public view override returns (address) {
        require(_isExist(tokenId), "ERC1155: Query for non Existance token");

        return _artist[tokenId];
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(_isExist(tokenId), "ERC1155: Query for non Existance token");

        return _tokenUris[tokenId];
    }

    function _isExist(uint256 tokenId) public view override returns (bool) {
        return (bytes(_tokenUris[tokenId]).length > 0);
    }

    function configureMedia(address _mediaContract) external onlyOwner {
        require(_mediaContract != address(0), "address zero provided");
        require(
            mediaContract == address(0),
            "media contract already configured"
        );

        mediaContract = _mediaContract;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        override
        returns (address receiver, uint256 royaltyAmount_)
    {
        require(_isExist(tokenId), "ERC1155: Token not Exist");

        Royalty memory royalty = _tokenRoyaltyInfo[tokenId];
        uint256 _royaltyAmount = salePrice.mul(royalty.royaltyFraction).div(
            PERCENTAGE_DENOMINATOR
        );

        return (royalty.receiver, _royaltyAmount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, IERC165)
        returns (bool)
    {
        return
            interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }
}