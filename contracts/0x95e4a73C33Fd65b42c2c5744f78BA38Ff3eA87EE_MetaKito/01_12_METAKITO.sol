// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title META KITO contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract MetaKito is ERC721URIStorage, Ownable {
    // It's possible to mint only a single token with ID==1 from this contract 
    uint8 private constant _MKITOID = 1;
    bool public isMinted = false; 
    bool public isFrozen = false;
    event PermanentURI(string _value, uint256 indexed _id);
    
    constructor() ERC721("META KITO", "MKITO") {}
    
    function mintTo(address recipient, string memory tokenURI) public onlyOwner returns (uint256)
    {
        require(!isMinted, "Single META KITO NFT has been already minted");
        _safeMint(recipient, _MKITOID);
        isMinted = true;
        _setTokenURI(_MKITOID, tokenURI);
        return _MKITOID;
    }

    function setMetaKitoURI(string memory tokenURI) public onlyOwner {
      require(!isFrozen, "META KITO's metadata has been frozen");
      _setTokenURI(_MKITOID, tokenURI);
    }

    function freezeMetaKito() public onlyOwner {
        isFrozen = true;
        emit PermanentURI(tokenURI(_MKITOID), _MKITOID);
    }
}