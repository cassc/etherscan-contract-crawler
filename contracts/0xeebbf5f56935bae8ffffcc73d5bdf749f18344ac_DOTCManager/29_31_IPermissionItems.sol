/* solhint-disable */
//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @title Interface for PermissionItems
 * @author Swarm
 * @dev Interface for contract which provides a permissioning mechanism through the asisgnation of ERC1155 tokens.
 * It inherits from standard EIP1155 and extends functionality for
 * role based access control and makes tokens non-transferable.
 */
interface IPermissionItems is IERC1155, IAccessControl {
    // Constants for roles assignments
    function MINTER_ROLE() external returns (bytes32);

    function BURNER_ROLE() external returns (bytes32);

    /**
     * @dev Grants TRANSFER role to `account`.
     *
     * Grants MINTER role to `account`.
     * Grants BURNER role to `account`.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function setAdmin(address account) external;

    /**
     * @dev Revokes TRANSFER role to `account`.
     *
     * Revokes MINTER role to `account`.
     * Revokes BURNER role to `account`.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeAdmin(address account) external;

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - the caller must have MINTER role.
     * - `account` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - the caller must have BURNER role.
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function burn(address account, uint256 id, uint256 value) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external;

    /**
     * @dev Disabled setApprovalForAll function.
     *
     */
    function setApprovalForAll(address, bool) external pure;

    /**
     * @dev Disabled safeTransferFrom function.
     *
     */
    function safeTransferFrom(address, address, uint256, uint256, bytes memory) external pure;

    /**
     * @dev Disabled safeBatchTransferFrom function.
     *
     */
    function safeBatchTransferFrom(address, address, uint256[] memory, uint256[] memory, bytes memory) external pure;

    /**
     * See {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}