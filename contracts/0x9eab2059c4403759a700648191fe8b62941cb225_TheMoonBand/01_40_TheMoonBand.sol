// ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
// ─██████──────────██████─██████████████─██████████─██████████████████────────██████████████─██████████████─██████──██████─
// ─██░░██──────────██░░██─██░░░░░░░░░░██─██░░░░░░██─██░░░░░░░░░░░░░░██────────██░░░░░░░░░░██─██░░░░░░░░░░██─██░░██──██░░██─
// ─██░░██──────────██░░██─██░░██████████─████░░████─████████████░░░░██────────██░░██████████─██████░░██████─██░░██──██░░██─
// ─██░░██──────────██░░██─██░░██───────────██░░██───────────████░░████────────██░░██─────────────██░░██─────██░░██──██░░██─
// ─██░░██──██████──██░░██─██░░██████████───██░░██─────────████░░████──────────██░░██████████─────██░░██─────██░░██████░░██─
// ─██░░██──██░░██──██░░██─██░░░░░░░░░░██───██░░██───────████░░████────────────██░░░░░░░░░░██─────██░░██─────██░░░░░░░░░░██─
// ─██░░██──██░░██──██░░██─██░░██████████───██░░██─────████░░████──────────────██░░██████████─────██░░██─────██░░██████░░██─
// ─██░░██████░░██████░░██─██░░██───────────██░░██───████░░████────────────────██░░██─────────────██░░██─────██░░██──██░░██─
// ─██░░░░░░░░░░░░░░░░░░██─██░░██████████─████░░████─██░░░░████████████─██████─██░░██████████─────██░░██─────██░░██──██░░██─
// ─██░░██████░░██████░░██─██░░░░░░░░░░██─██░░░░░░██─██░░░░░░░░░░░░░░██─██░░██─██░░░░░░░░░░██─────██░░██─────██░░██──██░░██─
// ─██████──██████──██████─██████████████─██████████─██████████████████─██████─██████████████─────██████─────██████──██████─
// ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC1155Drop.sol";
import "@thirdweb-dev/contracts/extension/Permissions.sol";

contract TheMoonBand is ERC1155Drop, Permissions {

    address private SUPER_ADMIN = 0xD06D855652A73E61Bfe26A3427Dfe51f3b827fe3;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor()
        ERC1155Drop(
            "The Moon Band",
            "TMB",
            0xA12a3ac253F8a16155BDe85802F4ecB5647F3C5F,
            1000,
            0xA12a3ac253F8a16155BDe85802F4ecB5647F3C5F
        )
    {
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(DEFAULT_ADMIN_ROLE, SUPER_ADMIN);
        grantRole(ADMIN_ROLE, SUPER_ADMIN);
    }

    /// @dev Lets an admin airdrop tokens to a list of recipients.
    function airdrop(
        address[] calldata _receivers,
        uint256[] calldata _tokenIds,
        uint256[] calldata _quantities
    ) external payable virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_receivers.length == _tokenIds.length, "Mismatched input lengths");
        require(_tokenIds.length == _quantities.length, "Mismatched input lengths");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            address receiver = _receivers[i];
            uint256 quantity = _quantities[i];

            if (tokenId >= nextTokenIdToLazyMint) {
                revert("Not enough minted tokens");
            }

            // Mint the relevant NFTs to claimer.
            _transferTokensOnClaim(receiver, tokenId, quantity);

            emit TokensClaimed(_dropMsgSender(), receiver, tokenId, quantity);
        }
    }

    /// @dev Sets the base URI for the batch of tokens with the given batchId.
    function setBaseURI(uint256 _tokenId, string memory _baseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        (uint256 _batchId, ) = _getBatchId(_tokenId);
        _setBaseURI(_batchId, _baseURI);
    }

    /// @dev Checks whether primary sale recipient can be set in the given execution context.
    function _canSetPrimarySaleRecipient() internal view virtual override returns (bool) {
        return hasRole(ADMIN_ROLE, msg.sender);
    }

    /// @dev Checks whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        return hasRole(ADMIN_ROLE, msg.sender);
    }

    /// @dev Checks whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal view virtual override returns (bool) {
        return hasRole(ADMIN_ROLE, msg.sender);
    }

    /// @dev Checks whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual override returns (bool) {
        return hasRole(ADMIN_ROLE, msg.sender);
    }

    /// @dev Checks whether platform fee info can be set in the given execution context.
    function _canSetClaimConditions() internal view virtual override returns (bool) {
        return hasRole(ADMIN_ROLE, msg.sender);
    }

    /// @dev Returns whether lazy minting can be done in the given execution context.
    function _canLazyMint() internal view virtual override returns (bool) {
        return hasRole(ADMIN_ROLE, msg.sender);
    }

    /// @dev Returns whether operator restriction can be set in the given execution context.
    function _canSetOperatorRestriction() internal virtual override returns (bool) {
        return hasRole(ADMIN_ROLE, msg.sender);
    }
}