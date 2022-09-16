// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "./interfaces/external/IYearnVault.sol";
import "./interfaces/IYearnVaultVTokenController.sol";

import "./BaseVaultController.sol";

/// @title Yearn vault controller
/// @notice Contains logic for depositing into into the Yearn Protocol
contract YearnVaultVTokenController is IYearnVaultVTokenController, BaseVaultController {
    /// @inheritdoc IYearnVaultVTokenController
    address public override vault;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @inheritdoc IYearnVaultVTokenController
    function initialize(
        address _vToken,
        address _vault,
        uint16 _targetDepositPercentageInBP,
        uint16 _percentageInBPPerStep,
        uint32 _stepDuration
    ) external override initializer {
        require(IYearnVault(_vault).token() == IvToken(_vToken).asset(), "Controller: INVALID");

        __BaseVaultController_init(_vToken, _targetDepositPercentageInBP, _percentageInBPPerStep, _stepDuration);

        vault = _vault;
    }

    /// @inheritdoc IVaultController
    function expectedWithdrawableAmount() external view override returns (uint) {
        if (IERC20(vault).totalSupply() == 0) {
            return 0;
        }

        uint shares = IERC20(vault).balanceOf(address(this));
        return (IYearnVault(vault).pricePerShare() * shares) / 10**IYearnVault(vault).decimals();
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IYearnVaultVTokenController).interfaceId || super.supportsInterface(_interfaceId);
    }

    /// @notice Deposits assets
    /// @param _amount Deposit amount
    function _deposit(uint _amount) internal override {
        if (_amount != 0) {
            IERC20(IvToken(vToken).asset()).approve(vault, _amount);
            IYearnVault(vault).deposit(_amount);
        }
    }

    /// @notice Withdraws deposited assets
    function _withdraw() internal override {
        uint amount = IERC20(vault).balanceOf(address(this));
        if (amount != 0) {
            IERC20(vault).approve(vault, amount);
            IYearnVault(vault).withdraw(amount);
        }
    }

    uint256[49] private __gap;
}