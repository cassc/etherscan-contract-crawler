pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (interfaces/external/convex/IConvexJointVaultManager.sol)

// ref: https://github.com/convex-eth/frax-cvx-platform/blob/feature/joint_vault/contracts/contracts/JointVaultManager.sol
interface IConvexJointVaultManager {
    function setFees(uint256 _owner, uint256 _jointowner, uint256 _booster) external;
    function acceptFees() external;
    function setJointOwnerDepositAddress(address _deposit) external;
    function setAllowedAddress(address _account, bool _allowed) external;

    function getOwnerFee(uint256 _amount, address _usingProxy) external view returns (uint256 _feeAmount, address _feeDeposit);
    function getJointownerFee(uint256 _amount, address _usingProxy) external view returns(uint256 _feeAmount, address _feeDeposit);
    function isAllowed(address _account) external view returns(bool);
    function allowBooster() external;
    function setVaultProxy(address _vault) external;
}