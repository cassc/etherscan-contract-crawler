// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Paper Key Manager
/// @author Winston Yeo
/// @notice PaperKeyManager makes it easy for developers to restrict certain functions to Paper.
/// @dev Developers are in charge of registering the contract with the initial Paper Access Token. Paper will then help you  automatically rotate and update your key in line with good security hygiene
interface IPaperKeyManager {
    /// @notice Registers a Paper Access Token to a contract
    /// @dev Registers the @param _paperKey with the caller of the function
    /// @param _paperKey The Paper Access Token that is associated with the checkout. You should be able to find this in the response of the checkout API or on the checkout dashbaord.
    /// @return bool indicating if the @param _paperKey was successfully registered with the calling address
    function register(address _paperKey) external returns (bool);

    /// @notice Verifies if the given @param _data is from Paper and have not been used before
    /// @dev Called as the first line in your function or extracted in a modifier. Refer to the Documentation for more usage details.
    /// @param _hash The bytes32 encoding of the data passed into your function
    /// @param _nonce a random set of bytes Paper passes your function which you forward. This helps ensure that the @param _hash has not been used before.
    /// @param _signature used to verify that Paper was the one who sent the @param _hash
    /// @return bool indicating if the @param _hash was successfully verified
    function verify(
        bytes32 _hash,
        bytes32 _nonce,
        bytes calldata _signature
    ) external returns (bool);

    /// @notice Checks the current registered Paper Access Token for a given contract address
    /// @param _contractAddress The contract address that is to be checked for.
    /// @return address corresponding to the expected paper Access Token that is to be resolved from signature originating from @param _contractAddress
    function checkRegisteredKey(address _contractAddress)
        external
        view
        returns (address);
}