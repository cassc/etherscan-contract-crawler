// SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./BaseStaking.sol";
import "../lib/StakingUtils.sol";

contract TaxedStaking is BaseStaking {
    using SafeERC20 for IERC20;

    StakingUtils.TaxConfiguration public taxConfiguration;

    function __TaxedStaking_init(
        StakingUtils.StakingConfiguration memory config,
        StakingUtils.TaxConfiguration memory taxConfig
    ) public onlyInitializing {
        __BaseStaking_init(config);
        __TaxedStaking_init_unchained(taxConfig);
    }

    function __TaxedStaking_init_unchained(StakingUtils.TaxConfiguration memory taxConfig) public onlyInitializing {
        taxConfiguration = taxConfig;
    }

    function setTaxAddresses(address _ownerTaxAddress, address _hpayTaxAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        taxConfiguration.feeAddress = _ownerTaxAddress;
        taxConfiguration.hpayFeeAddress = _hpayTaxAddress;
    }

    function setHpayAddress(address _hpay) external onlyRole(DEFAULT_ADMIN_ROLE) {
        taxConfiguration.hpayToken = ERC20(_hpay);
    }

    function _stake(uint256 _amount) internal virtual override {
        uint256 amountWithoutTax = takeStakeTax(_amount);
        BaseStaking._stake(amountWithoutTax);
    }

    function _withdraw(uint256 _amount) internal virtual override {
        uint256 amountWithoutTax = takeUnstakeTax(_amount);
        BaseStaking._withdraw(amountWithoutTax);
    }

    function takeUnstakeTax(uint256 _amount) internal virtual returns (uint256) {
        if (taxConfiguration.hpayFee > 0 && taxConfiguration.hpayToken.balanceOf(msg.sender) < 1e18) {
            uint256 _hpayFee = (_amount * taxConfiguration.hpayFee) / 10_000;
            _balances[msg.sender] -= _hpayFee;
            _totalSupply -= _hpayFee;
            IERC20(configuration.stakingToken).safeTransfer(taxConfiguration.feeAddress, _hpayFee);
            _amount -= _hpayFee;
        }

        if (taxConfiguration.unStakeTax > 0) {
            uint256 fee = (_amount * taxConfiguration.unStakeTax) / 10_000;
            _balances[msg.sender] -= fee;
            _totalSupply -= fee;
            IERC20(configuration.stakingToken).safeTransfer(taxConfiguration.feeAddress, fee);
            _amount -= fee;
        }
        return _amount;
    }

    function takeStakeTax(uint256 _amount) internal virtual returns (uint256) {
        if (taxConfiguration.hpayFee > 0 && taxConfiguration.hpayToken.balanceOf(msg.sender) < 1e18) {
            uint256 _hpayFee = (_amount * taxConfiguration.hpayFee) / 10_000;
            IERC20(configuration.stakingToken).safeTransferFrom(msg.sender, taxConfiguration.hpayFeeAddress, _hpayFee);
            _amount -= _hpayFee;
        }

        if (taxConfiguration.stakeTax > 0) {
            uint256 fee = (_amount * taxConfiguration.stakeTax) / 10_000;
            IERC20(configuration.stakingToken).safeTransferFrom(msg.sender, taxConfiguration.feeAddress, fee);
            _amount -= fee;
        }
        return _amount;
    }

    function setTax(uint256 stakeTax, uint256 unstakeTax) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(stakeTax <= 10_000 && unstakeTax < 10_000, "Tax cannot be greater than 100%");
        taxConfiguration.stakeTax = stakeTax;
        taxConfiguration.unStakeTax = unstakeTax;
    }

    function setHpayTax(uint256 tax) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(tax <= 10_000, "Tax cannot be greater than 100%");
        taxConfiguration.hpayFee = tax;
    }

    uint256[49] private __gap;
}