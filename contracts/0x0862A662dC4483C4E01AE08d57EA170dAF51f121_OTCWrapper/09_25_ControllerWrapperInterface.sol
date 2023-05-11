// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {UtilsWrapperInterface} from "./UtilsWrapperInterface.sol";

interface ControllerWrapperInterface {
    /* Getters */
    function getAccountVaultCounter(address _accountOwner) external view returns (uint256);

    function getVaultWithDetails(address _owner, uint256 _vaultId)
        external
        view
        returns (
            UtilsWrapperInterface.Vault memory,
            uint256,
            uint256
        );

    /* Admin-only functions */
    function operate(UtilsWrapperInterface.ActionArgs[] memory _actions) external;
}