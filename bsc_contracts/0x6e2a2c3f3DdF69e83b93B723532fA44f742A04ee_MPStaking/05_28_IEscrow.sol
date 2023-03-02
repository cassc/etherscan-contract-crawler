// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IEscrow {

    function emergencyWithdrawBNB (address _to) external;

    function emergencyWithdrawToken (
        address _tokenAddress,
        address _to
    ) external;

    function transferMultiTokensToWithPercentage (
        address[] memory _tokens,
        address _to,
        uint256 _percentage,
        uint256 _denominator
    ) external;

    function transferTokenTo (
        address _token,
        address _to,
        uint256 _quantity
    ) external;
}