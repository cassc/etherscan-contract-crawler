// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract UwUKitties is ERC721URIStorage, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    string public baseURIString;

    constructor() ERC721('UwU Kitty', 'UwUK') {}

    receive() external payable {
        revert('Forbidden');
    }

    // baseURI must have `/` symbol in the end
    // good: `www.mysite.example/token/`
    // bad `www.mysite.example/token`
    function setBaseURI(string memory baseURI) public onlyOwner {
        require(_equal(baseURIString, ''), 'The Base URL was already set');
        baseURIString = baseURI;
    }

    function mint(uint256 numberOfTokens) public onlyOwner {
        require(numberOfTokens != 0, 'Wrong amount of tokens provided');
        require(numberOfTokens + getLastId() <= 50, 'It is not allowed to mint more than 50 tokens');
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);
        }
    }

    function getLastId() public view returns (uint256) {
        return _tokenIds.current();
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        if (_equal(baseURIString, '')) revert('There is no URI for the token');
        return string(abi.encodePacked(baseURIString, tokenId.toString(), '.json'));
    }

    function _equal(string memory s1, string memory s2) internal pure returns (bool) {
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }
}