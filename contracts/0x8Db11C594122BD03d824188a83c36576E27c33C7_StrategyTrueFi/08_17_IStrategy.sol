//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IStrategy {
    function wantLockedInHere() external view returns (uint256);

    function lastEarnBlock() external view returns (uint256);

    function deposit(uint256 _wantAmt) external;

    function withdraw() external;

    function updateStrategy() external;

    function uniRouterAddress() external view returns (address);

    function wantAddress() external view returns (address);

    function earnedToWantPath(uint256 idx) external view returns (address);

    function earn() external;

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) external;
}

interface ILeverageStrategy is IStrategy {
    function leverage(uint256 _amount) external;

    function deleverage(uint256 _amount) external;

    function deleverageAll(uint256 redeemFeeAmount) external;

    function updateBalance()
        external
        view
        returns (
            uint256 sup,
            uint256 brw,
            uint256 supMin
        );

    function borrowRate() external view returns (uint256);

    function setBorrowRate(uint256 _borrowRate) external;
}

interface IStrategyAlpaca is IStrategy {
    function vaultAddress() external view returns (address);

    function poolId() external view returns (uint256);
}

interface IStrategyVenus is ILeverageStrategy {
    function vTokenAddress() external view returns (address);

    function markets(uint256 idx) external view returns (address);

    function earnedAddress() external view returns (address);

    function distributionAddress() external view returns (address);

    function isComp() external view returns (bool);
}