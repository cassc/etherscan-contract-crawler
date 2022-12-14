// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;


interface IDibs {
    function reward(address user,bytes32 parentCode,
                    uint256 totalFees,uint256 totalVolume,
                    address token) external returns(uint256 referralFee);

    function findTotalRewardFor(address _user, uint _totalFees) external view returns(uint256 _referralFeeAmount);
}