// contracts/VariableEndstateNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./EndstateBase.sol";

abstract contract VariableEndstateNFT is
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Royalty,
    EndstateBase
{
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter internal _tokenIds;

    // Initial token URI
    string internal _initialTokenUri;

    // mapping for variations
    mapping(uint256 => Counters.Counter) internal _variationSupply;

    // token limit
    uint256[] public maxVariationSupply;
    uint256 public specialMintReserve;

    /**
      Constructor takes `name` variable which would indicate the shoe drop, currently defaulting
      the symbol to `ENDSTATE` but this can be configured differently if desired
    */
    constructor(
        string memory name,
        string memory symbol,
        string memory initialTokenUri,
        uint256[] memory maxVariationSupply_,
        uint256 specialMintReserve_
    ) ERC721(name, symbol) {
        _initialTokenUri = initialTokenUri;

        maxVariationSupply = maxVariationSupply_;
        specialMintReserve = specialMintReserve_;

        _setDefaultRoyalty(_msgSender(), 500);
    }

    function _variationExists(uint256 variation)
        internal
        virtual
        returns (bool);

    function reserve(
        uint256 variation,
        address shoeOwner,
        uint256 numMints
    ) public returns (uint256, uint256) {
        require(
            hasRole(ENDSTATE_ADMIN_ROLE, _msgSender()),
            "EndstateNFT: must have admin role to reserve"
        );

        uint256 lastId;
        for (uint256 i = 0; i < numMints; i++) {
            lastId = _mintOne(variation, shoeOwner, true);
        }

        // return first and last IDs generated
        return (lastId - (numMints - 1), lastId);
    }

    function _checkLimit(uint256 variation, uint256 numMints)
        internal
        view
        virtual
    {
        if (maxVariationSupply[variation] > 0) {
            require(
                (_variationSupply[variation].current() + numMints <=
                    maxVariationSupply[variation]),
                "EndstateNFT: variation limit reached"
            );
        }
    }

    function _mintOne(
        uint256 variation,
        address shoeOwner,
        bool specialMint
    ) internal returns (uint256) {
        require(
            _variationExists(variation),
            "EndstateNFT: variation doesn't exist"
        );

        if (specialMint) {
            _checkLimit(variation, 1);
        } else {
            _checkLimit(variation, 1 + specialMintReserve);
        }

        _variationSupply[variation].increment();

        uint256 newShoeTokenId = _variationSupply[variation].current();
        for (uint256 i = 0; i < variation; i++) {
            newShoeTokenId += maxVariationSupply[i];
        }

        _safeMint(shoeOwner, newShoeTokenId);
        _setTokenURI(
            newShoeTokenId,
            string(
                abi.encodePacked(_initialTokenUri, newShoeTokenId.toString())
            )
        );

        return newShoeTokenId;
    }

    // Gives us a way to update the metaDataURI
    // NOTE: We can setup a flag or something to make this burnable (so it can't be called anymore)
    function redeem(uint256 tokenId, string memory newTokenURI) public {
        require(
            hasRole(ENDSTATE_ADMIN_ROLE, _msgSender()),
            "EndstateNFT: must have admin role to redeem"
        );

        _setTokenURI(tokenId, newTokenURI);
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
            "EndstateNFT: must have minter role to burn"
        );
        _burn(tokenId);
    }

    function variationTotalSupply(uint256 _variation)
        public
        view
        returns (uint256)
    {
        return _variationSupply[_variation].current();
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721URIStorage, ERC721Royalty)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function withdrawFunds() public {
        require(
            hasRole(ENDSTATE_ADMIN_ROLE, _msgSender()),
            "EndstateNFT: must be an admin to withdraw funds"
        );
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }
}