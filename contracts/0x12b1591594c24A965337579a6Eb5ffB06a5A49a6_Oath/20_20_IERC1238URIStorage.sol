// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../IERC1238.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Proposal of an interface for ERC1238 token with storage based token URI management.
 */
interface IERC1238URIStorage is IERC1238 {
    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     */
    event URI(uint256 indexed id, string value);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `id` token.
     */
    function tokenURI(uint256 id) external view returns (string memory);
}