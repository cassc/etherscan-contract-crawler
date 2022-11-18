// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BAGCERC721 is ERC721URIStorage, Ownable{
    constructor (string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function mint(address _to, uint256 _tokenId,  string calldata _uri) 
        external 
        onlyOwner 
    {
        _mint(_to, _tokenId);
        _setTokenURI(_tokenId, _uri);
    }

    function burn (uint256 _tokenId) 
        external 
        onlyOwner 
    {
        _burn(_tokenId);
    }
}