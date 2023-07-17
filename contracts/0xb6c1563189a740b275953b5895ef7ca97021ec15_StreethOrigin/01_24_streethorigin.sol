// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StreethOrigin is ERC721URIStorage, Ownable {

    constructor() ERC721("STREETH Origin", "STREETHOG") {}
    
    function mint(
        uint256 _id,
        address _to,
        string memory  _tokenURI
    ) public
    {
        _safeMint(_to, _id);
        _setTokenURI(_id, _tokenURI);
    }
    function mintAll(
        uint256[] memory _ids,
        address[] memory _tos,
        string[] memory _tokenURIs
    ) public onlyOwner {
        require(_ids.length == _tos.length, "tokenIDs and creators are not mismatched");
        require(_ids.length == _tokenURIs.length, "tokenIDs and tokenURI are not mismatched");
        for (uint i = 0; i < _ids.length; i ++) {
            mint(_ids[i], _tos[i], _tokenURIs[i]);
        }
    }
}