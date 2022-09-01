// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

/*
VirtueFoundersPass.sol
written by: mousedev.eth
*/

import "erc721a/contracts/ERC721A.sol";
import "./MerkleWhitelist.sol";

contract VirtueFoundersPass  is ERC721A, MerkleWhitelist{
    string public passURI = "data:application/json;base64,eyJuYW1lIjogIlZpcnR1ZSBGb3VuZGVycyBQYXNzIiwiZGVzY3JpcHRpb24iOiAiVGhlIFZpcnR1ZSBGb3VuZGVycyBQYXNzIGdyYW50cyB5b3UgYSBmcm9udC1yb3cgdGlja2V0IHRvIHVwY29taW5nIFZpcnR1ZSBjb250ZW50LCBwcml2YXRlIGNoYW5uZWxzLCBleGNpdGluZyBnYW1lcywgc3BlY2lhbCBldmVudHMsIHZvdGluZyBwcml2aWxlZ2VzLCBhbmQgbW9yZSEgIFBhc3MgaG9sZGVycyBqb2luIGFuIGV4Y2x1c2l2ZSwgcGFzc2lvbmF0ZSBjb21tdW5pdHkgb2YgbGVhZGVycywgaW5ub3ZhdG9ycywgYW5kIGNvbGxlY3RvcnMgc2hhcmluZyBpbiBvdXIgZWZmb3J0IHRvIGNyZWF0ZSBleGNpdGluZywgbmV3IGNvbnRlbnQgZm9yIFdlYjMgd2hpbGUga2VlcGluZyB0aGUgcG93ZXIgaW4gdGhlIGhhbmRzIG9mIHRoZSBjcmVhdG9ycy4iLCJhbmltYXRpb25fdXJsIjogImh0dHBzOi8vZ2F0ZXdheS5waW5hdGEuY2xvdWQvaXBmcy9RbVV0N1FzUlJONEgxeXhNNXNwYVc1Q0F4NXU3a0N0UVVxRzlWRnJNcXJpS2J1In0=";
    string public contractURI = "ipfs://QmTbVy4g7rRwRSXLQpwQgbCMefr68GTKXCWquqnpAheZBo";

    uint256 maxSupply = 500;
    
    constructor() ERC721A("Virtue Founders Pass", "VFP") {}

    function mintWhitelist(bytes32[] memory proof) public onlyWhitelisted(proof){
        require(_numberMinted(msg.sender) == 0, "You already minted!");
        require(totalSupply() + 1 <= maxSupply, "Max supply reached!");
        _mint(msg.sender, 1);
    }

    function mintAdmin(uint256 _quantity) public onlyOwner{
        require(totalSupply() + _quantity <= maxSupply, "Max supply reached!");
        _mint(msg.sender, _quantity);
    }

    function setURIs(string memory _contractURI, string memory _passURI) public onlyOwner{
        contractURI = _contractURI;
        passURI = _passURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist!");
        return passURI;
    }
}