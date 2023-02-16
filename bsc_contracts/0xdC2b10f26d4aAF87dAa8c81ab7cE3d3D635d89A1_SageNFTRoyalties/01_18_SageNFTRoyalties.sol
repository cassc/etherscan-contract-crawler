// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract SageNFTRoyalties is ERC721, ERC721Enumerable, ERC721URIStorage,ERC2981, Ownable  {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor(
        string memory _name, 
        string memory _symbol
        ) 
        ERC721(_name,_symbol) {
    }

    function createToken(
        string memory URI,
        address royaltyRecipient,
        uint96 royaltyValue
        // Percentage of each sale to pay as royalties 500 = 5%
        ) public returns (uint) {

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, URI);
        require(royaltyValue <5001, "Royalties must be < 50%");
        if (royaltyValue > 0) {
            _setTokenRoyalty(newItemId, royaltyRecipient, royaltyValue);
        }
        return newItemId;
    }

    // The following functions are overrides required by Solidity.

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    /// @notice Informs callers that this contract supports ERC2981
    function supportsInterface(bytes4 interfaceId) public view override(ERC721,ERC2981,ERC721Enumerable)
    returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}