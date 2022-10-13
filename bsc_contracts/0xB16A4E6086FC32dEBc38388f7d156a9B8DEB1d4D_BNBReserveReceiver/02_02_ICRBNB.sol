// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface ICRBNB {
    function _acceptAdmin() external returns (uint256);
    function _reduceReserves(uint256 reduceAmount) external returns (uint256);
    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint256);
    function pendingAdmin() external view returns (address);
    function mint() external payable;
    event ReservesReduced(address admin, uint256 reduceAmount, uint256 newTotalReserves);
}