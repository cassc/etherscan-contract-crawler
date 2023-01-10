// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ERC721Template is ERC721, Ownable{

    using Strings for uint256;

    string private _uri;

    constructor(string memory name_, string memory symbol_, string memory uri_) ERC721(name_, symbol_){
        _uri = uri_;
    }

    function setURI(string memory uri_) public onlyOwner{
        _uri = uri_;
    }

    function baseURI() public view returns(string memory){
        return _uri;
    }

    function mint(address to, uint256 tokenId) public onlyOwner{
        _mint(to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return bytes(_uri).length > 0 ? string(abi.encodePacked(_uri, tokenId.toString())) : "";
    }

    function uri(uint256 id) public view returns (string memory){
        return bytes(_uri).length > 0 ? string(abi.encodePacked(_uri, "{id}")) : "";
    }

}