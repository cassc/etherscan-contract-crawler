// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IFundStructs.sol";
import "@artman325/whitelist/contracts/interfaces/IWhitelist.sol";

interface IFundContractAggregator is IFundStructs {
     /**
     * @param _sellingToken address of ITR token
     * @param _token0 USD Coin
     * @param _token1 Wrapped token (WETH,WBNB,...)
     * @param _timestamps array of timestamps
     * @param _prices price exchange
     * @param _endTime after this time exchange stop
     * @param _thresholds thresholds
     * @param _bonuses bonuses
     * @param _ownerCanWithdraw enum option where:
     *  0 -owner can not withdraw tokens
     *  1 -owner can withdraw tokens only after endTimePassed
     *  2 -owner can withdraw tokens anytime
     * @param _whitelistData whitelist data struct
     *  address contractAddress;
	 *	bytes4 method;
	 *	uint8 role;
     *  bool useWhitelist;
     * @param _costManager costmanager address
     */
     function init(
        address _sellingToken,
        address _token0,
        address _token1,
        uint64[] memory _timestamps,
        uint256[] memory _prices,
        uint64 _endTime,
        uint256[] memory _thresholds,
        uint256[] memory _bonuses,
        EnumWithdraw _ownerCanWithdraw,
        IWhitelist.WhitelistStruct memory _whitelistData,
        address _costManager,
        address _producedBy
    ) external;
}