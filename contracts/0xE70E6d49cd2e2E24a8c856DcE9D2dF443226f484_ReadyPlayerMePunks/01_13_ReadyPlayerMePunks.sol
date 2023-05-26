// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


abstract contract ICryptoPunks
{
    mapping (uint => address) public punkIndexToAddress;
}


contract ReadyPlayerMePunks is ERC721, ERC721URIStorage, ERC721Enumerable
{
    string constant METADATA_URL = "https://punks.readyplayer.me/api/punks/";
    string constant METADATA_SUFFIX = "/meta";
    uint constant NFT_PRICE = 0.33 ether;
    address constant PARENT_TOKEN_ADDRESS = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    uint16 constant MAX_ASSETS = 10000;

    uint[MAX_ASSETS] private _assets;
    mapping(uint => bool) public _assetExists;
    address private _owner;


    constructor() ERC721("ReadyPlayerMePunks", "RPMP")
    {
        _owner = msg.sender;
    }


    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }


    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }


    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    function _mintSingle(ICryptoPunks _parentContract, uint _parentIndex) private
    {
        require(_parentContract.punkIndexToAddress(_parentIndex) == msg.sender, "Parent token owner and sender mismatch.");
        require(!_assetExists[_parentIndex], "The asset does not meet the unique constraint.");

        uint _id = totalSupply();
        _assets[_id] = _parentIndex;
        _mint(msg.sender, _id);
        _setTokenURI(_id, string(abi.encodePacked(METADATA_URL, Strings.toString(_id), METADATA_SUFFIX)));
        _assetExists[_parentIndex] = true;
    }


    function mint(uint _parentTokenIndex) public payable 
    {
        require(msg.value >= NFT_PRICE, "Not enough ETH sent.");

        ICryptoPunks _parentToken = ICryptoPunks(PARENT_TOKEN_ADDRESS);
        _mintSingle(_parentToken, _parentTokenIndex);
    }


    function batchMint(uint[] memory _parentTokenIndices) public payable
    {
        require(msg.value >= NFT_PRICE * _parentTokenIndices.length, "Not enough ETH sent.");
        ICryptoPunks _parentToken = ICryptoPunks(PARENT_TOKEN_ADDRESS);

        for (uint i = 0; i < _parentTokenIndices.length; i++)
        {
            _mintSingle(_parentToken, _parentTokenIndices[i]);
        }
    }


    function getParentToken(uint tokenId) public view returns(uint parentId)
    {
        parentId = _assets[tokenId];
    }


    function getTokenPrice() public pure returns(uint price)
    {
        price = NFT_PRICE;
    }


    function getOwner() public view returns(address)
    {
        return _owner;
    }


    function withdrawAll() public 
    {
        payable(_owner).transfer(address(this).balance);
    }
}