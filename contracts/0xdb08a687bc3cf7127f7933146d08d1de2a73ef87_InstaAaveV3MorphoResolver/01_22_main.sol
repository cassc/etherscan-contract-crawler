// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./interfaces.sol";
import "./helpers.sol";

/**
 *@title Morpho-Aave Resolver
 *@dev get user position details and market details.
 */
contract MorphoResolver is MorphoHelpers {
    /**
     *@dev get position of the user for all markets entered.
     *@notice get position details of the user in all entered market: overall position data, collaterals, rewards etc.
     *@param user Address of the user whose position details are needed.
     *@return positionData_ Overall position details of the user - balances, rewards, collaterals, market details.
     */
    function getPositionAll(address user) public view returns (UserData memory positionData_) {
        address[] memory userMarkets_ = getUserMarkets();
        positionData_ = getUserData(user, userMarkets_);
    }

    /**
     *@dev get position of the user for given markets.
     *@notice get position details of the user in a market including overall position data, collaterals, rewards etc.
     *@param user Address of the user whose position details are needed.
     *@param userMarkets Array of addresses of the markets for which user details are needed.
     *@return positionData_ Overall position details of the user - balances, rewards, collaterals and market details.
     */
    function getPosition(address user, address[] memory userMarkets)
        public
        view
        returns (UserData memory positionData_)
    {
        uint256 length = userMarkets.length;
        address[] memory _tokens = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            _tokens[i] = userMarkets[i] == getEthAddr() ? getAWethAddr() : userMarkets[i];
        }
        positionData_ = getUserData(user, _tokens);
    }

    /**
     *@dev get Morpho markets config for protocols supported and claim rewards flag.
     *@notice get Morpho markets config for protocols supported and claim rewards flag.
     *@return morphoData_ Struct containing supported protocols' details: markets created,rewards flags.
     */
    function getMorphoConfig() public view returns (MorphoData memory morphoData_) {
        morphoData_ = getMorphoData();
    }

    function getEModeData(uint8 id) public view returns (DataTypes.EModeCategory memory emodeCategoryData) {
        emodeCategoryData = getEmodeCategoryData(id);
    }
}

contract InstaAaveV3MorphoResolver is MorphoResolver {
    string public constant name = "Morpho-Aave-Resolver-v3.0";
}