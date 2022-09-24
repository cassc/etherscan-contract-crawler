// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface ICustomerSettings {
  event ContractReady(address indexed intializer);
  event ProjectPurchaseFeeSet(string indexed projectId, address feeToken, uint256 fee);
  event ProjectFreeMinterSet(string indexed projectId, address freeMinter, uint256 freeMintAmount);

  function getProjectPurchaseFee(string memory projectId) external view returns (uint256);
  function getProjectPurchaseFeeToken(string memory projectId) external view returns (address);
  function getProjectFreeMintAmount(string memory projectId, address freeMinter) external view returns (uint256);
  function decrementProjectFreeMint(string memory projectId, address freeMinter, uint256 amount) external;
}