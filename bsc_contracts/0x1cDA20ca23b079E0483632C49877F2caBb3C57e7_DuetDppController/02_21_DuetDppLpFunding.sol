// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import { DecimalMath } from "./lib/DecimalMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { IDODOV2 } from "./interfaces/IDODOV2.sol";
import { DuetDppERC20 } from "./DuetDppERC20.sol";

/// @title DppLpFunding
/// @author So. Lu
/// @notice For buy lps and sell lps
contract DuetDppLpFunding is DuetDppERC20, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public constant MINIMUM_SUPPLY = 10**3 + 1;
    // ============ Events ============

    event BuyShares(address to, uint256 increaseShares, uint256 totalShares);

    event SellShares(address payer, address to, uint256 decreaseShares, uint256 totalShares);

    // ============ Buy & Sell Shares ============

    // buy shares [round down]
    function _buyShares(address to)
        internal
        returns (
            uint256 shares,
            uint256 baseInput,
            uint256 quoteInput
        )
    {
        uint256 baseBalance = _BASE_TOKEN_.balanceOf(_DPP_ADDRESS_);
        uint256 quoteBalance = _QUOTE_TOKEN_.balanceOf(_DPP_ADDRESS_);
        (uint256 baseReserve, uint256 quoteReserve) = IDODOV2(_DPP_ADDRESS_).getVaultReserve();

        baseInput = baseBalance.sub(baseReserve);
        quoteInput = quoteBalance.sub(quoteReserve);
        require(baseInput > 0, "NO_BASE_INPUT");

        // Round down when withdrawing. Therefore, never be a situation occuring balance is 0 but totalsupply is not 0
        // But May Happen，reserve >0 But totalSupply = 0
        if (totalSupply == 0) {
            // case 1. initial supply
            require(baseBalance >= 10**3, "INSUFFICIENT_LIQUIDITY_MINED");
            _mint(address(0), MINIMUM_SUPPLY);
            shares = baseBalance.sub(MINIMUM_SUPPLY); // 以免出现balance很大但shares很小的情况
        } else if (baseReserve > 0 && quoteReserve == 0) {
            // case 2. supply when quote reserve is 0
            shares = baseInput.mul(totalSupply).div(baseReserve);
        } else if (baseReserve > 0 && quoteReserve > 0) {
            // case 3. normal case
            uint256 baseInputShare = (baseInput * totalSupply) / baseReserve;
            uint256 quoteInputShare = (quoteInput * totalSupply) / quoteReserve;
            shares = baseInputShare < quoteInputShare ? baseInputShare : quoteInputShare;
        }
        _mint(to, shares);
        emit BuyShares(to, shares, _SHARES_[to]);
    }

    // sell shares [round down]
    function _sellShares(
        uint256 shareAmount,
        address to,
        uint256 baseMinAmount,
        uint256 quoteMinAmount
    ) internal returns (uint256 baseAmount, uint256 quoteAmount) {
        require(shareAmount <= _SHARES_[to], "Duet_LP_NOT_ENOUGH");
        (uint256 baseBalance, uint256 quoteBalance) = IDODOV2(_DPP_ADDRESS_).getVaultReserve();
        uint256 totalShares = totalSupply;

        baseAmount = baseBalance.mul(shareAmount).div(totalShares);
        quoteAmount = quoteBalance.mul(shareAmount).div(totalShares);

        require(
            baseAmount >= baseMinAmount && quoteAmount >= quoteMinAmount,
            "Duet Dpp Controller: WITHDRAW_NOT_ENOUGH"
        );

        _burn(to, shareAmount);

        emit SellShares(to, to, shareAmount, _SHARES_[to]);
    }
}