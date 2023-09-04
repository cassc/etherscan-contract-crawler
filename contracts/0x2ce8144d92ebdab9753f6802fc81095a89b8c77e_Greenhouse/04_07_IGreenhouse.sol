// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IGreenhouse {
    /// @notice Thrown if salt `salt` already planted.
    /// @param salt The salt to plant.
    error AlreadyPlanted(bytes32 salt);

    /// @notice Thrown if planting at salt `salt` failed.
    /// @param salt The salt to plant.
    error PlantingFailed(bytes32 salt);

    /// @notice Thrown if provided salt is empty.
    error EmptySalt();

    /// @notice Thrown if provided creation code is empty.
    error EmptyCreationCode();

    /// @notice Emitted when new contract planted.
    /// @param caller The caller's address.
    /// @param salt The salt the contract got planted at.
    /// @param addr The address of the planted contract.
    event Planted(
        address indexed caller, bytes32 indexed salt, address indexed addr
    );

    /// @notice Plants a new contract with creation code `creationCode` to a
    ///         deterministic address solely depending on the salt `salt`.
    ///
    /// @dev Only callable by toll'ed addresses.
    ///
    /// @dev Note to add constructor arguments to the creation code, if
    ///      applicable!
    ///
    /// @custom:example Appending constructor arguments to the creation code:
    ///
    ///     ```solidity
    ///     bytes memory creationCode = abi.encodePacked(
    ///         // Receive the creation code of `MyContract`.
    ///         type(MyContract).creationCode,
    ///
    ///         // `MyContract` receives as constructor arguments an address
    ///         // and a uint.
    ///         abi.encode(address(0xcafe), uint(1))
    ///     );
    ///     ```
    ///
    /// @param salt The salt to plant the contract at.
    /// @param creationCode The creation code of the contract to plant.
    /// @return The address of the planted contract.
    function plant(bytes32 salt, bytes memory creationCode)
        external
        returns (address);

    /// @notice Returns the deterministic address for salt `salt`.
    /// @dev Note that the address is not guaranteed to be utilized yet.
    ///
    /// @custom:example Verifying a contract is planted at some salt:
    ///
    ///     ```solidity
    ///     bytes32 salt = bytes32("salt");
    ///     address contract_ = addressOf(salt);
    ///     bool isPlanted = contract_.code.length != 0;
    ///     ```
    ///
    /// @param salt The salt to query their deterministic address.
    /// @return The deterministic address for given salt.
    function addressOf(bytes32 salt) external view returns (address);
}