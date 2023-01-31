// SPDX-License-Identifier: MIT
// Unagi Contracts v1.0.0 (UltimateChampionsNFT.sol)
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title UltimateChampionsNFT
 * @dev Implementation of IERC721. NFCHAMP is described using the ERC721Metadata extension.
 * See https://github.com/ethereum/EIPs/blob/34a2d1fcdf3185ca39969a7b076409548307b63b/EIPS/eip-721.md#specification
 * @custom:security-contact [email protected]
 */
contract UltimateChampionsNFT is
    ERC721URIStorage,
    AccessControl,
    Multicall,
    Pausable
{
    using Counters for Counters.Counter;

    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // Counter for token ID
    Counters.Counter private _tokenIds;

    /**
     * @dev Create NFCHAMP contract.
     */
    constructor(uint256 initialId)
        ERC721("Non Fungible Ultimate Champions", "NFCHAMP")
    {
        _tokenIds._value = initialId;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINT_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    /**
     * @dev Pause token transfers.
     *
     * Requirements:
     *
     * - Caller must have role PAUSER_ROLE.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause token transfers.
     *
     * Requirements:
     *
     * - Caller must have role PAUSER_ROLE.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Allow to mint a new NFCHAMP.
     *
     * Requirements:
     *
     * - Caller must have role MINT_ROLE.
     */
    function safeMint(address to, string memory ipfsMedataURI)
        public
        onlyRole(MINT_ROLE)
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(to, newItemId);
        _setTokenURI(newItemId, ipfsMedataURI);
    }

    /**
     * @dev Before token transfer hook.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}