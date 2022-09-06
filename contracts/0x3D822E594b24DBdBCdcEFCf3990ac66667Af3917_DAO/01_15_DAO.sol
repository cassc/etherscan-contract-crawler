//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/IDAO.sol";
import "./ModuleBase.sol";

/// @notice A minimum viable DAO contract
contract DAO is IDAO, ModuleBase {
    /// @notice Function for initializing the contract that can only be called once
    /// @param _accessControl The address of the access control contract
    /// @param _moduleFactoryBase The address of the module factory
    /// @param _name Name of the Dao
    function initialize(address _accessControl, address _moduleFactoryBase, string calldata _name) external initializer {
        __initBase(_accessControl, _moduleFactoryBase, _name);
    }

    /// @notice A function for executing function calls from the DAO
    /// @param targets An array of addresses to target for the function calls
    /// @param values An array of ether values to send with the function calls
    /// @param calldatas An array of bytes defining the function calls
    function execute(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata calldatas
    ) external authorized {
        if (
            targets.length != values.length ||
            targets.length != calldatas.length
        ) revert UnequalArrayLengths();
        string memory errorMessage = "DAO: call reverted without message";
        uint256 targetlength = targets.length;
        for (uint256 i = 0; i < targetlength; ) {
            (bool success, bytes memory returndata) = targets[i].call{
                value: values[i]
            }(calldatas[i]);
            Address.verifyCallResult(success, returndata, errorMessage);
            unchecked {
                i++;
            }
        }
        emit Executed(targets, values, calldatas);
    }

    /// @notice Returns whether a given interface ID is supported
    /// @param interfaceId An interface ID bytes4 as defined by ERC-165
    /// @return bool Indicates whether the interface is supported
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceId == type(IDAO).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}