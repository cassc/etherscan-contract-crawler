// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./interfaces.sol";
import "./helpers.sol";

/**
 *@title Compund III Resolver
 *@dev get user position, user configuration, market configuration.
 */
contract CompoundIIIResolver is CompoundIIIHelpers {
    /**
     *@dev get position of the user for all collaterals.
     *@notice get position details of the user in a market including overall position data, collaterals, rewards etc.
     *@param user Address of the user whose position details are needed.
     *@param markets Array of addresses of the market for which the user's position details are needed
     *@return positionData Array of overall position details of the user - balances, rewards, collaterals and flags.
     *@return marketConfig Array of the market configuration details.
     */
    function getPositionForMarkets(address user, address[] calldata markets)
        public
        returns (PositionData[] memory positionData, MarketConfig[] memory marketConfig)
    {
        uint256 length = markets.length;
        positionData = new PositionData[](length);
        marketConfig = new MarketConfig[](length);

        for (uint256 i = 0; i < length; i++) {
            positionData[i].userData = getUserData(user, markets[i]);
            positionData[i].collateralData = getCollateralAll(user, markets[i]);
            marketConfig[i] = getMarketConfig(markets[i]);
        }
    }

    /**
     *@dev get position of the user for given collateral.
     *@notice get position details of the user in a market including overall position data, collaterals, rewards etc.
     *@param user Address of the user whose position details are needed.
     *@param markets Array of addresses of the market for which the user's position details are needed
     *@param tokenIDs IDs or offsets of the token as per comet market whose collateral details are needed.
     *@return positionData Array of overall position details of the user - balances, rewards, collaterals and flags.
     *@return marketConfig Array of the market configuration details.
     */
    function getPositionForTokenIds(
        address user,
        address[] calldata markets,
        uint8[] calldata tokenIDs
    ) public returns (PositionData[] memory positionData, MarketConfig[] memory marketConfig) {
        uint256 length = markets.length;
        positionData = new PositionData[](length);
        marketConfig = new MarketConfig[](length);

        for (uint256 i = 0; i < length; i++) {
            positionData[i].userData = getUserData(user, markets[i]);
            positionData[i].collateralData = getAssetCollaterals(user, markets[i], tokenIDs);
            marketConfig[i] = getMarketConfig(markets[i]);
        }
    }

    /**
     *@dev get market configuration.
     *@notice returns the market stats including market supplies, balances, rates, flags for market operations,
     *collaterals or assets active, base asset info etc.
     *@param markets Array of addresses of the comet market for which the user's position details are needed.
     *@return marketConfigs Array of struct containing data related to the market and the assets.
     */
    function getMarketConfiguration(address[] calldata markets)
        public
        view
        returns (MarketConfig[] memory marketConfigs)
    {
        uint256 length = markets.length;
        marketConfigs = new MarketConfig[](length);

        for (uint256 i = 0; i < length; i++) {
            marketConfigs[i] = getMarketConfig(markets[i]);
        }
    }

    /**
     *@dev get list of collaterals user has supplied..
     *@notice get list of all collaterals in the market.
     *@param user Address of the user whose collateral details are needed.
     *@param markets Array of addresses of the comet market for which the user's collateral details are needed.
     *@return datas array of token addresses supported in the market.
     */
    function getUsedCollateralsList(address user, address[] calldata markets)
        public
        returns (address[][] memory datas)
    {
        uint256 length = markets.length;
        datas = new address[][](length);

        for (uint256 i = 0; i < length; i++) {
            datas[i] = getUsedCollateralList(user, markets[i]);
        }
    }
}

contract InstaCompoundIIIResolver is CompoundIIIResolver {
    string public constant name = "Compound-III-Resolver-v1.0";
}