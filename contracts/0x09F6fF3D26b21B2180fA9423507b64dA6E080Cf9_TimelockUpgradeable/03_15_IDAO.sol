import "./IModuleBase.sol";

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IDAO {
    error Unauthorized(bytes32 role, address account);
    error UnequalArrayLengths();

    event Executed(address[] targets, uint256[] values, bytes[] calldatas);

    /// @notice Function for initializing the Dao
    /// @param _accessControl The address of the access control contract
    /// @param _moduleFactoryBase The address of the module factory
    /// @param _name Name of the Dao
    function initialize(address _accessControl, address _moduleFactoryBase, string calldata _name) external;

    /// @notice A function for executing function calls from the DAO
    /// @param targets An array of addresses to target for the function calls
    /// @param values An array of ether values to send with the function calls
    /// @param calldatas An array of bytes defining the function calls
    function execute(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata calldatas
    ) external;
}