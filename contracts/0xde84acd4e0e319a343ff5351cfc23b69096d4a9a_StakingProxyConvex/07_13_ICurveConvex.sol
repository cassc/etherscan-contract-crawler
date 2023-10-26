// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ICurveConvex {
   function earmarkRewards(uint256 _pid) external returns(bool);
   function earmarkFees() external returns(bool);
   function poolInfo(uint256 _pid) external returns(address _lptoken, address _token, address _gauge, address _crvRewards, address _stash, bool _shutdown);
   function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns(bool);
}