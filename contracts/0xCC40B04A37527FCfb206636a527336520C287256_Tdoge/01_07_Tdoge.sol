// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Tdoge is Ownable, ERC721A {
    address private _owner;

    string private _baseTokenURI;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => address) private _tokenAuthors;
    mapping(address => bool) public _airdrop;

    constructor() ERC721A("Tdoge game card V2", "TdogeGameCardV2") {
        _baseTokenURI = "ipfs://QmbjXbiLHxmUhdrrY4CLpFjUwuKXcGJLBtHAwdgLpm37uP/";
        _owner = msg.sender;
    }

    modifier onlyAdmin() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (bytes(_tokenURIs[tokenId]).length > 0) {
            return _tokenURIs[tokenId];
        } else {
            string memory baseURI = _baseURI();
            return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, Strings.toString(tokenId)))
            : '';
        }
    }

    function setTokenURI(uint256 tokenId,string calldata uri) public onlyAdmin(){
        _tokenURIs[tokenId] = uri;
    }

    function setBaseURI(string calldata uri) public onlyAdmin(){
        _baseTokenURI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    function airdrop(address[] calldata addrs, uint256 number) public onlyAdmin(){
        for (uint i = 0; i < addrs.length; i++){
            _safeMint(addrs[i], number);
        }
    }

    function withdraw(address to) public onlyAdmin(){
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }
}