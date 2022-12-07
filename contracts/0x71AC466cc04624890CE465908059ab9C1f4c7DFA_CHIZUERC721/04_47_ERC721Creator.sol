// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "../OZ/OZERC721Upgradeable.sol";
import "../utils/BytesUtil.sol";
import "./ERC721ProxyCall.sol";
import "../interfaces/ITokenCreator.sol";
import "../utils/AccountMigrationUtil.sol";

error ERC721Creator_Time_Expired();

/**
 * @title Allows each token to be associated with a creator.
 * @notice Also manages the payment address for each NFT, allowing royalties to be split with collaborators.
 */
abstract contract ERC721Creator is
    OZERC721Upgradeable,
    ITokenCreator,
    ERC721ProxyCall
{
    using AccountMigrationUtil for address;
    using BytesUtil for bytes;
    using ECDSA for bytes32;

    /**
     * @notice Stores the creator address for each NFT.
     */
    mapping(uint256 => address payable) private tokenIdToCreator;
    /**
     * @notice Emitted when the creator for an NFT is set.
     * @param fromCreator The original creator address for this NFT.
     * @param toCreator The new creator address for this NFT.
     * @param tokenId The token ID for the NFT which was updated.
     */
    event TokenCreatorUpdated(
        address indexed fromCreator,
        address indexed toCreator,
        uint256 indexed tokenId
    );

    /**
     * @notice Emitted when the creator for an NFT is changed through account migration.
     * @param tokenId The tokenId of the NFT which had the creator changed.
     * @param originalAddress The original creator address for this NFT.
     * @param newAddress The new creator address for this NFT.
     */
    event NFTCreatorMigrated(
        uint256 indexed tokenId,
        address indexed originalAddress,
        address indexed newAddress
    );
    /**
     * @notice Emitted when the owner of an NFT is changed through account migration.
     * @param tokenId The tokenId of the NFT which had the owner changed.
     * @param originalAddress The original owner address for this NFT.
     * @param newAddress The new owner address for this NFT.
     */
    event NFTOwnerMigrated(
        uint256 indexed tokenId,
        address indexed originalAddress,
        address indexed newAddress
    );

    event Burned(uint256 tokenId, bytes32 indexed burnHash);

    /**
     * @notice Allows the creator to burn if they currently own the NFT.
     * @param tokenId The tokenId of the NFT to be burned.
     */
    function burn(
        uint256 tokenId,
        uint256 expiredAt,
        address nodeAddress,
        bytes32 burnHash,
        bytes memory burnSignature
    ) external {
        if (expiredAt < block.timestamp) {
            revert ERC721Creator_Time_Expired();
        }
        _validateBurnSignature(
            address(this),
            msg.sender,
            tokenId,
            expiredAt,
            nodeAddress,
            burnHash,
            burnSignature
        );
        require(
            tokenIdToCreator[tokenId] == msg.sender,
            "ERC721Creator: Caller is not creator"
        );
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721Creator: Caller is not owner nor approved"
        );
        _burn(tokenId);
        emit Burned(tokenId, burnHash);
    }

    /**
     * @dev Remove the creator and payment address records when burned.
     */
    function _burn(uint256 tokenId) internal virtual override {
        delete tokenIdToCreator[tokenId];

        // Delete the NFT details.
        super._burn(tokenId);
    }

    function _updateTokenCreator(uint256 tokenId, address payable creator)
        internal
    {
        emit TokenCreatorUpdated(tokenIdToCreator[tokenId], creator, tokenId);

        tokenIdToCreator[tokenId] = creator;
    }

    function _validateBurnSignature(
        address contractAddress,
        address creator,
        uint256 tokenId,
        uint256 expiredAt,
        address nodeAddress,
        bytes32 burnHash,
        bytes memory burnSignature
    ) internal view returns (bool success, string memory message) {
        if (!INodeRole(core).isNode(nodeAddress)) {
            return (false, "ERC721Creator : is not node");
        }
        bytes32 calculatedHash = keccak256(
            abi.encodePacked(
                uint256(uint160(contractAddress)),
                uint256(uint160(creator)),
                uint256(tokenId),
                uint256(expiredAt)
            )
        );
        bytes32 calculatedOrigin = calculatedHash.toEthSignedMessageHash();

        address recoveredSigner = calculatedOrigin.recover(burnSignature);

        if (calculatedHash != burnHash) {
            return (false, "ERC721Creator : hash does not match");
        }
        if (recoveredSigner != nodeAddress) {
            return (false, "ERC721Creator : signer does not match");
        }
        success = true;
    }

    /**
     * @inheritdoc ERC165
     * @dev Checks the ITokenCreator interface.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (interfaceId == type(ITokenCreator).interfaceId) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    /**
     * @param tokenId The tokenId of the NFT to get the creator
     * @return creator The creator's address for the given tokenId.
     */
    function tokenCreator(uint256 tokenId)
        public
        view
        override
        returns (address payable creator)
    {
        creator = tokenIdToCreator[tokenId];
    }

    /**
     * @notice This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[1000] private __gap;
}