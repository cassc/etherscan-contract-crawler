// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

interface IAllowlist {
    /// @notice         Check if address is allowed to interact with sending contract
    /// @param user_    Address to check
    /// @param proof_   Data to be used in determining allow status (optional, depends on specific implementation)
    /// @return         True if allowed, false otherwise
    function isAllowed(address user_, bytes calldata proof_) external view returns (bool);

    /// @notice         Check if address is allowed to interact with market ID on sending contract
    /// @param id_      Market ID to check
    /// @param user_    Address to check
    /// @param proof_   Data to be used in determining allow status (optional, depends on specific implementation
    /// @return         True if allowed, false otherwise
    function isAllowed(
        uint256 id_,
        address user_,
        bytes calldata proof_
    ) external view returns (bool);

    /// @notice         Register allowlist for sending address
    /// @dev            Can be used to intialize or update an allowlist
    /// @param params_  Parameters to configure allowlist (depends on specific implementation)
    function register(bytes calldata params_) external;

    /// @notice         Register allowlist for market ID on sending address
    /// @dev            Can be used to intialize or update an allowlist
    /// @param id_      Market ID to register allowlist for
    /// @param params_  Parameters to configure allowlist (depends on specific implementation)
    function register(uint256 id_, bytes calldata params_) external;
}