// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.13;

import {ERC721, ERC721Claimable} from "@proofofplay/erc721-extensions/src/L1/ERC721Claimable.sol";
import {ERC721ContractURI} from "@proofofplay/erc721-extensions/src/ERC721ContractURI.sol";
import {ERC721OperatorFilter} from "@proofofplay/erc721-extensions/src/ERC721OperatorFilter.sol";
import {ERC721AfterTokenTransferHandler} from "@proofofplay/erc721-extensions/src/ERC721AfterTokenTransferHandler.sol";

/** @title Updated PirateNFT for L1
 * @notice This contract is an upgraded contract of our PirateNFTParent, which is now deprecated with the release of this contract.
 */
contract PirateNFTL1 is
    ERC721Claimable,
    ERC721ContractURI,
    ERC721OperatorFilter,
    ERC721AfterTokenTransferHandler
{
    string private _baseTokenURI;
    uint256 private _totalSupply;

    error NotOwnerOrApproved(uint256 tokenId);

    //todo: we should check if we need anything else from l1 token before we do anything else.

    /** Constructor */
    constructor(uint256 maxSupply) ERC721("Pirate", "PIRATE") {
        _totalSupply = maxSupply;
    }

    /**
     * @notice Returns the total supply of the collection
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Sets the total supply of the collection
     */
    function setTotalSupply(
        uint256 supply
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _totalSupply = supply;
    }

    /**
     * @param tokenId token id to check
     * @return Whether or not the given tokenId has been minted
     */
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /**
     *
     * @param tokenId token id to burn
     */
    function burn(uint256 tokenId) external {
        if (msg.sender != ownerOf(tokenId)) {
            require(
                isApprovedForAll(ownerOf(tokenId), msg.sender),
                "ERC721: caller is not owner nor approved"
            );
        }
        _burn(tokenId);
        _totalSupply -= 1;
    }

    /**
     * @notice Handles any pre-transfer actions
     * @inheritdoc ERC721
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override(ERC721, ERC721OperatorFilter) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
     * @notice Handles any pre-transfer actions
     * @inheritdoc ERC721
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override(ERC721, ERC721AfterTokenTransferHandler) {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
     * @notice Handles interfaces
     * @inheritdoc ERC721
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC721Claimable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(
        string calldata newURI
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = newURI;
    }

    /** @return Base URI for the tokenURI function */
    function getBaseURI() external view returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}