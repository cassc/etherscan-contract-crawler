// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.8;

import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title ConsensusVault responsible for managing initial capital and reward
 */
contract ConsensusVault is Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    address public liquidStakingContractAddress;
    address public dao;

    event DaoAddressChanged(address _oldDao, address _dao);
    event LiquidStakingChanged(address _from, address _to);
    event Transferred(address _to, uint256 _amount);

    modifier onlyLiquidStaking() {
        require(liquidStakingContractAddress == msg.sender, "Not allowed to touch funds");
        _;
    }

    modifier onlyDao() {
        require(msg.sender == dao, "PERMISSION_DENIED");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {}

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
        require(_to != address(0), "Recipient address invalid");
        payable(_to).transfer(_amount);
        emit Transferred(_to, _amount);
    }

    /**
     * @notice Set proxy address of LiquidStaking
     * @param _liquidStakingContractAddress proxy address of LiquidStaking
     * @dev will only allow call of function by the address registered as the owner
     */
    function setLiquidStaking(address _liquidStakingContractAddress) external onlyOwner {
        require(_liquidStakingContractAddress != address(0), "LiquidStaking address invalid");
        emit LiquidStakingChanged(liquidStakingContractAddress, _liquidStakingContractAddress);
        liquidStakingContractAddress = _liquidStakingContractAddress;
    }

    /**
     * @notice set dao address
     * @param _dao new dao address
     */
    function setDaoAddress(address _dao) external onlyOwner {
        require(_dao != address(0), "Dao address invalid");
        emit DaoAddressChanged(dao, _dao);
        dao = _dao;
    }

    receive() external payable {}
}