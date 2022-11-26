//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/** @title NFT contract for imbued works of art
    @author 0xsublime.eth
    @notice This contract is the persistent center of the Imbued Art project,
    and allows unstoppable ownership of the NFTs. The minting is controlled by a
    separate contract, which is upgradeable. This contract enforces a 700 token
    limit: 7 editions of 100 tokens.

    The dataContract is intended to serve as a store for metadata, animations,
    code, etc.

    The owner of a token can imbue it with meaning. The imbuement is a string,
    up to 32 bytes long. The history of a tokens owenrship and its imbuements
    are stored and are retrievable via view functions.

    Token transfers are initially turned off for all editions. Once a transfers
    are activated on an edition of tokens, it cannot be disallowed again.
 */
interface IImbuedNFT is IERC721Enumerable {

    /// @dev The contract controlling minting
    function mintContract() external view returns (address);
    /// @dev For storing metadata, animations, code.
    function dataContract() external view returns (address); 

    function NUM_EDITIONS() external pure returns (uint256);
    function EDITION_SIZE() external pure returns (uint256);

    /// Tokens are marked transferable at the edition level.
    function editionTransferable(uint256) external pure returns (bool);

    function baseURI() external pure returns (string memory);

    /// Maps a token to its history of owners.
    function id2provenance(uint256) external view returns (address[] memory);
    /// Maps a (token, owner) pair to its imbuement.
    function idAndOwner2imbuement(uint256, address) external view returns (string memory);

    event Imbued(uint256 indexed tokenId, address indexed owner, string imbuement);
    event EditionTransferable(uint256 indexed edition);

    // ===================================
    // Mint contract privileged functions.
    // ===================================

    /** @dev The mint function can only be called by the minter address.
        @param recipient The recipient of the minted token, needs to be an EAO or a contract which accepts ERC721s.
        @param tokenId The token ID to mint.
     */
    function mint(address recipient, uint256 tokenId) external;
    // ==============
    // NFT functions.
    // ==============

    /** Saves an imbuement for a token and owner.
        An imbuement is a string, up to 32 bytes (equivalent to 32 ASCII
        characters).  Once set, it is immuatble.  Only the owner, or an address
        which has permission to control the token, can imbue it.
        @param tokenId The token to imbue.
        @param imbuement The string that should be saved
     */
    function imbue(uint256 tokenId, string calldata imbuement) external;

    // ===============
    // View functions.
    // ===============

    /// Get the complete list of imbuements for a token.
    /// @param id ID of the token to get imbuements for
    /// @param start start of the range to return (inclusive)
    /// @param end end of the range to return (non-inclusive), or 0 for max length.
    /// @return A string array, each string at most 32 bytes.
    function imbuements(uint256 id, uint256 start, uint256 end) external view returns (string[] memory);

    /// Get the chronological list of owners of a token.
    /// @param id The token ID to get the provenance for.
    /// @param start start of the range to return (inclusive)
    /// @param end end of the range to return (non-inclusive), or 0 for max length.
    /// @return An address array of all owners, listed chornologically.
    function provenance(uint256 id, uint256 start, uint256 end) external view returns (address[] memory);

    // =====================
    // Only owner functions.
    // =====================

    function setMintContract(address _mintContract) external;
    function setDataContract(address _dataContract) external;

    function setBaseURI(string memory newBaseURI) external;

    /// @dev Edition transfers can only be allowed, there is no way to disallow them later.
    function setEditionTransferable(uint256 edition) external;


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external;

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;
}