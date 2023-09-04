// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.8;

import "openzeppelin-contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title ELReward for managing rewards
 */
contract ELReward is ReentrancyGuard, Initializable {
    address public manager;
    address public dao;
    uint256 public operatorId;

    event DaoAddressChanged(address _oldDao, address _dao);
    event ManagerAddressChanged(address _oldManager, address _manager);
    event Transferred(address _to, uint256 _amount);

    error PermissionDenied();
    error InvalidAddr();

    modifier onlyManager() {
        if (manager != msg.sender) revert PermissionDenied();
        _;
    }

    modifier onlyDao() {
        if (msg.sender != dao) revert PermissionDenied();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {}

    /**
     * @notice Initializes the NodeCapitalVault contract by setting the required external contracts ,
     * ReentrancyGuardUpgradeable, OwnableUpgradeable, UUPSUpgradeable and `_aggregatorProxyAddress`
     * @dev initializer - A modifier that defines a protected initializer function that can be invoked at most once
     * @param _dao dao address
     * @param _manager manager Address
     * @param _operatorId operator Id
     */
    function initialize(address _dao, address _manager, uint256 _operatorId) public initializer {
        dao = _dao;
        manager = _manager;
        operatorId = _operatorId;
    }

    /**
     * @notice transfer ETH
     * @param _amount transfer amount
     * @param _to transfer to address
     */
    function transfer(uint256 _amount, address _to) external nonReentrant onlyManager {
        if (_to == address(0)) revert InvalidAddr();

        payable(_to).transfer(_amount);
        emit Transferred(_to, _amount);
    }

    /**
     * @notice Set proxy address of LiquidStaking
     * @param _manager manager address
     * @dev will only allow call of function by the address registered as the owner
     */
    function setManager(address _manager) external onlyDao {
        if (_manager == address(0)) revert InvalidAddr();
        emit ManagerAddressChanged(manager, _manager);
        manager = _manager;
    }

    /**
     * @notice set dao address
     * @param _dao new dao address
     */
    function setDaoAddress(address _dao) external onlyDao {
        if (_dao == address(0)) revert InvalidAddr();
        emit DaoAddressChanged(dao, _dao);
        dao = _dao;
    }

    receive() external payable {}
}