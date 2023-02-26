// SPDX-License-Identifier: MIT
// Indelible Labs LLC

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";

/**
 * @dev This implements an optional extension of {ERC721} that automatically
 * expires approvals for operators to transfer your tokens after 30 days or
 * the set approval lifespan.
 */
abstract contract ERC721AX is ERC721A {
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => uint)) private _operatorApprovals;
    mapping(address => uint128) public approvalLifespans;

    // Approval lifespan
    uint128 constant public DEFAULT_APPROVAL_LIFESPAN = 30 days;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721A) {
        require(_msgSenderERC721A() != operator, "ERC721: approve to caller");
        uint128 approvalLifespan = approvalLifespans[_msgSenderERC721A()] > 0 ? approvalLifespans[_msgSenderERC721A()] : DEFAULT_APPROVAL_LIFESPAN;
        _operatorApprovals[_msgSenderERC721A()][operator] = approved ? block.timestamp + approvalLifespan : 0;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override(ERC721A) returns (bool) {
        return _operatorApprovals[owner][operator] > block.timestamp;
    }
    
    /**
     * @dev Set the lifespan of an approval in days.
     */
    function setApprovalLifespanDays(uint128 lifespanDays) public {
        approvalLifespans[msg.sender] = lifespanDays * 1 days;
    }
}