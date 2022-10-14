// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ICurve3Pool } from "./ICurve3Pool.sol";

/**
 * @title   Calculates Curve token amounts including fees for the Curve.fi 3Pool.
 * @notice  This has been configured to work for Curve 3Pool which contains DAI, USDC and USDT.
 * This is an alternative to Curve's `calc_token_amount` which does not take into account fees.
 * This library takes into account pool fees.
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-07-12
 * @dev     See Atul Agarwal's post "Understanding the Curve AMM, Part -1: StableSwap Invariant"
 *          for an explaination of the maths behind StableSwap. This includes an explation of the
 *          variables S, D, Ann used in _getD
 *          https://atulagarwal.dev/posts/curveamm/stableswap/
 */
library Curve3PoolCalculatorLibrary {
    /// @notice Number of coins in the pool.
    uint256 public constant N_COINS = 3;
    uint256 public constant VIRTUAL_PRICE_SCALE = 1e18;
    /// @notice Scale of the Curve.fi metapool fee. 100% = 1e10, 0.04% = 4e6.
    uint256 public constant CURVE_FEE_SCALE = 1e10;
    /// @notice Address of the Curve.fi 3Pool contract.
    address public constant THREE_POOL = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    /// @notice Address of the Curve.fi 3Pool liquidity token (3Crv).
    address public constant LP_TOKEN = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    /// @notice Scales up the mint tokens by 0.002 basis points.
    uint256 public constant MINT_ADJUST = 10000002;
    uint256 public constant MINT_ADJUST_SCALE = 10000000;

    /**
     * @notice Calculates the amount of liquidity provider tokens (3Crv) to mint for depositing a fixed amount of pool tokens.
     * @param _tokenAmount The amount of coins, eg DAI, USDC or USDT, to deposit.
     * @param _coinIndex The index of the coin in the pool to withdraw. 0 = DAI, 1 = USDC, 2 = USDT.
     * @return mintAmount_ The amount of liquidity provider tokens (3Crv) to mint.
     * @return invariant_ The invariant before the deposit. This is the USD value of the 3Pool.
     * @return totalSupply_ Total liquidity provider tokens (3Crv) before the deposit.
     */
    function calcDeposit(uint256 _tokenAmount, uint256 _coinIndex)
        external
        view
        returns (
            uint256 mintAmount_,
            uint256 invariant_,
            uint256 totalSupply_
        )
    {
        totalSupply_ = IERC20(LP_TOKEN).totalSupply();
        // To save gas, only deal with deposits when there are already coins in the 3Pool.
        require(totalSupply_ > 0, "empty THREE_POOL");

        // Get balance of each stablecoin in the 3Pool
        uint256[N_COINS] memory oldBalances = [
            ICurve3Pool(THREE_POOL).balances(0), // DAI
            ICurve3Pool(THREE_POOL).balances(1), // USDC
            ICurve3Pool(THREE_POOL).balances(2) // USDT
        ];
        // Scale USDC and USDT from 6 decimals up to 18 decimals
        uint256[N_COINS] memory oldBalancesScaled = [
            oldBalances[0],
            oldBalances[1] * 1e12,
            oldBalances[2] * 1e12
        ];

        // Get 3Pool amplitude coefficient (A)
        uint256 Ann = ICurve3Pool(THREE_POOL).A() * N_COINS;

        // USD value before deposit
        invariant_ = _getD(oldBalancesScaled, Ann);

        // Add deposit to corresponding balance
        uint256[N_COINS] memory newBalances = [
            _coinIndex == 0 ? oldBalances[0] + _tokenAmount : oldBalances[0],
            _coinIndex == 1 ? oldBalances[1] + _tokenAmount : oldBalances[1],
            _coinIndex == 2 ? oldBalances[2] + _tokenAmount : oldBalances[2]
        ];
        // Scale USDC and USDT from 6 decimals up to 18 decimals
        uint256[N_COINS] memory newBalancesScaled = [
            newBalances[0],
            newBalances[1] * 1e12,
            newBalances[2] * 1e12
        ];

        // Invariant after deposit
        uint256 invariantAfterDeposit = _getD(newBalancesScaled, Ann);

        // We need to recalculate the invariant accounting for fees
        // to calculate fair user's share
        // _fee: uint256 = self.fee * N_COINS / (4 * (N_COINS - 1))
        uint256 fee = (ICurve3Pool(THREE_POOL).fee() * 3) / 8;

        // The following is not in a for loop to save gas

        // DAI at index 0
        uint256 idealBalanceScaled = (invariantAfterDeposit * oldBalances[0]) / invariant_;
        uint256 differenceScaled = idealBalanceScaled > newBalances[0]
            ? idealBalanceScaled - newBalances[0]
            : newBalances[0] - idealBalanceScaled;
        newBalancesScaled[0] = newBalances[0] - ((fee * differenceScaled) / CURVE_FEE_SCALE);

        // USDC at index 1
        idealBalanceScaled = (invariantAfterDeposit * oldBalances[1]) / invariant_;
        differenceScaled = idealBalanceScaled > newBalances[1]
            ? idealBalanceScaled - newBalances[1]
            : newBalances[1] - idealBalanceScaled;
        // Scale up USDC from 6 to 18 decimals
        newBalancesScaled[1] = (newBalances[1] - (fee * differenceScaled) / CURVE_FEE_SCALE) * 1e12;

        // USDT at index 2
        idealBalanceScaled = (invariantAfterDeposit * oldBalances[2]) / invariant_;
        differenceScaled = idealBalanceScaled > newBalances[2]
            ? idealBalanceScaled - newBalances[2]
            : newBalances[2] - idealBalanceScaled;
        // Scale up USDT from 6 to 18 decimals
        newBalancesScaled[2] = (newBalances[2] - (fee * differenceScaled) / CURVE_FEE_SCALE) * 1e12;

        // Calculate, how much pool tokens to mint
        // LP tokens to mint = total LP tokens * (USD value after - USD value before) / USD value before
        mintAmount_ = (totalSupply_ * (_getD(newBalancesScaled, Ann) - invariant_)) / invariant_;
    }

    /**
     * @notice Calculates the amount of liquidity provider tokens (3Crv) to burn for receiving a fixed amount of pool tokens.
     * @param _tokenAmount The amount of coins, eg DAI, USDC or USDT, required to receive.
     * @param _coinIndex The index of the coin in the pool to withdraw. 0 = DAI, 1 = USDC, 2 = USDT.
     * @return burnAmount_ The amount of liquidity provider tokens (3Crv) to burn.
     * @return invariant_ The invariant before the withdraw. This is the USD value of the 3Pool.
     * @return totalSupply_ Total liquidity provider tokens (3Crv) before the withdraw.
     */
    function calcWithdraw(uint256 _tokenAmount, uint256 _coinIndex)
        external
        view
        returns (
            uint256 burnAmount_,
            uint256 invariant_,
            uint256 totalSupply_
        )
    {
        totalSupply_ = IERC20(LP_TOKEN).totalSupply();
        require(totalSupply_ > 0, "empty THREE_POOL");

        // Get balance of each stablecoin in the 3Pool
        uint256[N_COINS] memory oldBalances = [
            ICurve3Pool(THREE_POOL).balances(0), // DAI
            ICurve3Pool(THREE_POOL).balances(1), // USDC
            ICurve3Pool(THREE_POOL).balances(2) // USDT
        ];
        // Scale USDC and USDT from 6 decimals up to 18 decimals
        uint256[N_COINS] memory oldBalancesScaled = [
            oldBalances[0],
            oldBalances[1] * 1e12,
            oldBalances[2] * 1e12
        ];

        // Get 3Pool amplitude coefficient (A)
        uint256 Ann = ICurve3Pool(THREE_POOL).A() * N_COINS;

        // USD value before withdraw
        invariant_ = _getD(oldBalancesScaled, Ann);

        // Remove withdraw from corresponding balance
        uint256[N_COINS] memory newBalances = [
            _coinIndex == 0 ? oldBalances[0] - _tokenAmount : oldBalances[0],
            _coinIndex == 1 ? oldBalances[1] - _tokenAmount : oldBalances[1],
            _coinIndex == 2 ? oldBalances[2] - _tokenAmount : oldBalances[2]
        ];
        // Scale USDC and USDT from 6 decimals up to 18 decimals
        uint256[N_COINS] memory newBalancesScaled = [
            newBalances[0],
            newBalances[1] * 1e12,
            newBalances[2] * 1e12
        ];

        // Invariant after withdraw
        uint256 invariantAfterWithdraw = _getD(newBalancesScaled, Ann);

        // We need to recalculate the invariant accounting for fees
        // to calculate fair user's share
        // _fee: uint256 = self.fee * N_COINS / (4 * (N_COINS - 1))
        uint256 fee = (ICurve3Pool(THREE_POOL).fee() * 3) / 8;

        // The following is not in a for loop to save gas

        // DAI at index 0
        uint256 idealBalanceScaled = (invariantAfterWithdraw * oldBalances[0]) / invariant_;
        uint256 differenceScaled = idealBalanceScaled > newBalances[0]
            ? idealBalanceScaled - newBalances[0]
            : newBalances[0] - idealBalanceScaled;
        newBalancesScaled[0] = newBalances[0] - ((fee * differenceScaled) / CURVE_FEE_SCALE);

        // USDC at index 1
        idealBalanceScaled = (invariantAfterWithdraw * oldBalances[1]) / invariant_;
        differenceScaled = idealBalanceScaled > newBalances[1]
            ? idealBalanceScaled - newBalances[1]
            : newBalances[1] - idealBalanceScaled;
        // Scale up USDC from 6 to 18 decimals
        newBalancesScaled[1] = (newBalances[1] - (fee * differenceScaled) / CURVE_FEE_SCALE) * 1e12;

        // USDT at index 2
        idealBalanceScaled = (invariantAfterWithdraw * oldBalances[2]) / invariant_;
        differenceScaled = idealBalanceScaled > newBalances[2]
            ? idealBalanceScaled - newBalances[2]
            : newBalances[2] - idealBalanceScaled;
        // Scale up USDT from 6 to 18 decimals
        newBalancesScaled[2] = (newBalances[2] - (fee * differenceScaled) / CURVE_FEE_SCALE) * 1e12;

        // Calculate, how much pool tokens to burn
        // LP tokens to burn = total LP tokens * (USD value before - USD value after) / USD value before
        burnAmount_ =
            ((totalSupply_ * (invariant_ - _getD(newBalancesScaled, Ann))) / invariant_) +
            1;
    }

    /**
     * @notice Calculates the amount of pool coins to deposit for minting a fixed amount of liquidity provider tokens (3Crv).
     * @param _mintAmount The amount of liquidity provider tokens (3Crv) to mint.
     * @param _coinIndex The index of the coin in the pool to withdraw. 0 = DAI, 1 = USDC, 2 = USDT.
     * @return tokenAmount_ The amount of coins, eg DAI, USDC or USDT, to deposit.
     * @return invariant_ The invariant before the mint. This is the USD value of the 3Pool.
     * @return totalSupply_ Total liquidity provider tokens (3Crv) before the mint.
     */
    function calcMint(uint256 _mintAmount, uint256 _coinIndex)
        external
        view
        returns (
            uint256 tokenAmount_,
            uint256 invariant_,
            uint256 totalSupply_
        )
    {
        totalSupply_ = IERC20(LP_TOKEN).totalSupply();
        // To save gas, only deal with mints when there are already coins in the 3Pool.
        require(totalSupply_ > 0, "empty THREE_POOL");

        // Get 3Pool balances and scale to 18 decimal
        uint256[N_COINS] memory oldBalancesScaled = [
            ICurve3Pool(THREE_POOL).balances(0), // DAI
            ICurve3Pool(THREE_POOL).balances(1) * 1e12, // USDC
            ICurve3Pool(THREE_POOL).balances(2) * 1e12 // USDT
        ];

        uint256 Ann = ICurve3Pool(THREE_POOL).A() * N_COINS;

        // Get invariant before mint
        invariant_ = _getD(oldBalancesScaled, Ann);

        // Desired invariant after mint
        uint256 invariantAfterMint = invariant_ + ((_mintAmount * invariant_) / totalSupply_);

        // Required coin balance to get to the new invariant after mint
        uint256 requiredBalanceScaled = _getY(
            oldBalancesScaled,
            Ann,
            _coinIndex,
            invariantAfterMint
        );

        // Adjust balances for fees
        uint256 fee = (ICurve3Pool(THREE_POOL).fee() * 3) / 8;
        uint256[N_COINS] memory newBalancesScaled;

        // The following is not in a for loop to save gas

        // DAI at index 0
        uint256 dx_expected = _coinIndex == 0
            ? requiredBalanceScaled - ((oldBalancesScaled[0] * invariantAfterMint) / invariant_)
            : ((oldBalancesScaled[0] * invariantAfterMint) / invariant_) - oldBalancesScaled[0];
        // the -1 covers 18 decimal rounding issues
        newBalancesScaled[0] = oldBalancesScaled[0] - ((dx_expected * fee) / CURVE_FEE_SCALE) - 1;

        // USDC at index 1
        dx_expected = _coinIndex == 1
            ? requiredBalanceScaled - ((oldBalancesScaled[1] * invariantAfterMint) / invariant_)
            : ((oldBalancesScaled[1] * invariantAfterMint) / invariant_) - oldBalancesScaled[1];
        // the -1e12 covers 6 decimal rounding issues
        newBalancesScaled[1] =
            oldBalancesScaled[1] -
            ((dx_expected * fee) / CURVE_FEE_SCALE) -
            1e12;

        // USDT at index 2
        dx_expected = _coinIndex == 2
            ? requiredBalanceScaled - ((oldBalancesScaled[2] * invariantAfterMint) / invariant_)
            : ((oldBalancesScaled[2] * invariantAfterMint) / invariant_) - oldBalancesScaled[2];
        // the -1e12 covers 6 decimal rounding issues
        newBalancesScaled[2] =
            oldBalancesScaled[2] -
            ((dx_expected * fee) / CURVE_FEE_SCALE) -
            1e12;

        // tokens (DAI, USDC or USDT) to transfer from caller scaled to 18 decimals
        tokenAmount_ =
            _getY(newBalancesScaled, Ann, _coinIndex, invariantAfterMint) -
            newBalancesScaled[_coinIndex];
        // If DAI then already 18 decimals, else its USDC or USDT so need to scale down to only 6 decimals
        // Deposit more to account for rounding errors
        tokenAmount_ = _coinIndex == 0 ? tokenAmount_ : tokenAmount_ / 1e12;

        // Round up the amount
        tokenAmount_ = (tokenAmount_ * MINT_ADJUST) / MINT_ADJUST_SCALE;
    }

    /**
     * @notice Calculates the amount of pool coins to receive for redeeming a fixed amount of liquidity provider tokens (3Crv).
     * @param _burnAmount The amount of liquidity provider tokens (3Crv) to burn.
     * @param _coinIndex The index of the coin in the pool to withdraw. 0 = DAI, 1 = USDC, 2 = USDT.
     * @return tokenAmount_ The amount of coins, eg DAI, USDC or USDT, to receive from the redeem.
     * @return invariant_ The invariant before the redeem. This is the USD value of the 3Pool.
     * @return totalSupply_ Total liquidity provider tokens (3Crv) before the redeem.
     */
    function calcRedeem(uint256 _burnAmount, uint256 _coinIndex)
        external
        view
        returns (
            uint256 tokenAmount_,
            uint256 invariant_,
            uint256 totalSupply_
        )
    {
        totalSupply_ = IERC20(LP_TOKEN).totalSupply();
        require(totalSupply_ > 0, "empty THREE_POOL");

        uint256[N_COINS] memory oldBalancesScaled = [
            ICurve3Pool(THREE_POOL).balances(0), // DAI
            ICurve3Pool(THREE_POOL).balances(1) * 1e12, // USDC
            ICurve3Pool(THREE_POOL).balances(2) * 1e12 // USDT
        ];

        uint256 Ann = ICurve3Pool(THREE_POOL).A() * N_COINS;

        // Get invariant before redeem
        invariant_ = _getD(oldBalancesScaled, Ann);

        // Desired invariant after redeem
        uint256 invariantAfterRedeem = invariant_ - ((_burnAmount * invariant_) / totalSupply_);

        // Required coin balance to get to the new invariant after redeem
        uint256 requiredBalanceScaled = _getY(
            oldBalancesScaled,
            Ann,
            _coinIndex,
            invariantAfterRedeem
        );

        // Adjust balances for fees
        // _fee: uint256 = self.fee * N_COINS / (4 * (N_COINS - 1))
        uint256 fee = (ICurve3Pool(THREE_POOL).fee() * 3) / 8;
        uint256[N_COINS] memory newBalancesScaled;

        // The following is not in a for loop to save gas

        // DAI at index 0
        uint256 dx_expected = _coinIndex == 0
            ? ((oldBalancesScaled[0] * invariantAfterRedeem) / invariant_) - requiredBalanceScaled
            : oldBalancesScaled[0] - (oldBalancesScaled[0] * invariantAfterRedeem) / invariant_;
        newBalancesScaled[0] = oldBalancesScaled[0] - ((dx_expected * fee) / CURVE_FEE_SCALE);

        // USDC at index 1
        dx_expected = _coinIndex == 1
            ? ((oldBalancesScaled[1] * invariantAfterRedeem) / invariant_) - requiredBalanceScaled
            : oldBalancesScaled[1] - (oldBalancesScaled[1] * invariantAfterRedeem) / invariant_;
        newBalancesScaled[1] = oldBalancesScaled[1] - ((dx_expected * fee) / CURVE_FEE_SCALE);

        // USDT at index 2
        dx_expected = _coinIndex == 2
            ? ((oldBalancesScaled[2] * invariantAfterRedeem) / invariant_) - requiredBalanceScaled
            : oldBalancesScaled[2] - (oldBalancesScaled[2] * invariantAfterRedeem) / invariant_;
        newBalancesScaled[2] = oldBalancesScaled[2] - ((dx_expected * fee) / CURVE_FEE_SCALE);

        // tokens (DAI, USDC or USDT) to transfer to receiver scaled to 18 decimals
        uint256 tokenAmountScaled = newBalancesScaled[_coinIndex] -
            _getY(newBalancesScaled, Ann, _coinIndex, invariantAfterRedeem) -
            1; // Withdraw less to account for rounding errors

        // If DAI then already 18 decimals, else its USDC or USDT so need to scale down to only 6 decimals
        tokenAmount_ = _coinIndex == 0 ? tokenAmountScaled : tokenAmountScaled / 1e12;
    }

    /**
     * Get 3Pool's virtual price which is in USD. This is 3Pool's USD value (invariant)
     * divided by the number of LP tokens scaled to `VIRTUAL_PRICE_SCALE` which is 1e18.
     * @return virtualPrice_ 3Pool's virtual price in USD scaled to 18 decimal places.
     */
    function getVirtualPrice() external view returns (uint256 virtualPrice_) {
        // Calculate the USD value of the 3Pool which is the invariant
        uint256 invariant = _getD(
            [
                ICurve3Pool(THREE_POOL).balances(0),
                ICurve3Pool(THREE_POOL).balances(1) * 1e12,
                ICurve3Pool(THREE_POOL).balances(2) * 1e12
            ],
            ICurve3Pool(THREE_POOL).A() * N_COINS
        );

        // This will fail if the pool is empty.
        // virtual price of one 3Crv in USD scaled to 18 decimal places (3Crv/USD) = 3Pool USD value * 1e18 / total 3Crv
        virtualPrice_ = (invariant * VIRTUAL_PRICE_SCALE) / IERC20(LP_TOKEN).totalSupply();
    }

    /**
     * @notice Uses Newton’s Method to iteratively solve the StableSwap invariant (D).
     * @param xp  The scaled balances of the coins in the 3Pool.
     * @param Ann The amplitude coefficient multiplied by the number of coins in the pool (A * N_COINS).
     * @return D  The StableSwap invariant
     */
    function _getD(uint256[N_COINS] memory xp, uint256 Ann) internal pure returns (uint256 D) {
        uint256 S = xp[0] + xp[1] + xp[2];

        // Do these multiplications here rather than in each loop
        uint256 xp0 = xp[0] * N_COINS;
        uint256 xp1 = xp[1] * N_COINS;
        uint256 xp2 = xp[2] * N_COINS;

        uint256 Dprev = 0;
        D = S;
        uint256 D_P;
        for (uint256 i = 0; i < 255; ) {
            // D_P: uint256 = D
            // for _x in xp:
            //     D_P = D_P * D / (_x * N_COINS)  # If division by 0, this will be borked: only withdrawal will work. And that is good
            D_P = (((((D * D) / xp0) * D) / xp1) * D) / xp2;

            Dprev = D;
            D = ((Ann * S + D_P * N_COINS) * D) / ((Ann - 1) * D + (N_COINS + 1) * D_P);
            // Equality with the precision of 1
            if (D > Dprev) {
                if (D - Dprev <= 1) break;
            } else {
                if (Dprev - D <= 1) break;
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * Calculate x[i] if one reduces D from being calculated for xp to D
     *
       Done by solving quadratic equation iteratively using the Newton's method.
        x_1**2 + x1 * (sum' - (A*n**n - 1) * D / (A * n**n)) = D ** (n + 1) / (n ** (2 * n) * prod' * A)
        x_1**2 + b*x_1 = c

        x_1 = (x_1**2 + c) / (2*x_1 + b)
     */
    function _getY(
        uint256[N_COINS] memory xp,
        uint256 Ann,
        uint256 coinIndex,
        uint256 D
    ) internal pure returns (uint256 y) {
        uint256 c = D;
        uint256 S_ = 0;
        if (coinIndex != 0) {
            S_ += xp[0];
            c = (c * D) / (xp[0] * N_COINS);
        }
        if (coinIndex != 1) {
            S_ += xp[1];
            c = (c * D) / (xp[1] * N_COINS);
        }
        if (coinIndex != 2) {
            S_ += xp[2];
            c = (c * D) / (xp[2] * N_COINS);
        }

        c = (c * D) / (Ann * N_COINS);
        uint256 b = S_ + D / Ann;
        uint256 yPrev = 0;
        y = D;
        uint256 i = 0;
        for (; i < 255; ) {
            yPrev = y;
            y = (y * y + c) / (2 * y + b - D);

            // Equality with the precision of 1
            if (y > yPrev) {
                if (y - yPrev <= 1) break;
            } else {
                if (yPrev - y <= 1) break;
            }

            unchecked {
                ++i;
            }
        }
    }
}