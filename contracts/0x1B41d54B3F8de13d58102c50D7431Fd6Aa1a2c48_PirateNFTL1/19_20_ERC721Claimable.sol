// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract ERC721Claimable is Context, ERC721, AccessControl {
    error InvalidInput();

    bytes32 public constant TRUSTED_CLAIM_ROLE = keccak256("TRUSTED_CLAIM_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(TRUSTED_CLAIM_ROLE, DEFAULT_ADMIN_ROLE);
    }

    // ** Bulk action for airdrops/claims **
    // If we are using claim we should not be using mint or unexpected results may occur.
    function claim(
        uint256[] calldata tokenIds,
        address[] calldata addresses
    ) external onlyRole(TRUSTED_CLAIM_ROLE) {
        if (tokenIds.length != addresses.length) {
            revert InvalidInput();
        }

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            //todo: can we do optimizations
            if (tokenIds[i] == 0) {
                revert InvalidInput();
            }
            _mint(addresses[i], tokenIds[i]);
        }
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(AccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}