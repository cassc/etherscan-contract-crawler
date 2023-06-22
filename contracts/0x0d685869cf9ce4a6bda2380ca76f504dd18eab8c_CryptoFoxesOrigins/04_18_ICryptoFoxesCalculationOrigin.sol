// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @author: miinded.com

interface ICryptoFoxesCalculationOrigin {
    function calculationRewards(address _contract, uint256[] calldata _tokenIds, uint256 _currentTimestamp) external view returns(uint256);
    function claimRewards(address _contract, uint256[] calldata _tokenIds, address _owner) external;
}