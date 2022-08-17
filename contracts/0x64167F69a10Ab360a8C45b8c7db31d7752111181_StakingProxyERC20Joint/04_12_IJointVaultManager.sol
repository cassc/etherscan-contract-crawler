// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IJointVaultManager{
    function getOwnerFee(uint256 _amount, address _usingProxy) external view returns(uint256 _feeAmount, address _feeDeposit);
    function getJointownerFee(uint256 _amount, address _usingProxy) external view returns(uint256 _feeAmount, address _feeDeposit);
    function jointownerProxy() external view returns(address);
    function isAllowed(address _account) external view returns(bool);
}