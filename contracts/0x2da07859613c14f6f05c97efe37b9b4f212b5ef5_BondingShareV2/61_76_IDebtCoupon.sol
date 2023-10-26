// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @title A debt coupon which corresponds to a IDebtRedemption contract
interface IDebtCoupon is IERC1155 {
    function updateTotalDebt() external;

    function burnCoupons(
        address couponOwner,
        uint256 amount,
        uint256 expiryBlockNumber
    ) external;

    function mintCoupons(
        address recipient,
        uint256 amount,
        uint256 expiryBlockNumber
    ) external;

    function getTotalOutstandingDebt() external view returns (uint256);
}