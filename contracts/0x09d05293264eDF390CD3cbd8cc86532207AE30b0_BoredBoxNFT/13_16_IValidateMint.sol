// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/// Completely optional contract that customizes mint requirements
interface IValidateMint {
    /// Throws `revert` or `require` error message to halt execution
    /// Returns 0 VALIDATE_STATUS__NA
    /// Returns 1 VALIDATE_STATUS__PASS
    /// Returns 2 VALIDATE_STATUS__FAIL
    /// It is up to caller to figure out what to do with returned `bool`
    /// @param to Address that will receive NFT if operation is valid
    /// @param boxId Generation key to possibly use internally or by checking calling contract strage
    /// @param tokenId Specific token ID that needs to be minted
    /// @param auth Optional extra data to require for validation process
    function validate(
        address to,
        uint256 boxId,
        uint256 tokenId,
        bytes memory auth
    ) external view returns (uint256 validate_status);
}