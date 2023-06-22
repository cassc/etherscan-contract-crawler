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

import "../interfaces/IAntePoolFactoryController.sol";

/// @title The interface for the Ante V0.6 Ante Pool Factory
/// @notice The Ante V0.6 Ante Pool Factory programmatically generates an AntePool for a given AnteTest
interface IAntePoolFactory {
    /// @notice Emitted when an AntePool is created from an AnteTest
    /// @param testAddr The address of the AnteTest used to create the AntePool
    /// @param tokenAddr The address of the ERC20 Token used to stake
    /// @param tokenMinimum The minimum allowed stake amount
    /// @param payoutRatio The payout ratio of the pool
    /// @param decayRate The decay rate of the pool
    /// @param authorRewardRate The test writer reward rate
    /// @param testPool The address of the AntePool created by the factory
    /// @param poolCreator address which created the pool (msg.sender on createPool)
    event AntePoolCreated(
        address indexed testAddr,
        address tokenAddr,
        uint256 tokenMinimum,
        uint256 payoutRatio,
        uint256 decayRate,
        uint256 authorRewardRate,
        address testPool,
        address poolCreator
    );

    /// @notice Emitted when pushing the fail state to a pool reverts.
    event PoolFailureReverted();

    /// @notice Creates an AntePool for an AnteTest and returns the AntePool address
    /// @param testAddr The address of the AnteTest to create an AntePool for
    /// @param tokenAddr The address of the ERC20 Token used to stake
    /// @param payoutRatio The payout ratio of the pool
    /// @param decayRate The decay rate of the pool
    /// @param authorRewardRate The test writer reward rate
    /// @return testPool - The address of the generated AntePool
    function createPool(
        address testAddr,
        address tokenAddr,
        uint256 payoutRatio,
        uint256 decayRate,
        uint256 authorRewardRate
    ) external returns (address testPool);

    /// @notice Returns the historic failure state of a given ante test
    /// @param testAddr Address of the test to check
    function hasTestFailed(address testAddr) external view returns (bool);

    /// @notice Runs the verification of the invariant of the connected Ante Test, called by a pool
    /// @param _testState The encoded data required to set the test state
    /// @param verifier The address of who called the test verification
    /// @param poolConfig config hash of the AntePool calling the method. Used for gas effective authorization
    function checkTestWithState(
        bytes memory _testState,
        address verifier,
        bytes32 poolConfig
    ) external;

    /// @notice Returns a single address in the allPools array
    /// @param i The array index of the address to return
    /// @return The address of the i-th AntePool created by this factory
    function allPools(uint256 i) external view returns (address);

    /// @notice Returns the address of the AntePool corresponding to a given AnteTest
    /// @param testAddr address of the AnteTest to look up
    /// @return The addresses of the corresponding AntePools
    function getPoolsByTest(address testAddr) external view returns (address[] memory);

    /// @notice Returns the number of AntePools corresponding to a given AnteTest
    /// @param testAddr address of the AnteTest to look up
    /// @return The number of pools for a specified AnteTest
    function getNumPoolsByTest(address testAddr) external view returns (uint256);

    /// @notice Returns the address of the AntePool corresponding to a given config hash
    /// @param configHash config hash of the AntePool to look up
    /// @return The address of the corresponding AntePool
    function poolByConfig(bytes32 configHash) external view returns (address);

    /// @notice Returns the number of pools created by this factory
    /// @return Number of pools created.
    function numPools() external view returns (uint256);

    /// @notice Returns the Factory Controller used for whitelisting tokens
    /// @return IAntePoolFactoryController The Ante Factory Controller interface
    function controller() external view returns (IAntePoolFactoryController);
}