// solhint-disable
//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @title Interface for TokenListManager
 * @author Swarm
 */
interface ITokenListManager is IAccessControl {
    /**
     * @dev ERC20 Tokens registry.
     */
    function allowedErc20tokens(address token) external view returns (uint256);

    /**
     * @dev ERC1155 Tokens registry.
     */
    function allowedErc1155tokens(address token) external view returns (uint256);

    /**
     * @dev Hash of the TOKEN_MANAGER_ROLE role
     */
    function TOKEN_MANAGER_ROLE() external view returns (bytes32);

    /**
     * @dev Grants TOKEN_MANAGER_ROLE to `_manager`.
     *
     * Requirements:
     * - the caller must have ``role``'s admin role.
     *
     * @param _manager address
     */
    function setRegistryManager(address _manager) external;

    /**
     * @dev Registers a new ERC20 to be allowed into DOTCProtocol.
     *
     * Requirements:
     *
     * - the caller must have TOKEN_MANAGER_ROLE.
     * - `_token` cannot be the zero address.
     *
     * @param _token The address of the ERC20 being registered.
     */
    function registerERC20Token(address _token) external;

    /**
     * @dev Registers a new ERC1155 to be allowed into DOTCProtocol.
     *
     * Requirements:
     *
     * - the caller must have TOKEN_MANAGER_ROLE.
     * - `_token` cannot be the zero address.
     *
     * @param _token The address of the ERC20 being registered.
     */
    function registerERC1155Token(address _token) external;

    /**
     * @dev Unregisters a new ERC20 allowed into DOTCProtocol.
     *
     * Requirements:
     *
     * - the caller must have TOKEN_MANAGER_ROLE.
     * - `_token` cannot be the zero address.
     *
     * @param _token The address of the ERC20 being registered.
     */
    function unRegisterERC20Token(address _token) external;

    /**
     * @dev Unregisters a new ERC1155 allowed into DOTCProtocol.
     *
     * Requirements:
     *
     * - the caller must have TOKEN_MANAGER_ROLE.
     * - `_token` cannot be the zero address.
     *
     * @param _token The address of the ERC20 being registered.
     */
    function unRegisterERC1155Token(address _token) external;
}