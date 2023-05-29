// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @author: miinded.com

interface ICryptoFoxesCalculationV2 {
    function calculationRewardsV2(address _contract, uint16[] calldata _tokenIds, uint256 _currentTimestamp) external view returns(uint256);
    function claimRewardsV2(address _contract, uint16[] calldata _tokenIds, address _owner) external;
    function claimMoveRewardsOrigin(address _contract, uint16 _tokenId, address _ownerOrigin) external;
}