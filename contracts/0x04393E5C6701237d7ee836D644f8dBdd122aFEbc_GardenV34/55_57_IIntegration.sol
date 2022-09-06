// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

/**
 * @title IIntegration
 * @author Babylon Finance
 *
 * Interface for protocol integrations
 */
interface IIntegration {
    function getName() external view returns (string memory);
}