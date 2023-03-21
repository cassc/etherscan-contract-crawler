// SPDX-License-Identifier: GPL-3.0-only

// ┏━━━┓━━━━━┏┓━━━━━━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━━━━━
// ┃┏━┓┃━━━━┏┛┗┓━━━━━━━━┃┏━━┛━━━━━━━━━━━━━━━━━━━━━━━
// ┃┗━┛┃┏━┓━┗┓┏┛┏━━┓━━━━┃┗━━┓┏┓┏━┓━┏━━┓━┏━┓━┏━━┓┏━━┓
// ┃┏━┓┃┃┏┓┓━┃┃━┃┏┓┃━━━━┃┏━━┛┣┫┃┏┓┓┗━┓┃━┃┏┓┓┃┏━┛┃┏┓┃
// ┃┃ ┃┃┃┃┃┃━┃┗┓┃┃━┫━┏┓━┃┃━━━┃┃┃┃┃┃┃┗┛┗┓┃┃┃┃┃┗━┓┃┃━┫
// ┗┛ ┗┛┗┛┗┛━┗━┛┗━━┛━┗┛━┗┛━━━┗┛┗┛┗┛┗━━━┛┗┛┗┛┗━━┛┗━━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

pragma solidity ^0.8.0;

/// @title The interface for the Ante V0.6 Ante Test
/// @notice The Ante V0.6 Ante Test wraps test logic for verifying fundamental invariants of a protocol
interface IAnteTest {
    /// @notice Emitted when the test author is changed
    /// @param previousAuthor The address of the previous author
    /// @param newAuthor The address of the new author
    event TestAuthorChanged(address indexed previousAuthor, address indexed newAuthor);

    /// @notice Function containing the logic to set the AnteTest state and call checkTestPasses
    /// @param _state The encoded data required to set the test state
    /// @return A single bool indicating if the Ante Test passes/fails
    function setStateAndCheckTestPasses(bytes memory _state) external returns (bool);

    /// @notice Function containing test logic to inspect the protocol invariant
    /// @dev This should usually return True
    /// @return A single bool indicating if the Ante Test passes/fails
    function checkTestPasses() external returns (bool);

    /// @notice Returns the author of the Ante Test
    /// @dev This overrides the auto-generated getter for testAuthor as a public var
    /// @return The address of the test author
    function testAuthor() external view returns (address);

    /// @notice Sets the author of the Ante Test
    /// @dev This can only be called by the current author, which is the deployer initially
    /// @param _testAuthor The address of the test author
    function setTestAuthor(address _testAuthor) external;

    /// @notice Returns the name of the protocol the Ante Test is testing
    /// @dev This overrides the auto-generated getter for protocolName as a public var
    /// @return The name of the protocol in string format
    function protocolName() external view returns (string memory);

    /// @notice Returns a single address in the testedContracts array
    /// @dev This overrides the auto-generated getter for testedContracts [] as a public var
    /// @param i The array index of the address to return
    /// @return The address of the i-th element in the list of tested contracts
    function testedContracts(uint256 i) external view returns (address);

    /// @notice Returns the name of the Ante Test
    /// @dev This overrides the auto-generated getter for testName as a public var
    /// @return The name of the Ante Test in string format
    function testName() external view returns (string memory);

    /// @notice Returns a string of comma delimited types used for setting the AnteTest state
    /// @return The types of the state variables
    function getStateTypes() external pure returns (string memory);
}