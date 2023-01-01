// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../common/Errors.sol";
import "../../../../access/roles/AccessControlInternal.sol";
import "../../extensions/mintable/IERC1155MintableExtension.sol";
import "../../base/ERC1155BaseInternal.sol";
import "./IERC1155MintableRoleBased.sol";

/**
 * @title ERC1155 - Mint as role
 * @notice Allow minting for grantees of MINTER_ROLE.
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:required-dependencies IERC1155MintableExtension
 * @custom:provides-interfaces IERC1155MintableRoleBased
 */
contract ERC1155MintableRoleBased is IERC1155MintableRoleBased, AccessControlInternal {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @inheritdoc IERC1155MintableRoleBased
     */
    function mintByRole(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual onlyRole(MINTER_ROLE) {
        IERC1155MintableExtension(address(this)).mintByFacet(to, id, amount, data);
    }

    /**
     * @inheritdoc IERC1155MintableRoleBased
     */
    function mintByRole(
        address[] calldata tos,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes[] calldata datas
    ) public virtual onlyRole(MINTER_ROLE) {
        IERC1155MintableExtension(address(this)).mintByFacet(tos, ids, amounts, datas);
    }
}