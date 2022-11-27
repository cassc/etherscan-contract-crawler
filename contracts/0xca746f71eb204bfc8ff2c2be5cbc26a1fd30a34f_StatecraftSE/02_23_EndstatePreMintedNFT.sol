// contracts/EndstatePreMintedNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./EndstateBase.sol";

contract EndstatePreMintedNFT is
    EndstateBase,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Royalty
{
    using Counters for Counters.Counter;
    Counters.Counter internal _tokenIds;

    /**
      Constructor takes `name` variable which would indicate the shoe drop, currently defaulting
      the symbol to `ENDSTATE` but this can be configured differently if desired
    */
    constructor(
        string memory name,
        address wallet
    ) ERC721(name, "ENDSTATE") {
        _setDefaultRoyalty(_msgSender(), 500);
        _setApprovalForAll(_msgSender(), wallet, true);
    }

    function mintURI(address shoeOwner, string memory newTokenURI) public returns (uint256) {
        require(
            hasRole(ENDSTATE_ADMIN_ROLE, _msgSender()),
            "EndstatePreMintedNFT: must have admin role to mintURI"
        );

        _tokenIds.increment();

        uint256 newShoeTokenId = _tokenIds.current();
        _safeMint(shoeOwner, newShoeTokenId);
        _setTokenURI(newShoeTokenId, newTokenURI);

        return newShoeTokenId;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function burn(uint256 tokenId) public virtual {
        require(
            hasRole(ENDSTATE_ADMIN_ROLE, _msgSender()),
            "EndstatePreMintedNFT: must have minter role to burn"
        );
        _burn(tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage, ERC721Royalty)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}