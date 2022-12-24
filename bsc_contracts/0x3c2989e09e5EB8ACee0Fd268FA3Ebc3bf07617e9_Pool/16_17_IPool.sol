// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IPool {
    function targetCollateralRatio() external view returns (uint256);

    function calcMintInput(uint256 _dollarAmount) external view returns (uint256 _mainCollateralAmount, uint256 _secondCollateralAmount, uint256 _shareAmount, uint256 _shareFee);

    function calcMintOutputFromMainCollateral(uint256 _mainCollateralAmount) external view returns (uint256 _dollarAmount, uint256 _secondCollateralAmount, uint256 _shareAmount, uint256 _shareFee);

    function calcMintOutputFromSecondCollateral(uint256 _secondCollateralAmount) external view returns (uint256 _dollarAmount, uint256 _mainCollateralAmount, uint256 _shareAmount, uint256 _shareFee);

    function calcMintOutputFromShare(uint256 _shareAmount) external view returns (uint256 _dollarAmount, uint256 _mainCollateralAmount, uint256 _secondCollateralAmount, uint256 _shareFee);

    function calcRedeemOutput(uint256 _dollarAmount) external view returns (uint256 _mainCollateralAmount, uint256 _secondCollateralAmount, uint256 _shareAmount, uint256 _shareFee);

    function getMainCollateralPrice() external view returns (uint256);

    function getSecondCollateralPrice() external view returns (uint256);

    function getDollarPrice() external view returns (uint256);

    function getSharePrice() external view returns (uint256);

    function getRedemptionOpenTime(address _account) external view returns (uint256);

    function unclaimed_pool_main_collateral() external view returns (uint256);

    function unclaimed_pool_second_collateral() external view returns (uint256);

    function unclaimed_pool_share() external view returns (uint256);

    function mintingLimitHourly() external view returns (uint256 _limit);

    function mintingLimitDaily() external view returns (uint256 _limit);

    function calcMintableDollarHourly() external view returns (uint256 _limit);

    function calcMintableDollarDaily() external view returns (uint256 _limit);

    function calcMintableDollar() external view returns (uint256 _dollarAmount);

    function calcRedeemableDollarHourly() external view returns (uint256 _limit);

    function calcRedeemableDollarDaily() external view returns (uint256 _limit);

    function calcRedeemableDollar() external view returns (uint256 _dollarAmount);

    function updateTargetCollateralRatio() external;
}