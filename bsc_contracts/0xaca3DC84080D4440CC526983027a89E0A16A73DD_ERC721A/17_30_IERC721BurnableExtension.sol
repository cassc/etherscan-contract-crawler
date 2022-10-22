// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @dev Extension of {ERC721} that allows holders or approved operators to burn tokens.
 */
interface IERC721BurnableExtension {
    function burn(uint256 id) external;

    function burnBatch(uint256[] memory ids) external;

    function burnByFacet(uint256 id) external;

    function burnBatchByFacet(uint256[] memory ids) external;
}