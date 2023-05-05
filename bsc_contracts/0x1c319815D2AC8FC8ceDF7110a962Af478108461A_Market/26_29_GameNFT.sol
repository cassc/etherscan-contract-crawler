// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

/// @author Welechi Ifeanyichukwu - @nerdjango
/// @title A Product Smart Contract
contract GameNFT is ERC1155, ERC1155Supply, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address marketplaceAddress;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /// @dev - base for the product
    constructor(address tokenOwner, address _marketplaceAddress) ERC1155("") {
        _transferOwnership(tokenOwner);
        marketplaceAddress = _marketplaceAddress;
    }

    function createToken(
        uint256 amount,
        string memory tokenURI
    ) external onlyOwner {
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId, amount, "");
        _tokenIds.increment();

        _setTokenURI(newItemId, tokenURI);
        setApprovalForAll(marketplaceAddress, true);
    }

    function uri(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(exists(tokenId), "invalid token ID");

        string memory _tokenURI = _tokenURIs[tokenId];
        return _tokenURI;
    }

    function _setTokenURI(
        uint256 tokenId,
        string memory _tokenURI
    ) internal virtual {
        require(exists(tokenId), "URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}