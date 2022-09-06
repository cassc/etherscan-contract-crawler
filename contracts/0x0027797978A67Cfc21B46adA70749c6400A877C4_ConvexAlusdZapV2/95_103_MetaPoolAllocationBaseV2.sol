// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;

import {SafeMath} from "contracts/libraries/Imports.sol";
import {IERC20} from "contracts/common/Imports.sol";

import {
    ILiquidityGauge,
    IStableSwap
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {IMetaPool} from "contracts/protocols/curve/metapool/Imports.sol";
import {
    IBaseRewardPool
} from "contracts/protocols/convex/common/interfaces/Imports.sol";

import {ImmutableAssetAllocation} from "contracts/tvl/Imports.sol";
import {
    Curve3poolUnderlyerConstants
} from "contracts/protocols/curve/3pool/Constants.sol";

/**
 * @title Periphery Contract for a Curve metapool
 * @author APY.Finance
 * @notice This contract enables the APY.Finance system to retrieve the balance
 *         of an underlyer of a Curve LP token. The balance is used as part
 *         of the Chainlink computation of the deployed TVL.  The primary
 *         `getUnderlyerBalance` function is invoked indirectly when a
 *         Chainlink node calls `balanceOf` on the APYAssetAllocationRegistry.
 */
abstract contract MetaPoolAllocationBaseV2 is
    ImmutableAssetAllocation,
    Curve3poolUnderlyerConstants
{
    using SafeMath for uint256;

    address public constant CURVE_3POOL_ADDRESS =
        0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address public constant CURVE_3CRV_ADDRESS =
        0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

    /**
     * @notice Returns the balance of an underlying token represented by
     *         an account's LP token balance.
     * @param metaPool the liquidity pool comprised of multiple underlyers
     * @param rewardContract the staking contract for the LP tokens
     * @param coin the index indicating which underlyer
     * @return balance
     */
    function getUnderlyerBalance(
        address account,
        IMetaPool metaPool,
        IBaseRewardPool rewardContract,
        IERC20 lpToken,
        uint256 coin
    ) public view returns (uint256 balance) {
        require(address(metaPool) != address(0), "INVALID_POOL");
        require(
            address(rewardContract) != address(0),
            "INVALID_REWARD_CONTRACT"
        );
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");
        require(coin < 256, "INVALID_COIN");

        // since we swap out of primary underlyer, we effectively
        // hold zero of it
        if (coin == 0) {
            return 0;
        }
        // turn into 3Pool index
        coin -= 1;

        // metaPool values
        uint256 lpTokenSupply = lpToken.totalSupply();
        // do not include LP tokens held directly by account, as that
        // is included in the regular Curve allocation
        uint256 accountLpTokenBalance = rewardContract.balanceOf(account);

        uint256 totalSupplyFor3Crv = IERC20(CURVE_3CRV_ADDRESS).totalSupply();

        // metaPool's tracked primary underlyer and 3Crv balances
        // (this will differ from `balanceOf` due to admin fees)
        uint256 metaPoolPrimaryBalance = metaPool.balances(0);
        uint256 metaPool3CrvBalance = metaPool.balances(1);

        // calc account's share of 3Crv
        uint256 account3CrvBalance =
            accountLpTokenBalance.mul(metaPool3CrvBalance).div(lpTokenSupply);
        // calc account's share of primary underlyer
        uint256 accountPrimaryBalance =
            accountLpTokenBalance.mul(metaPoolPrimaryBalance).div(
                lpTokenSupply
            );
        // `metaPool.get_dy` can revert on dx = 0, so we skip the call in that case
        if (accountPrimaryBalance > 0) {
            // expected output of swapping primary underlyer amount for 3Crv tokens
            uint256 swap3CrvOutput =
                metaPool.get_dy(0, 1, accountPrimaryBalance);
            // total amount of 3Crv tokens account owns after swapping out of primary underlyer
            account3CrvBalance = account3CrvBalance.add(swap3CrvOutput);
        }

        // get account's share of 3Pool underlyer
        uint256 basePoolUnderlyerBalance =
            IStableSwap(CURVE_3POOL_ADDRESS).balances(coin);
        balance = account3CrvBalance.mul(basePoolUnderlyerBalance).div(
            totalSupplyFor3Crv
        );
    }

    function _getBasePoolTokenData(
        address primaryUnderlyer,
        string memory symbol,
        uint8 decimals
    ) internal pure returns (TokenData[] memory) {
        TokenData[] memory tokens = new TokenData[](4);
        tokens[0] = TokenData(primaryUnderlyer, symbol, decimals);
        tokens[1] = TokenData(DAI_ADDRESS, "DAI", 18);
        tokens[2] = TokenData(USDC_ADDRESS, "USDC", 6);
        tokens[3] = TokenData(USDT_ADDRESS, "USDT", 6);
        return tokens;
    }
}