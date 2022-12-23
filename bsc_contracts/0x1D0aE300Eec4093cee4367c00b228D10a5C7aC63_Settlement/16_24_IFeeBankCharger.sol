// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IFeeBankCharger {
    function availableCredit(address account) external view returns (uint256);
    function increaseAvailableCredit(address account, uint256 amount) external returns (uint256 allowance);
    function decreaseAvailableCredit(address account, uint256 amount) external returns (uint256 allowance);
}