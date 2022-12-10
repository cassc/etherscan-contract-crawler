// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Mintable.sol";

contract Asset is ERC721, Ownable, Mintable{

    string _internalBaseURI;

    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _imx,
        string memory _baseUri
    ) ERC721(_name, _symbol) Mintable(_owner, _imx) {
        _internalBaseURI = _baseUri;
    }


    function _mintFor(
        address user,
        uint256 id,
        bytes memory
    ) internal override {
        _safeMint(user, id);
    }

    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function setBaseURI(string memory newBaseUri) public onlyOwner {
        _internalBaseURI = newBaseUri;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return _internalBaseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}