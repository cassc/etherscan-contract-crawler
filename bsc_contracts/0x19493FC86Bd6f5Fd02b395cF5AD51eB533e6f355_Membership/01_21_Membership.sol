// contracts/GameItems.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Membership is ERC721PresetMinterPauserAutoId, Ownable {

    string private _tokenURISuffix;
    string private _tokenBaseURI = "";
     mapping(address => bool) public whitelistedSource;
    mapping(address => bool) public whitelistedDest;
    bool public enableWhitelistTransfer;


    constructor(string memory name, string memory symbol) public ERC721PresetMinterPauserAutoId(name,symbol,"") {
     
    }

 function bulkMint(address receiver, uint256 tokenId, uint256 toMint) public onlyOwner {
         for (uint256 i=tokenId;i<toMint;i++) {
            mint(receiver,i);
        }
    }


  function setEnableWhitelist(bool _enableWhitelistTransfer) public onlyOwner {
        enableWhitelistTransfer = _enableWhitelistTransfer;
    }

   function addToWhitelistedSource(address[] memory _addresses) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            require(whitelistedSource[_addresses[i]] != true);
            whitelistedSource[_addresses[i]] = true;
        }
    }

    function addToWhitelistedDest(address[] memory _addresses) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            require(whitelistedDest[_addresses[i]] != true);
            whitelistedDest[_addresses[i]] = true;
        }
    }

       function removeFromWhitelistedSource(address[] memory _addresses) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            require(whitelistedSource[_addresses[i]] != false);
            whitelistedSource[_addresses[i]] = false;
        }
    }

    function removeFromWhitelistedDest(address[] memory _addresses) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            require(whitelistedDest[_addresses[i]] != false);
            whitelistedDest[_addresses[i]] = false;
        }
    }

   function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function setTokenURISuffix(string calldata suffix) external onlyOwner {
        _tokenURISuffix = suffix;
    }

   function tokenURI(uint256 tokenId) public view override(ERC721) returns(string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");

        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString(), _tokenURISuffix));
    }

  function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721PresetMinterPauserAutoId) {
          if (enableWhitelistTransfer) {
            require((whitelistedSource[from] || whitelistedDest[to]), "Source or dest have to be whitelisted");
        }

        super._beforeTokenTransfer(from, to, tokenId);
    }

}