// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';

contract WQBridgePool is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address payable;

    bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');
    bytes32 public constant UPGRADER_ROLE = keccak256('UPGRADER_ROLE');
    bytes32 public constant BRIDGE_ROLE = keccak256('BRIDGE_ROLE');

    bool private initialized;

    mapping(address => bool) public isBlockListed;

    event AddedBlockList(address user);
    event RemovedBlockList(address user);
    event Transferred(address token, address recipient, uint256 amount);
    event TransferredNative(address sender, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    // constructor() initializer {}

    function initialize() external initializer {
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setRoleAdmin(UPGRADER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(BRIDGE_ROLE, ADMIN_ROLE);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function transfer(
        address payable recipient,
        uint256 amount, 
        address token
    ) external onlyRole(BRIDGE_ROLE) whenNotPaused {
        require(isBlockListed[recipient] == false, 'WQBridgePool: Recipient address is blocklisted');
        if (token != address(0)) {
            IERC20Upgradeable(token).safeTransfer(recipient, amount);
        } else {
            recipient.sendValue(amount);
        }
        emit Transferred(token, recipient, amount);
    }

    receive() external payable {
        emit TransferredNative(msg.sender, msg.value);
    }

    function removeLiquidity(
        address payable recipient,
        uint256 amount,
        address token
    ) external onlyRole(ADMIN_ROLE) {
        require(recipient != payable(0), 'WQBridge: invalid recipient address');
        if (token != address(0)) {
            IERC20Upgradeable(token).safeTransfer(recipient, amount);
        } else {
            recipient.sendValue(amount);
        }
        emit Transferred(token, recipient, amount);
    }

    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Add user address to blocklist
     *
     * Requirements
     *
     * - `user` address of user.
     */
    function addBlockList(address user) external onlyRole(ADMIN_ROLE) {
        isBlockListed[user] = true;
        emit AddedBlockList(user);
    }

    /**
     * @notice Remove user address from blocklist
     * @param user address of user.
     */
    function removeBlockList(address user) external onlyRole(ADMIN_ROLE) {
        isBlockListed[user] = false;
        emit RemovedBlockList(user);
    }
}