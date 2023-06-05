// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Strategy.sol";

/// @title This strategy will hold collateral and payback excessDebt via rebalance.
contract EulerDummyStrategy is Strategy {
    using SafeERC20 for IERC20;

    // solhint-disable-next-line var-name-mixedcase
    string public NAME;
    string public constant VERSION = "5.1.0";

    constructor(
        address _pool,
        address _swapManager,
        address _receiptToken,
        string memory _name
    ) Strategy(_pool, _swapManager, _receiptToken) {
        NAME = _name;
    }

    function tvl() public view virtual override returns (uint256) {
        return collateralToken.balanceOf(address(this));
    }

    // Allow any token to be withdrawn
    function isReservedToken(address /*_token*/) public pure override returns (bool) {
        return false;
    }

    function _approveToken(uint256 _amount) internal virtual override {
        super._approveToken(_amount);
    }

    function _beforeMigration(address _newStrategy) internal override {}

    function _rebalance() internal virtual override returns (uint256 _profit, uint256 _loss, uint256 _payback) {
        // Safe to assume that strategy debtRatio will be set to 0 and we will be paying excessDebt.
        uint256 _excessDebt = IVesperPool(pool).excessDebt(address(this));
        uint256 _collateralHere = collateralToken.balanceOf(address(this));

        _payback = Math.min(_collateralHere, _excessDebt);
        IVesperPool(pool).reportEarning(0, 0, _payback);
        return (0, 0, _payback);
    }

    // This strategy will not withdraw collateral when pool.withdraw() is called.
    function _withdrawHere(uint256 _amount) internal override {}
}