// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NonconformistDucks2Gen is ERC721Burnable, Ownable  {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private _maxSupply = 3000;

    string public _provenanceHash;
    string public _baseURL;

    constructor() ERC721("Nonconformist Ducks 2nd GEN", "NCD2") {}

    function mint(address tokenOwner) public onlyOwner {
        require(_tokenIds.current() < _maxSupply, "Can not mint more than max supply");
        _tokenIds.increment();
        _mint(tokenOwner, _tokenIds.current());
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        _provenanceHash = provenanceHash;
    }

    function setBaseURL(string memory baseURI) public onlyOwner {
        _baseURL = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }
}