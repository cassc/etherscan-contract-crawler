// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title CAN Soulbound token inteface
 */
interface ISBT {
    /// @dev emit when the contract uri is changed.
    event ContractURISet(string contractURI);

    /// @dev emit when the base URI is changed.
    event BaseURISet(string baseURI);

    /// @dev emit when the token revoked with reason
    event RevokedByReason(address owner, uint256 tokenId, string reason);

    /// @dev emit when the token is set expiration
    event ExpirationSet(uint256 tokenId, uint256 expiration);

    /// @dev emit when the contract is set claimable
    event ClaimableSet(bool claimable);

    /// @dev emit when the token is burned
    event Burned(uint256 tokenId);

    /// @dev mark the token as revoked by contract owner only
    function revoke(uint256 tokenId, string calldata reason) external;

    /// @dev claim a SBT
    function claim() external;

    /// @dev mint to receivers
    function mint(address[] calldata receivers, uint256 expiration) external;

    /// @dev burn a SBT
    function burn(uint256 tokenId) external;

    /// @dev set a minter list
    function setMinters(address[] calldata minters) external;

    /// @dev enable/disable claiming SBT
    function setClaimable(bool claimable) external;

    /// @dev set SBT expiration
    function setExpiration(uint256 tokenId, uint256 expiration) external;

    /// @dev set the base token URI
    function setBaseURI(string calldata baseURI) external;

    /// @dev set the contract URI
    function setContractURI(string calldata contractURI_) external;

    /// @dev get the contract URI
    function contractURI() external view returns (string memory);
}