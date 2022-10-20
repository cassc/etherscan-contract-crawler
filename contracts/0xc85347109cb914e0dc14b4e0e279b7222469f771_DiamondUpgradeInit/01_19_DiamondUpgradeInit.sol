pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./facets/Mailbox.sol";
import "./libraries/Diamond.sol";
import "../common/L2ContractHelper.sol";

/// @author Matter Labs
contract DiamondUpgradeInit is MailboxFacet {
    /// @dev Request priority operation on behalf of force deployer address to the deployer system contract
    /// @return The message indicating the successful force deployment of contract on L2
    function forceDeployL2Contract(
        bytes calldata _forceDeployCalldata,
        bytes[] calldata _factoryDeps,
        uint256 _ergsLimit
    ) external payable returns (bytes32) {
        _requestL2Transaction(
            FORCE_DEPLOYER,
            DEPLOYER_SYSTEM_CONTRACT_ADDRESS,
            0,
            _forceDeployCalldata,
            _ergsLimit,
            _factoryDeps
        );

        return Diamond.DIAMOND_INIT_SUCCESS_RETURN_VALUE;
    }
}