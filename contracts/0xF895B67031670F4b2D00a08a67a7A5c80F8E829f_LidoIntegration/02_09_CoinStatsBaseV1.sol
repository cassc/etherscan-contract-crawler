// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./FeesV1.sol";

interface IVault {
  function addAffiliateBalance(
    address affiliate,
    address token,
    uint256 affiliatePortion
  ) external;
}

abstract contract CoinStatsBaseV1 is FeesV1 {
  using SafeERC20 for IERC20;

  address public immutable VAULT;

  constructor(
    uint256 _goodwill,
    uint256 _affiliateSplit,
    address _vaultAddress
  ) FeesV1(_goodwill, _affiliateSplit) {
    VAULT = _vaultAddress;
  }

  /// @notice Sends provided token amount to the contract
  /// @param token represents token address to be transfered
  /// @param amount represents token amount to be transfered
  function _pullTokens(address token, uint256 amount)
    internal
    returns (uint256 balance)
  {
    if (token == address(0) || token == ETH_ADDRESS) {
      require(msg.value > 0, "ETH was not sent");
    } else {
      // solhint-disable reason-string
      require(msg.value == 0, "Along with token, the ETH was also sent");
      uint256 balanceBefore = _getBalance(token);

      // Transfers all tokens to current contract
      IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

      return _getBalance(token) - balanceBefore;
    }
    return amount;
  }

  /// @notice Subtracts goodwill portion from given amount
  /// @dev If 0x00... address was given, then it will be replaced with 0xEeeEE... address
  /// @param token represents token address
  /// @param amount represents token amount
  /// @param affiliate goodwill affiliate
  /// @param enableGoodwill boolean representation whether to charge fee or not
  /// @return totalGoodwillPortion the amount of goodwill
  function _subtractGoodwill(
    address token,
    uint256 amount,
    address affiliate,
    bool enableGoodwill
  ) internal returns (uint256 totalGoodwillPortion) {
    bool whitelisted = feeWhitelist[msg.sender];

    if (enableGoodwill && !whitelisted && (goodwill > 0)) {
      totalGoodwillPortion = (amount * goodwill) / 10000;

      if (token == address(0) || token == ETH_ADDRESS) {
        Address.sendValue(payable(VAULT), totalGoodwillPortion);
      } else {
        uint256 balanceBefore = IERC20(token).balanceOf(VAULT);
        IERC20(token).safeTransfer(VAULT, totalGoodwillPortion);
        totalGoodwillPortion = IERC20(token).balanceOf(VAULT) - balanceBefore;
      }

      if (affiliates[affiliate]) {
        if (token == address(0)) {
          token = ETH_ADDRESS;
        }

        uint256 affiliatePortion = (totalGoodwillPortion * affiliateSplit) /
          100;

        IVault(VAULT).addAffiliateBalance(affiliate, token, affiliatePortion);
      }
    }
  }
}