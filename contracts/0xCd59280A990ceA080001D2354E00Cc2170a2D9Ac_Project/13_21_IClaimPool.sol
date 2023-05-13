// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface IClaimPool is IERC165Upgradeable {
    function initialize(address _owner, address _project, address _paymentToken) external;

    function addBudgetTo(address _collectionAddress, uint256 _budget) external;

    function withdrawBudgetFrom(address _collectionAddress, address _to, uint256 _amount) external;

    function addBudgetUse(address _collectionAddress, uint256 _amount) external;

    function reduceBudgetUse(address _collectionAddress, uint256 _amount) external;

    function transferToReward(address _collectionAddress, uint256 _amount) external;

    function getFreeBudget(address _collectionAddress) external view returns (uint256);
}