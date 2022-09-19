// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

/**
 * @dev This layer stores the corresponding URI of each token ID
 * Furthermore, it stores the default approved market address so that it is allowed to transfer each token ID
 */
abstract contract BlockMelonERC721TokenBase is ERC721URIStorageUpgradeable {
    using StringsUpgradeable for uint256;

    /// @notice Emitted when the URI of `tokenId` is set
    event URI(string value, uint256 indexed tokenId);
    /// @notice Emitted when the default approved operator address is changed
    event DefaultApprovedMarket(address indexed operator);

    /// @dev Storing the address of the default approved operator, i.e.: the BlockMelon market contract
    address public defaultApprovedMarket;
    /// @dev Base URI for all of the token IDs
    string private baseURI_;

    modifier onylExisting(uint256 tokenId) {
        require(_exists(tokenId), "query for nonexistent token");
        _;
    }

    function __BlockMelonERC721TokenBase_init_unchained()
        internal
        onlyInitializing
    {}

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     *      token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI();
    }

    /**
     * @dev See {ERC721Upgradeable__baseURI}
     */
    function _baseURI() internal view virtual override returns (string memory) {
        if (bytes(baseURI_).length > 0) {
            return baseURI_;
        }
        return "ipfs://";
    }

    /**
     * @dev Internal function to set the base URI for all token IDs.
     */
    function _setBaseURI(string memory newBaseURI) internal virtual {
        baseURI_ = newBaseURI;
    }

    function _setTokenURI(uint256 tokenId, string memory newUri)
        internal
        virtual
        override
    {
        require(0 != bytes(newUri).length, "empty token uri");
        super._setTokenURI(tokenId, newUri);
        emit URI(newUri, tokenId);
    }

    /**
     * @dev See {ERC721Upgradeable-_isApprovedOrOwner}
     * This version adds default approval for operators, i.e.: the BlockMelon market contract
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        override
        returns (bool)
    {
        return
            spender == defaultApprovedMarket ||
            super._isApprovedOrOwner(spender, tokenId);
    }

    /**
     * @dev See {ERC721Upgradeable-isApprovedForAll}
     * This version adds default approval for operators, i.e.: the BlockMelon market contract
     */
    function isApprovedForAll(address _owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            operator == defaultApprovedMarket ||
            super.isApprovedForAll(_owner, operator);
    }

    function _setDefaultApprovedMarket(address operator) internal {
        defaultApprovedMarket = operator;
        emit DefaultApprovedMarket(operator);
    }

    uint256[50] private __gap;
}