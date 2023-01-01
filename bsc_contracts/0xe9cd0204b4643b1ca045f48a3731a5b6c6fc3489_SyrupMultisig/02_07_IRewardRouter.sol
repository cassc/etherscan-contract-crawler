// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IRewardRouter {
    function feeSlpTracker() external view returns (address);

    function stakedSlpTracker() external view returns (address);

    function mintAndStakeSlp(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minSlp
    ) external payable returns (uint256);

    function mintAndStakeSlpETH(
        uint256 _minUsdg,
        uint256 _minSlp
    ) external payable returns (uint256);

    function unstakeAndRedeemSlp(
        address _tokenOut,
        uint256 _slpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);
}