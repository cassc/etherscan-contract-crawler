// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// @title ix shells for Sotheby's Natively Digital
// @author Matt Condon (@1ofthemanymatts / @shrugs)
// @notice A simple ERC721 for showcsing ix shells' work for Sotheby's Natively Digital Sale
// @dev We use Ownable to make setting OpenSea collection information easy, as well as updating the metadata after mint, in the event of human error.
//      The chain will show that ownership is revoked before the sale.
// @dev We don't expose a public mint() function, so this collection is frozen.
contract IXSHTB is ERC721, Ownable {
    string private baseURI = "";
    
    constructor (address _ix) ERC721("ix shells for Sotheby's", "IXSHTB") {
        _mint(_ix, 0);
        _mint(_ix, 1);
        _mint(_ix, 2);
    }
    
    function _baseURI() override internal view virtual returns (string memory) {
        return baseURI;
    }
    
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
}