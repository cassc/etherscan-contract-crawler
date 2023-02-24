// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;
// solhint-disable no-empty-blocks

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "../../../interface/core/token/basic/IGameFiTokenERC721.sol";

/**
 * @author Alex Kaufmann
 * @dev ERC721 Token contract for GameFiCore.
 * Can be used as a base for expanding functionality.
 * See https://docs.openzeppelin.com/contracts/4.x/api/token/erc721.
 * Also supports contract-level metadata (https://docs.opensea.io/docs/contract-level-metadata)
 */
contract GameFiTokenERC721 is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable,
    IGameFiTokenERC721
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    string private _contractURI;
    string private _tokenURI;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Constructor method (https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers).
     * @param name_ ERC20 name() field (see ERC20Metadata).
     * @param symbol_ ERC20 symbol() field (see ERC20Metadata).
     * @param contractURI_ Contract-level metadata (https://docs.opensea.io/docs/contract-level-metadata).
     * @param tokenURI_  Uniform Resource Identifier (URI) of the token metadata.
     * @param data_ Custom hex-data for additional parameters. Depends on token implementation.
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory tokenURI_,
        bytes memory data_
    ) public virtual initializer {
        __ERC721_init(name_, symbol_);
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Ownable_init();
        _contractURI = contractURI_;
        _tokenURI = tokenURI_;
        data_;
    }

    /**
     * @dev Sets new contract-level metadata URI (https://docs.opensea.io/docs/contract-level-metadata).
     * @param newURI Contract-level metadata.
     */
    function setContractURI(string memory newURI) external onlyOwner {
        _contractURI = newURI;
    }

    /**
     * @dev Sets new token metadata URI (see ERC721Metadata).
     * @param newURI Token metadata.
     */
    function setTokenURI(string memory newURI) external onlyOwner {
        _tokenURI = newURI;
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function mint(address to, bytes memory data) external onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(to, tokenId);

        data;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function burn(uint256 tokenId, bytes memory data) external onlyOwner {
        _burn(tokenId);

        data;
    }

    /**
     * @dev Returns contract-level metadata URI.
     * @return Contract-level metadata.
     */
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for all tokens (Base URL).
     * @return Token metadata.
     */
    function tokenURI() external view returns (string memory) {
        return _tokenURI;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for specific token (Base URL + Token Id).
     * @return Specific token metadata.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable, IERC721MetadataUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
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
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return (interfaceId == type(IGameFiTokenERC721).interfaceId || super.supportsInterface(interfaceId));
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenURI;
    }
}