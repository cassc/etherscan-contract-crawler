// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.8;

import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "src/interfaces/ILiquidStaking.sol";

/**
 * @title ConsensusVault responsible for managing initial capital and reward
 */
contract ConsensusVault is Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    address public liquidStakingContractAddress;
    address public dao;

    event DaoAddressChanged(address _oldDao, address _dao);
    event LiquidStakingChanged(address _from, address _to);
    event Transferred(address _to, uint256 _amount);
    event RewardReinvestment(address _liquidStakingContract, uint256 _rewards);

    error PermissionDenied();
    error InvalidAddr();

    modifier onlyLiquidStaking() {
        if (liquidStakingContractAddress != msg.sender) revert PermissionDenied();
        _;
    }

    modifier onlyDao() {
        if (msg.sender != dao) revert PermissionDenied();
        _;
    }

    /**
     * @notice Initializes the NodeCapitalVault contract by setting the required external contracts ,
     * ReentrancyGuardUpgradeable, OwnableUpgradeable, UUPSUpgradeable and `_aggregatorProxyAddress`
     * @dev initializer - A modifier that defines a protected initializer function that can be invoked at most once
     * @param _dao dao address
     * @param _liquidStakingProxyAddress liquidStaking Address
     */
    function initialize(address _dao, address _liquidStakingProxyAddress) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        dao = _dao;
        liquidStakingContractAddress = _liquidStakingProxyAddress;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @notice transfer ETH
     * @param _amount transfer amount
     * @param _to transfer to address
     */
    function transfer(uint256 _amount, address _to) external nonReentrant onlyLiquidStaking {
        if (_to == address(0)) revert InvalidAddr();
        payable(_to).transfer(_amount);
        emit Transferred(_to, _amount);
    }

    /**
     * @notice transfer ETH
     * @param _amount transfer amount
     */
    function reinvestment(uint256 _amount) external nonReentrant onlyLiquidStaking {
        ILiquidStaking(liquidStakingContractAddress).receiveRewards{value: _amount}(_amount);
        emit RewardReinvestment(liquidStakingContractAddress, _amount);
    }

    /**
     * @notice Set proxy address of LiquidStaking
     * @param _liquidStakingContractAddress proxy address of LiquidStaking
     * @dev will only allow call of function by the address registered as the owner
     */
    function setLiquidStaking(address _liquidStakingContractAddress) external onlyOwner {
        if (_liquidStakingContractAddress == address(0)) revert InvalidAddr();
        emit LiquidStakingChanged(liquidStakingContractAddress, _liquidStakingContractAddress);
        liquidStakingContractAddress = _liquidStakingContractAddress;
    }

    /**
     * @notice set dao address
     * @param _dao new dao address
     */
    function setDaoAddress(address _dao) external onlyOwner {
        if (_dao == address(0)) revert InvalidAddr();
        emit DaoAddressChanged(dao, _dao);
        dao = _dao;
    }

    receive() external payable {}
}