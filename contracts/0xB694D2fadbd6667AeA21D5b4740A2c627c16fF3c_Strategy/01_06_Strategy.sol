// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/math/Math.sol";

import {IERC20, BaseStrategy} from "BaseStrategy.sol";
import "interfaces/IVault.sol";
import {Comet, CometStructs, CometRewards} from "interfaces/CompoundV3.sol";

contract Strategy is BaseStrategy {
    // TODO: add rewards
    Comet public immutable cToken;
    uint256 private SECONDS_PER_YEAR = 365 days;

    constructor(
        address _vault,
        string memory _name,
        Comet _cToken
    ) BaseStrategy(_vault, _name) {
        cToken = _cToken;
        require(cToken.baseToken() == IVault(vault).asset());
    }

    function _maxWithdraw(
        address owner
    ) internal view override returns (uint256) {
        // TODO: may not be accurate due to unaccrued balance in cToken
        return
            Math.min(IERC20(asset).balanceOf(address(cToken)), _totalAssets());
    }

    function _freeFunds(
        uint256 _amount
    ) internal returns (uint256 _amountFreed) {
        uint256 _idleAmount = balanceOfAsset();
        if (_amount <= _idleAmount) {
            // we have enough idle assets for the vault to take
            _amountFreed = _amount;
        } else {
            // NOTE: we need the balance updated
            cToken.accrueAccount(address(this));
            // We need to take from Aave enough to reach _amount
            // Balance of
            // We run with 'unchecked' as we are safe from underflow
            unchecked {
                _withdrawFromComet(
                    Math.min(_amount - _idleAmount, balanceOfCToken())
                );
            }
            _amountFreed = balanceOfAsset();
        }
    }

    function _withdraw(
        uint256 amount,
        address receiver,
        address owner
    ) internal override returns (uint256) {
        return _freeFunds(amount);
    }

    function _totalAssets() internal view override returns (uint256) {
        return balanceOfAsset() + balanceOfCToken();
    }

    function _invest() internal override {
        uint256 _availableToInvest = balanceOfAsset();
        _depositToComet(_availableToInvest);
    }

    function _withdrawFromComet(uint256 _amount) internal {
        cToken.withdraw(address(asset), _amount);
    }

    function _depositToComet(uint256 _amount) internal {
        Comet _cToken = cToken;
        _checkAllowance(address(_cToken), asset, _amount);
        _cToken.supply(address(asset), _amount);
    }

    function _checkAllowance(
        address _contract,
        address _token,
        uint256 _amount
    ) internal {
        if (IERC20(_token).allowance(address(this), _contract) < _amount) {
            IERC20(_token).approve(_contract, 0);
            IERC20(_token).approve(_contract, _amount);
        }
    }

    function balanceOfCToken() internal view returns (uint256) {
        return IERC20(cToken).balanceOf(address(this));
    }

    function balanceOfAsset() internal view returns (uint256) {
        return IERC20(asset).balanceOf(address(this));
    }

    function aprAfterDebtChange(int256 delta) external view returns (uint256) {
        uint256 borrows = cToken.totalBorrow();
        uint256 supply = cToken.totalSupply();

        uint256 newUtilization = (borrows * 1e18) /
            uint256(int256(supply) + delta);
        uint256 newSupplyRate = cToken.getSupplyRate(newUtilization) *
            SECONDS_PER_YEAR;
        return newSupplyRate;
    }
}