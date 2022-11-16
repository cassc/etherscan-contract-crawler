// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";


contract ZabaletaContract is ERC1155, Ownable, Pausable, ERC1155Burnable {
    mapping (uint256 => string) private _uris;
    
    mapping (uint256 => string) public token_attachments;

    constructor() ERC1155(""){}

    function uri(uint256 tokenId) override public view returns (string memory) {
        return(_uris[tokenId]);
    }

    function setTokenUri(uint256 _tokenId, string memory _uri) public onlyOwner {
        _uris[_tokenId] = _uri;
    }

    function setTokenAttachment(uint256 _tokenId, string memory _uri) public onlyOwner {
        token_attachments[_tokenId] = _uri;
    }

    function mint(address recipient, uint256 tokenId, uint256 amount) public onlyOwner {
        _mint(recipient, tokenId, amount, "");
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

}