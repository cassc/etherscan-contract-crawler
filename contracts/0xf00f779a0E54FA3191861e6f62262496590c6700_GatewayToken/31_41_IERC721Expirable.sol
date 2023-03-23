// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../library/Charge.sol";

interface IERC721Expirable {
    /**
    * @dev Emitted when expiration set to `tokenId`
    */
    event Expiration(uint256 indexed tokenId, uint256 timestamp);

    /**
    * @dev Get the gateway token expiry
    * @param tokenId Gateway token id
    */
    function getExpiration(uint256 tokenId) external view returns (uint256);

    /**
    * @dev Set the gateway token expiry
    * @param tokenId Gateway token id
    * @param tokenId Expiration timestamp
    * @param charge The charge details for token issuance (ignored here - handled if at all by the forwarding contract)
    */
    function setExpiration(uint256 tokenId, uint256 timestamp, Charge calldata charge) external;
}