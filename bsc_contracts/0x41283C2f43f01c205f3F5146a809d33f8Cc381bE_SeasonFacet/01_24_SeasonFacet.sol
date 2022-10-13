/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity = 0.8.16;

import "./Sun.sol";
import "../../../interfaces/IOracle.sol";
import "../../../libraries/LibCheck.sol";
import "../../../libraries/LibIncentive.sol";

/**
 * @title Season holds the sunrise function and handles all logic for Season changes.
 **/
contract SeasonFacet is Sun {
    using Decimal for Decimal.D256;

    event Sunrise(uint256 indexed season);
    event Incentivization(address indexed account, uint256 topcorns, uint256 incentive, uint256 feeInBnb);
    event SeasonSnapshot(uint32 indexed season, uint256 price, uint256 supply, uint256 stalk, uint256 seeds, uint256 podIndex, uint256 harvestableIndex, uint256 totalLiquidityUSD);

    /**
     * Sunrise
     **/

    function sunrise() external {
        require(!paused(), "Season: Paused.");
        require(seasonTime() > season(), "Season: Still current Season.");

        (Decimal.D256 memory topcornPrice, Decimal.D256 memory busdPrice) = IOracle(address(this)).capture();
        uint256 price = topcornPrice.mul(1e18).div(busdPrice).asUint256();

        (uint256 bnbReserve, uint256 topcornsReserve) = reserves();
        uint256 priceBNB = (Decimal.from(1).div(busdPrice)).mul(1e18).asUint256();
        uint256 _totalLiquidityUSD = (topcornsReserve * price + bnbReserve * priceBNB) / 1e18;
        stepSeason();
        decrementWithdrawSeasons();
        snapshotSeason(price, _totalLiquidityUSD);
        stepWeather(price, s.f.soil);
        uint256 increase = stepSun(topcornPrice, busdPrice);
        stepSilo(increase);
        incentivize(msg.sender, topcornPrice.mul(1e18).asUint256());

        LibCheck.balanceCheck();

        emit Sunrise(season());
    }

    function stepSeason() private {
        s.season.current += 1;
    }

    function decrementWithdrawSeasons() internal {
        uint256 withdrawSeasons = s.season.withdrawSeasons;
        if ((withdrawSeasons > 13 && s.season.current % 84 == 0) || (withdrawSeasons > 5 && s.season.current % 168 == 0)) {
            s.season.withdrawSeasons -= 1;
        }
    }

    function snapshotSeason(uint256 price, uint256 _totalLiquidityUSD) private {
        s.season.timestamp = block.timestamp;
        emit SeasonSnapshot(s.season.current, price, topcorn().totalSupply(), s.s.stalk, s.s.seeds, s.f.pods, s.f.harvestable, _totalLiquidityUSD);
    }

    function incentivize(address account, uint256 price) private {
        uint256 incentive = 0;
        uint256 gasPrice = tx.gasprice;
        if (gasPrice > 8e9) gasPrice = 8e9;
        uint256 feeInBnb = gasPrice * s.season.costSunrice; // calculation Transaction Fee (in bnb)
        uint256 amount = ((feeInBnb * 1e18) / price) + incentive; // feeInBnb/price - Transaction Fee (in topcorn)
        mintToAccount(account, amount);
        emit Incentivization(account, amount, incentive, feeInBnb);
    }
}