// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "./interfaces/external/IYakStrategy.sol";
import "./interfaces/IYakStrategyController.sol";

import "../BaseVaultController.sol";

/// @title YieldYak Strategy controller
/// @notice Contains logic for depositing into the YieldYak Protocol
contract YakStrategyController is IYakStrategyController, BaseVaultController {
    /// @inheritdoc IYakStrategyController
    address public override strategy;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @inheritdoc IYakStrategyController
    function initialize(
        address _vToken,
        address _strategy,
        uint16 _targetDepositPercentageInBP,
        uint16 _percentageInBPPerStep,
        uint32 _stepDuration
    ) external override initializer {
        require(IYakStrategy(_strategy).depositToken() == IvToken(_vToken).asset(), "Controller: INVALID");

        __BaseVaultController_init(_vToken, _targetDepositPercentageInBP, _percentageInBPPerStep, _stepDuration);

        strategy = _strategy;
    }

    /// @inheritdoc IVaultController
    function expectedWithdrawableAmount() external view override returns (uint) {
        return IYakStrategy(strategy).getDepositTokensForShares(IERC20(strategy).balanceOf(address(this)));
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IYakStrategyController).interfaceId || super.supportsInterface(_interfaceId);
    }

    /// @notice Deposits assets
    /// @param _amount Deposit amount
    function _deposit(uint _amount) internal override {
        if (_amount != 0) {
            IERC20(IvToken(vToken).asset()).approve(strategy, _amount);
            IYakStrategy(strategy).deposit(_amount);
        }
    }

    /// @notice Withdraws deposited assets
    function _withdraw() internal override {
        uint amount = IERC20(strategy).balanceOf(address(this));
        if (amount != 0) {
            IERC20(strategy).approve(strategy, amount);
            IYakStrategy(strategy).withdraw(amount);
        }
    }

    uint256[49] private __gap;
}