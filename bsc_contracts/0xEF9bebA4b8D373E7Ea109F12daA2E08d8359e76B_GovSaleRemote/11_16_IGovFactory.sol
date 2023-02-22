// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IGovFactory {
  event ProjectCreated(address indexed project, uint256 index);

  function beacon() external view returns (address);

  function savior() external view returns (address);

  function keeper() external view returns (address);

  function saleGateway() external view returns (address);

  function operational() external view returns (address);

  function marketing() external view returns (address);

  function treasury() external view returns (address);

  function operationalPercentage_d2() external view returns (uint128);

  function marketingPercentage_d2() external view returns (uint128);

  function treasuryPercentage_d2() external view returns (uint128);

  function gasForDestinationLzReceive() external view returns (uint256);

  function crossFee_d2() external view returns (uint128);

  function allProjectsLength() external view returns (uint256);

  function allPaymentsLength() external view returns (uint256);

  function allProjects(uint256) external view returns (address);

  function allPayments(uint256) external view returns (address);

  function getPaymentIndex(address) external view returns (uint256);

  function isKnown(address) external view returns (bool);

  function setPayment(address) external;

  function setGasForDestinationLzReceive(uint256) external;

  function removePayment(address) external;

  function config(
    address,
    address,
    address,
    address,
    address,
    address,
    address
  ) external;
}