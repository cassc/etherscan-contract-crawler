//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IStrategyToken {
    function deposit(uint256 amt, uint256[] memory minLPAmounts) external;

    function withdraw(uint256[] memory minBaseAmounts) external;
}

interface IMultiStrategyToken is IStrategyToken {
    function approveToken() external;

    function strategies(uint256 idx) external view returns (address);

    function strategyCount() external view returns (uint256);

    function ratios(address _strategy) external view returns (uint256);

    function ratioTotal() external view returns (uint256);

    function changeRatio(uint256 _index, uint256 _value) external;

    function inCaseTokensGetStuck(
        address token,
        uint256 _amount,
        address _to
    ) external;

    function updateAllStrategies() external;
}