// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

abstract contract BaseCore is
    Initializable,
    ERC721Upgradeable,
    ERC721BurnableUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;
    string private _metadataURI;

    // solhint-disable-next-line func-name-mixedcase
    function __BaseCore_init(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) internal onlyInitializing {
        __BaseCore_init_unchained(name_, symbol_, baseURI_);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __BaseCore_init_unchained(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) internal onlyInitializing {
        __ERC721_init(name_, symbol_);
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __ERC721Burnable_init();
        _metadataURI = baseURI_;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for all tokens (Base URL).
     * @return Token metadata.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        tokenId; // for linter
        return _baseURI();
    }

    /**
     * @dev Returns base URI for token metadata.
     * @return Base URI.
     */
    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _mintProfileToken(address target) internal returns (uint256 tokenId) {
        tokenId = _tokenIdCounter.current();
        _mint(target, tokenId);
        _tokenIdCounter.increment();
    }

    function _setBaseURI(string memory newBaseURI) internal {
        _metadataURI = newBaseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function _baseURI() internal view override(ERC721Upgradeable) returns (string memory) {
        return _metadataURI;
    }

    uint256[48] private __gap;
}