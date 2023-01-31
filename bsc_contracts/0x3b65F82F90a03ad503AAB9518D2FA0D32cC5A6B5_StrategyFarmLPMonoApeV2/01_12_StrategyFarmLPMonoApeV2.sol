// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "./StrategyFarmLPMono.sol";


contract StrategyFarmLPMonoApeV2 is StrategyFarmLPMono {

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
    ) StrategyFarmLPMono(
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
        amount = IMasterChefApeV2(masterchef).pendingBanana(poolId, address(this));
        return amount;
    }

    function _poolDeposit(uint256 _amount) internal override virtual {
        IMasterChefApeV2(masterchef).deposit(poolId, _amount);
    }

    function _poolWithdraw(uint256 amount) internal override virtual {
        IMasterChefApeV2(masterchef).withdraw(poolId, amount);
    }
}

interface IMasterChefApeV2 is IMasterChef {
    function pendingBanana(uint256 _pid, address _user) external view returns (uint256);
}