// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/ICharacter.sol";
import "./helpers/MinterManaged.sol";

/**
 * @dev ASM The Next Legends - Character contract
 */
contract Character is ICharacter, ERC721Royalty, MinterManaged {
    uint256 public totalSupply;
    string public baseURI;

    mapping(uint256 => bytes32) private _hash; // tokenId => hashId (used for tokenURI)
    mapping(bytes32 => bool) private _used; // list of used hashIDs

    event BaseURIChanged(string newBaseURI);

    constructor(address manager, address asm) MinterManaged(manager, asm) ERC721("TNL Character", "TNLC") {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(MinterManaged, ICharacter, ERC721Royalty)
        returns (bool)
    {
        if (MinterManaged.supportsInterface(interfaceId)) {
            return true;
        }
        return
            interfaceId == type(ICharacter).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(ERC721Royalty).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    /** ----------------------------------
     * ! Public functions
     * ----------------------------------- */

    /**
     * @notice
     * @dev This function can only be called from contracts or wallets with MINTER_ROLE
     * @param recipient The wallet address to receive a minted token
     */
    function mint(address recipient, bytes32 hashId) external onlyRole(MINTER_ROLE) returns (uint256) {
        if (recipient == address(0)) revert InvalidInput(INVALID_ADDRESS);
        if (_used[hashId]) revert MintingError(TOKEN_ALREADY_MINTED, 0);

        _mint(recipient, totalSupply);
        _hash[totalSupply] = hashId;
        _used[hashId] = true;
        return totalSupply++;
    }

    /**
     * @notice Get tokenURI for `tokenId`
     * @notice returns baseURI + hashID of the tokenID
     * @param `tokenId` The token ID
     * @return The tokenURL as a string
     */
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        if (!_exists(tokenId)) revert AccessError(WRONG_TOKEN_ID);
        string memory hashString = Strings.toHexString(uint256(_hash[tokenId]), 32);
        return string(abi.encodePacked(_baseURI(), hashString));
    }

    /**
     * @notice Get base URI for the tokenURI
     * @return address the baseURI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /** ----------------------------------
     * ! Manager's functions
     * ----------------------------------- */

    /**
     * @notice Set base URI for the tokenURI
     * @dev emit an Event with new baseURI
     * @dev only MANAGER_ROLE can call this function
     * @param newURI new baseURI to set
     */
    function setBaseURI(string calldata newURI) external onlyRole(MANAGER_ROLE) {
        baseURI = newURI;
        emit BaseURIChanged(newURI);
    }

    /**
     * @notice Set the default royalty amount
     * @dev only MANAGER_ROLE can call this function
     * @param receiver wallet to collect royalties
     * @param feeNumerator percent of royalties, e.g. 2550 = 25.5%,  17.01% = 1701
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRole(MANAGER_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @notice Set the royalty amount for the specific token
     * @dev only MANAGER_ROLE can call this function
     * @param tokenId specific tokenId to setup royalty
     * @param receiver wallet to collect royalties
     * @param feeNumerator percent of royalties, e.g. 2550 = 25.5%,  17.01% = 1701
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(MANAGER_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function resetTokenRoyalty(uint256 tokenId) external onlyRole(MANAGER_ROLE) {
        _resetTokenRoyalty(tokenId);
    }

    /**
     * @dev Removes default royalty information.
     */
    function deleteDefaultRoyalty() external onlyRole(MANAGER_ROLE) {
        _deleteDefaultRoyalty();
    }
}