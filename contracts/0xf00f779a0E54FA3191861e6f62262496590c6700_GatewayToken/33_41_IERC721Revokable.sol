// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721Revokable {
    /**
    * @dev Emitted when GatewayToken is revoked.
    */
    event Revoke(uint256 indexed tokenId);

    /**
    * @dev Triggers to revoke gateway token
    * @param tokenId Gateway token id
    */
    function revoke(uint256 tokenId) external;
}