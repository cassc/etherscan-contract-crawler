// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Base.sol";

abstract contract ERC721OperatorApprovable is ERC721Base {
    address public approvedOperator;

    /**
     * @dev See {IERC721-isApprovedForAll}. Returns true if `_operator` is approved operator
     */
    function isApprovedForAll(address _owner, address _operator) public view virtual override returns (bool) {
        // if approved operator address is detected, auto-return true
        if (_operator == approvedOperator) {
            return true;
        }
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    /**
     * @dev Updates approved operator address
     * @param operator New address to be approved
     */
    function setApprovedOperator(address operator) external onlyOwner {
        approvedOperator = operator;
    }
}