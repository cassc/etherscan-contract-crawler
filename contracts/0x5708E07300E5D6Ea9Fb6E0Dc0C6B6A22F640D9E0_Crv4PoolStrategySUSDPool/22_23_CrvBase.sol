// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../dependencies/openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../dependencies/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../dependencies/openzeppelin/contracts/utils/math/SafeCast.sol";
import "../../interfaces/curve/IStableSwap.sol";
import "../../interfaces/curve/ILiquidityGauge.sol";
import "../../interfaces/curve/ITokenMinter.sol";
import "../../interfaces/curve/IMetapoolFactory.sol";
import "../../interfaces/curve/IDepositZap.sol";

abstract contract CrvBase {
    using SafeERC20 for IERC20;

    address public constant CRV_MINTER = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;

    // solhint-disable-next-line  var-name-mixedcase
    address public CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    IStableSwapUnderlying public immutable crvPool;
    address public immutable crvLp;
    address public immutable crvGauge;

    constructor(
        address _pool,
        address _lp,
        address _gauge
    ) {
        require(_pool != address(0x0), "CRVMgr: invalid curve pool");
        require(_lp != address(0x0), "CRVMgr: invalid lp token");
        require(_gauge != address(0x0), "CRVMgr: invalid gauge");

        crvPool = IStableSwapUnderlying(_pool);
        crvLp = _lp;
        crvGauge = _gauge;
    }

    function _minimumLpPrice(uint256 _safeRate) internal view returns (uint256) {
        return ((crvPool.get_virtual_price() * _safeRate) / 1e18);
    }

    function _withdrawAsFromCrvPool(
        uint256 _lpAmount,
        uint256 _minAmt,
        uint256 i
    ) internal virtual {
        crvPool.remove_liquidity_one_coin(_lpAmount, SafeCast.toInt128(int256(i)), _minAmt);
    }

    function _withdrawAllAs(uint256 i) internal virtual {
        uint256 lpAmt = IERC20(crvLp).balanceOf(address(this));
        if (lpAmt != 0) {
            crvPool.remove_liquidity_one_coin(lpAmt, SafeCast.toInt128(int256(i)), 0);
        }
    }

    function calcWithdrawLpAs(uint256 _amtNeeded, uint256 i)
        public
        view
        returns (uint256 lpToWithdraw, uint256 unstakeAmt)
    {
        uint256 lp = getLp();
        uint256 tlp = totalLp();
        lpToWithdraw = (_amtNeeded * tlp) / getLpValueAs(tlp, i);
        lpToWithdraw = (lpToWithdraw > tlp) ? tlp : lpToWithdraw;
        if (lpToWithdraw > lp) {
            unstakeAmt = lpToWithdraw - lp;
        }
    }

    function getLpValueAs(uint256 _lpAmount, uint256 i) public view virtual returns (uint256) {
        return (_lpAmount != 0) ? crvPool.calc_withdraw_one_coin(_lpAmount, SafeCast.toInt128(int256(i))) : 0;
    }

    // While this is inaccurate in terms of slippage, this gives us the
    // best estimate (least manipulatable value) to calculate share price
    function getLpValue(uint256 _lpAmount) public view virtual returns (uint256) {
        return (_lpAmount != 0) ? (crvPool.get_virtual_price() * _lpAmount) / 1e18 : 0;
    }

    function setCheckpoint() external {
        _setCheckpoint();
    }

    // requires that gauge has approval for lp token
    function _stakeAllLp() internal virtual {
        uint256 balance = IERC20(crvLp).balanceOf(address(this));
        if (balance != 0) {
            ILiquidityGaugeV2(crvGauge).deposit(balance);
        }
    }

    function _unstakeAllLp() internal virtual {
        _unstakeLp(IERC20(crvGauge).balanceOf(address(this)));
    }

    function _unstakeLp(uint256 _amount) internal virtual {
        if (_amount != 0) {
            ILiquidityGaugeV2(crvGauge).withdraw(_amount);
        }
    }

    function _claimRewards() internal virtual {
        ITokenMinter(CRV_MINTER).mint(crvGauge);
    }

    function _setCheckpoint() internal virtual {
        ILiquidityGaugeV2(crvGauge).user_checkpoint(address(this));
    }

    function totalStaked() public view virtual returns (uint256 total) {
        total = IERC20(crvGauge).balanceOf(address(this));
    }

    function totalLp() public view virtual returns (uint256 total) {
        total = getLp() + IERC20(crvGauge).balanceOf(address(this));
    }

    // Gets LP value not staked in gauge
    function getLp() public view virtual returns (uint256 total) {
        total = IERC20(crvLp).balanceOf(address(this));
    }
}