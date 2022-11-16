// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./IBaseBondDepository.sol";

interface IBondDepositoryCommon is IBaseBondDepository {
  function reserve() external view returns (IERC20);

  function bondPrice() external view returns (uint256 price);

  function redeem(uint256 bondId, address recipient)
    external
    returns (uint256 payout, uint256 principal);

  function setIsRedeemPaused(bool pause) external;

  function setIsPurchasePaused(bool pause) external;

  event BondPurchased(
    uint256 indexed bondId,
    address indexed recipient,
    uint256 amount,
    uint256 principal,
    uint256 price
  );
  event BondRedeemed(
    uint256 indexed bondId,
    address indexed recipient,
    bool indexed fullyRedeemed,
    uint256 payout,
    uint256 principal
  );
}