// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

interface IApprovedTokenRegistry {
    /// @notice Returns if a token has been approved or not.
    /// @param _tokenContract Contract of token being checked.
    /// @return True if the token is allowed, false otherwise.
    function isApprovedToken(address _tokenContract)
        external
        view
        returns (bool);

    /// @notice Adds a token to the list of approved tokens.
    /// @param _tokenContract Contract of token being approved.
    function addApprovedToken(address _tokenContract) external;

    /// @notice Removes a token from the approved tokens list.
    /// @param _tokenContract Contract of token being approved.
    function removeApprovedToken(address _tokenContract) external;

    /// @notice Sets whether all token contracts should be approved.
    /// @param _allTokensApproved Bool denoting if all tokens should be approved.
    function setAllTokensApproved(bool _allTokensApproved) external;
}