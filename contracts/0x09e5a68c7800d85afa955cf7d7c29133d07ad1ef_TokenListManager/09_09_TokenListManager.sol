//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/ITokenListManager.sol";

/**
 * @title TokenListManager contract
 * @author Swarm
 */
contract TokenListManager is AccessControl, ITokenListManager {
    /**
     * @dev Emitted when `erc20Asset` is registered.
     */
    event RegisterERC20Token(address indexed token);

    /**
     * @dev Emitted when `erc1155Asset` is registered.
     */
    event RegisterERC1155Token(address indexed token);

    /**
     * @dev Emitted when `erc1155Asset` is unRegistered.
     */
    event unRegisterERC1155(address indexed token);

    /**
     * @dev Emitted when `erc20Asset` is unRegistered.
     */
    event unRegisterERC20(address indexed token);

    /**
     * @dev TOKEN_MANAGER_ROLE for operating this contract
     */
    bytes32 public constant TOKEN_MANAGER_ROLE = keccak256("TOKEN_MANAGER_ROLE");

    /**
     * @dev ERC20 Tokens registry.
     */
    mapping(address => uint256) public allowedErc20tokens;

    /**
     * @dev ERC1155 Tokens registry.
     */
    mapping(address => uint256) public allowedErc1155tokens;

    uint256 private _erc20Id;
    uint256 private _erc1155Id;

    /**
     * @dev Check if sender has admin role
     */
    modifier onlyAdmin() {
        require(hasRole(TOKEN_MANAGER_ROLE, _msgSender()), "TokenListManager: Account must have TOKEN_MANAGER_ROLE");
        _;
    }

    /**
     * @dev Check if `_address` is not address(0)
     */
    modifier addressNotZero(address _address) {
        require(_address != address(0), "TokenListManager: Address == zero address");
        _;
    }

    /**
     * @dev Grants the contract deployer the default admin role.
     *
     */
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TOKEN_MANAGER_ROLE, msg.sender);
    }

    /**
     * @dev Grants TOKEN_MANAGER_ROLE to `_manager`.
     *
     * Requirements:
     * - the caller must have ``role``'s admin role.
     *
     * @param _manager address
     */
    function setRegistryManager(address _manager) external addressNotZero(_manager) {
        grantRole(TOKEN_MANAGER_ROLE, _manager);
    }

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
    function registerERC20Token(address _token) external onlyAdmin addressNotZero(_token) {
        emit RegisterERC20Token(_token);

        _erc20Id++;

        allowedErc20tokens[_token] = _erc20Id;
    }

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
    function registerERC1155Token(address _token) external onlyAdmin addressNotZero(_token) {
        emit RegisterERC1155Token(_token);

        _erc1155Id++;

        allowedErc1155tokens[_token] = _erc1155Id;
    }

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
    function unRegisterERC20Token(address _token) external onlyAdmin addressNotZero(_token) {
        emit unRegisterERC20(_token);

        delete allowedErc20tokens[_token];
    }

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
    function unRegisterERC1155Token(address _token) external onlyAdmin addressNotZero(_token) {
        emit unRegisterERC1155(_token);

        delete allowedErc1155tokens[_token];
    }
}