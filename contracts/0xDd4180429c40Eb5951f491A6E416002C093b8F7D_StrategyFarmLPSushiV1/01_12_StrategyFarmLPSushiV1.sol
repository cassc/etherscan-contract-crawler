// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "./StrategyFarmLP.sol";


contract StrategyFarmLPSushiV1 is StrategyFarmLP {
    constructor(
        address _unirouter,
        address _want,
        address _output,
        address _wbnb,

        address _callFeeRecipient,
        address _frfiFeeRecipient,
        address _strategistFeeRecipient,

        address _safeFarmFeeRecipient,

        address _treasuryFeeRecipient,
        address _systemFeeRecipient
    ) StrategyFarmLP(
        _unirouter,
        _want,
        _output,
        _wbnb,

        _callFeeRecipient,
        _frfiFeeRecipient,
        _strategistFeeRecipient,

        _safeFarmFeeRecipient,

        _treasuryFeeRecipient,
        _systemFeeRecipient
    ) {
    }

    function pendingReward() public view override virtual returns (uint256 amount) {
        amount = IMasterChefSushi(masterchef).pendingSushi(poolId, address(this));
        return amount;
    }

    // skip swaps on non liquidity
    function _outputBalance() internal override returns (uint256) {
        uint256 allBal = super._outputBalance();
        uint256 outputHalf = (allBal * (MAX_FEE - poolFee) / MAX_FEE) / 2;

        if (outputHalf == 0) return 0;
        if (_checkLpOutput(lpToken0, outputToLp0Route, outputHalf) == 0) return 0;
        if (_checkLpOutput(lpToken1, outputToLp1Route, outputHalf) == 0) return 0;

        return allBal;
    }

    function _checkLpOutput(
        address lpToken,
        address[] memory route,
        uint256 amount
    ) private view returns (uint256) {
        if (lpToken == output) return amount;

        uint256[] memory amounts = IUniswapRouterETH(unirouter).getAmountsOut(
            amount, route
        );

        return amounts[amounts.length - 1];
    }
}

interface IMasterChefSushi is IMasterChef {
    function pendingSushi(uint256 _pid, address _user) external view returns (uint256);
}