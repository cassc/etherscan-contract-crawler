//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libraries/math/SafeMath.sol";
import "./uniswap/UniswapV2Library.sol";
import "./libraries/token/IERC20.sol";
import "./interfaces/ILGEToken.sol";
import "./interfaces/IFloor.sol";

contract Reader {
    using SafeMath for uint256;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    address public immutable factory;
    address public immutable xvix;
    address public immutable dai;
    address public immutable lgeTokenWETH;
    address public immutable distributor;
    address public immutable floor;

    constructor(
        address _factory,
        address _xvix,
        address _dai,
        address _lgeTokenWETH,
        address _distributor,
        address _floor
    ) public {
        factory = _factory;
        xvix = _xvix;
        dai = _dai;
        lgeTokenWETH = _lgeTokenWETH;
        distributor = _distributor;
        floor = _floor;
    }

    function getPoolAmounts(
        address _account,
        address _token0,
        address _token1
    ) external view returns (uint256, uint256, uint256, uint256, uint256) {
        address pair = UniswapV2Library.pairFor(factory, _token0, _token1);
        uint256 supply = IERC20(pair).totalSupply();
        if (supply == 0) { return (0, 0, 0, 0, 0); }
        uint256 accountBalance = IERC20(pair).balanceOf(_account);
        uint256 balance0 = IERC20(_token0).balanceOf(pair);
        uint256 balance1 = IERC20(_token1).balanceOf(pair);
        uint256 pool0 = balance0.mul(accountBalance).div(supply);
        uint256 pool1 = balance1.mul(accountBalance).div(supply);
        return (pool0, pool1, balance0, balance1, supply);
    }

    function getLGEAmounts(address _account) public view returns (uint256, uint256, uint256, uint256) {
        uint256 accountBalance = IERC20(lgeTokenWETH).balanceOf(_account);
        uint256 supply = IERC20(lgeTokenWETH).totalSupply();
        if (supply == 0) { return (0, 0, 0, 0); }

        return (
            accountBalance,
            distributor.balance.mul(accountBalance).div(supply),
            IERC20(dai).balanceOf(distributor).mul(accountBalance).div(supply),
            IERC20(xvix).balanceOf(distributor).mul(accountBalance).div(supply)
        );
    }

    function getLPAmounts(address _account, address _lgeToken) public view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 supply = IERC20(_lgeToken).totalSupply();
        if (supply == 0) { return (0, 0, 0, 0, 0); }

        uint256 amountLGEToken = IERC20(_lgeToken).balanceOf(_account);
        address pair = UniswapV2Library.pairFor(factory, xvix, ILGEToken(_lgeToken).token());
        uint256 amountToken = getLPAmount(_account, pair, _lgeToken, ILGEToken(_lgeToken).token());
        uint256 amountXVIX = getLPAmount(_account, pair, _lgeToken, xvix);
        uint256 refundBasisPoints = getRefundBasisPoints(_lgeToken, amountLGEToken, amountToken);

        return (
            amountLGEToken,
            amountToken,
            amountXVIX,
            refundBasisPoints,
            IFloor(floor).getRefundAmount(amountXVIX)
        );
    }

    function getLPAmount(address _account, address _pair, address _lgeToken, address _token) public view returns (uint256) {
        if (IERC20(_pair).totalSupply() == 0) { return 0; }
        uint256 amountLGEToken = IERC20(_lgeToken).balanceOf(_account);
        uint256 totalTokenBalance = IERC20(_token).balanceOf(_pair);
        uint256 distributorTokenBalance = totalTokenBalance
            .mul(IERC20(_pair).balanceOf(distributor))
            .div(IERC20(_pair).totalSupply());

        return distributorTokenBalance
            .mul(amountLGEToken)
            .div(IERC20(_lgeToken).totalSupply());
    }

    function getRefundBasisPoints(address _lgeToken, uint256 _amountLGEToken, uint256 _amountToken) public view returns (uint256) {
        uint256 refBalance = ILGEToken(_lgeToken).refBalance();
        uint256 refSupply = ILGEToken(_lgeToken).refSupply();
        uint256 refAmount = _amountLGEToken.mul(refBalance).div(refSupply);
        uint256 minExpectedAmount = refAmount.mul(2);

        if (_amountToken >= minExpectedAmount) { return 0; }

        uint256 diff = minExpectedAmount.sub(_amountToken);
        uint256 refundBasisPoints = diff.mul(BASIS_POINTS_DIVISOR).div(refAmount);

        if (refundBasisPoints >= BASIS_POINTS_DIVISOR) {
            return BASIS_POINTS_DIVISOR;
        }

        return refundBasisPoints;
    }
}