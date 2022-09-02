// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "OwnableUpgradeable.sol";
import "ERC721URIStorageUpgradeable.sol";
import "MerkleProofUpgradeable.sol";
import "ReentrancyGuardUpgradeable.sol";
import "AddressUpgradeable.sol";


/**
 * @dev NFT Contract that supports
 * - Enumerability
 * - Per token URIs
 *   - See: openzeppelin-contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol
 * - Royalties
 */
contract AICrypToadzBannerz is OwnableUpgradeable, ReentrancyGuardUpgradeable, ERC721URIStorageUpgradeable {
    /**
     * @dev Calls initializers of inherited contracts.
     */
    constructor() initializer {
        __ERC721_init("AICrypToadzBannerz", "AITDBN");
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    ////////////////////////////////////////////////////////////////////////////
    // Interfaces
    ////////////////////////////////////////////////////////////////////////////

    /**
     *  @dev Rarible: RoyaltiesV1
     *
     *  bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *  bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     *
     *  => 0xb9c4d9fb ^ 0x0ebd4c7f = 0xb7799584
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    /**
     *  @dev Foundation
     *
     *  bytes4(keccak256('getFees(uint256)')) == 0xd5a06d4c
     *
     *  => 0xd5a06d4c = 0xd5a06d4c
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_FOUNDATION = 0xd5a06d4c;

    /**
     *  @dev EIP-2981
     *
     * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
     *
     * => 0x2a55205a = 0x2a55205a
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Upgradeable) returns (bool) {
        return
            interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE ||
            interfaceId == _INTERFACE_ID_ROYALTIES_FOUNDATION ||
            interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 ||
            super.supportsInterface(interfaceId);
    }

    ////////////////////////////////////////////////////////////////////////////
    // Events
    ////////////////////////////////////////////////////////////////////////////

    event DefaultRoyaltiesUpdated(address payable[] receivers, uint256[] basisPoints);

    ////////////////////////////////////////////////////////////////////////////
    // Vars
    ////////////////////////////////////////////////////////////////////////////

    // Mapping for token URIs
    string private _baseTokenURI;

    // Royalties
    address payable[] internal _royaltyReceivers;
    uint256[] internal _royaltyBPS;

    ////////////////////////////////////////////////////////////////////////////
    // Minting
    ////////////////////////////////////////////////////////////////////////////
    function ownerMint(address to, uint256 tokenId) external onlyOwner {
        _safeMint(to, tokenId);
    }

    ////////////////////////////////////////////////////////////////////////////
    // Custom URI
    ////////////////////////////////////////////////////////////////////////////

    function setBaseTokenURI(string calldata uri) external onlyOwner {
        _baseTokenURI = uri;
    }

    ////////////////////////////////////////////////////////////////////////////
    // Royalties
    ////////////////////////////////////////////////////////////////////////////

    function setRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints ) external onlyOwner {
        require(receivers.length == basisPoints.length, "Invalid input");

        uint256 totalBasisPoints;

        for (uint i = 0; i < basisPoints.length; i++) {
            totalBasisPoints += basisPoints[i];
        }

        require(totalBasisPoints < 10000, "Invalid total royalties");

        _royaltyReceivers = receivers;
        _royaltyBPS = basisPoints;

        emit DefaultRoyaltiesUpdated(receivers, basisPoints);
    }

    function getRoyalties(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory) {
        require(_exists(tokenId), "Nonexistent token");
        return (_royaltyReceivers, _royaltyBPS);
    }

    function getFeeRecipients(uint256 tokenId) external view returns (address payable[] memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _royaltyReceivers;
    }

    function getFeeBps(uint256 tokenId) external view returns (uint[] memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _royaltyBPS;
    }

    function getFees(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory) {
        require(_exists(tokenId), "Nonexistent token");
        return (_royaltyReceivers, _royaltyBPS);
    }

    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256) {
        require(_exists(tokenId), "Nonexistent token");
        require(_royaltyReceivers.length <= 1, "More than 1 royalty receiver");

        if (_royaltyReceivers.length == 0) {
            return (address(this), 0);
        }

        return (_royaltyReceivers[0], _royaltyBPS[0]*value/10000);
    }

    ////////////////////////////////////////////////////////////////////////////
    // Overrides
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev If the base token URI is set then return the baseURI concatenated
     * with the token Id. Otherwise return the per token token URI.
     *
     * This is useful for hide and reveal drops the tokenURI is used to gather
     * initial user data but once assets are generated and metadata uploaded to
     * IPFS we can update the baseURI for all tokens and ignore the individual
     * tokenURIs.
     */
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721URIStorageUpgradeable) returns (string memory) {
        if (bytes(_baseTokenURI).length > 0) {
            return ERC721Upgradeable.tokenURI(tokenId);
        }

        return ERC721URIStorageUpgradeable.tokenURI(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }
}