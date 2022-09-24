// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface ITaggrSettings {
  event ContractReady(address indexed intializer);
  event MembershipFeeSet(uint256 fee);
  event ProjectLaunchFeeSet(uint256 fee);
  event MembershipFeeTokenSet(address indexed feeToken);
  event ProjectLaunchFeeTokenSet(address indexed feeToken);
  event MintingFeesByPlanTypeSet(uint256 planType, uint256 fee);
  event PlanTypeToggle(uint256 planType, bool isActive);

  function isActivePlanType(uint256 planType) external view returns (bool);
  function getMembershipFee() external view returns (uint256);
  function getProjectLaunchFee() external view returns (uint256);
  function getMembershipFeeToken() external view returns (address);
  function getProjectLaunchFeeToken() external view returns (address);
  function getMintingFeeByPlanType(uint256 planType) external view returns (uint256);
}