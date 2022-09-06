//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IStrategyAlpacaFarm {
    function wantLockedInHere() external view returns (uint256);

    function deposit(uint256 wantAmt, uint256 minLPAmount) external;

    function withdraw(uint256 minBaseAmount) external;

    function updateStrategy() external;

    function uniRouterAddress() external view returns (address);

    function wantAddress() external view returns (address);

    function earnedToWantPath(uint256 idx) external view returns (address);

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) external;
}