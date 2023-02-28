// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../interface/IBnbY.sol";
contract BnbY is IBnbY, ERC20Upgradeable, AccessControlUpgradeable {
    address private stakeManager;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _admin) external override initializer {
        __AccessControl_init();
        __ERC20_init("Liquid Staking BNB", "BNBy");

        require(_admin != address(0), "zero address provided");

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function mint(address _account, uint256 _amount)
        external
        override
        onlyStakeManager
    {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount)
        external
        override
        onlyStakeManager
    {
        _burn(_account, _amount);
    }

    function setStakeManager(address _address)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(stakeManager != _address, "Old address == new address");
        require(_address != address(0), "zero address provided");

        stakeManager = _address;

        emit SetStakeManager(_address);
    }

    modifier onlyStakeManager() {
        require(
            msg.sender == stakeManager,
            "Accessible only by StakeManager Contract"
        );
        _;
    }
}