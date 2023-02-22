// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTCollection is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdentifiers;
    address public marketplaceContract;
    uint256 public MAX_SUPPLY = 2**256 - 1;

    modifier onlyMarketplaceContract {
      require(msg.sender == marketplaceContract, "No registered.");
      _;
    }

    constructor(string memory _name, string memory _symbol, uint256 _maxSupply) ERC721(_name, _symbol) {
        MAX_SUPPLY = _maxSupply;
        marketplaceContract = msg.sender;
    }

    function MintNFT(string memory _tokenURI, address _to) external onlyMarketplaceContract returns(uint256) {
        require(_tokenIdentifiers.current() < MAX_SUPPLY, "Exceeded max supply.");
        bytes memory stringURI = bytes(_tokenURI);
        require(stringURI.length > 0, "Token URI can't be empty string!");
        _tokenIdentifiers.increment();
        _mint(_to, _tokenIdentifiers.current());
        _setTokenURI(_tokenIdentifiers.current(), _tokenURI);
        return _tokenIdentifiers.current();
    }
}