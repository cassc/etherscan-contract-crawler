// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./VaultStakingMock.sol";
import "../BaseVaultController.sol";

contract VaultControllerMock is BaseVaultController {
    address public staking;

    function initialize(
        address _vToken,
        address _staking,
        uint16 _targetDepositPercentageInBP,
        uint16 _percentageInBPPerStep,
        uint32 _stepDuration
    ) external initializer {
        __BaseVaultController_init(_vToken, _targetDepositPercentageInBP, _percentageInBPPerStep, _stepDuration);

        staking = _staking;
    }

    function _deposit(uint amount) internal override {
        IERC20(IVaultStakingMock(staking).asset()).approve(staking, amount);
        IVaultStakingMock(staking).stake(amount);
    }

    function _withdraw() internal override {
        IVaultStakingMock(staking).withdraw();
    }

    function expectedWithdrawableAmount() external view virtual override returns (uint) {
        return VaultStakingMock(staking).withdrawable();
    }
}