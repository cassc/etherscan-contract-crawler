// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an IInscription compliant contract.
 */
interface IInscription is IERC165 {
    /**
     * @dev Emitted when `inscriptionId` inscription is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed inscriptionId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the owner of the `inscriptionId` inscription.
     *
     * Requirements:
     *
     * - `inscriptionId` must exist.
     */
    function ownerOf(uint256 inscriptionId) external view returns (address owner);

    /**
     * @dev Safely transfers `inscriptionId` inscription from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `inscriptionId` inscription must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this inscription by {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IInscriptionReceiver-onInscriptionReceived}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 inscriptionId,
        bytes calldata data
    ) external;


    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {safeTransferFrom} for any inscription owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}