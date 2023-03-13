// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "../interfaces/IStargateFeeLibrary.sol";
import "../interfaces/IWrapperV05.sol";

contract WrapperV05 {

    IWrapperV05 public stargateFeeLibraryV05;

    constructor(address _stargateFeeLibraryV05){
        stargateFeeLibraryV05 = IWrapperV05(_stargateFeeLibraryV05);
    }

    function shouldCallUpdateTokenPrice(uint _poolId) external view returns (bool){
        IWrapperV05.Price memory price = stargateFeeLibraryV05.poolIdToPrice(_poolId);
        IWrapperV05.PriceDeviationState currentState = price.state;
        (bool isChanged, uint rtnPrice, IWrapperV05.PriceDeviationState newState) = stargateFeeLibraryV05.isTokenPriceChanged(_poolId);
        if (newState != currentState) {
            return true;
        }

        if (newState == IWrapperV05.PriceDeviationState.Drift) {
            return isChanged;
        }

        return false;
    }

    function getPrice(uint _poolId) external view returns (IWrapperV05.Price memory){
        return stargateFeeLibraryV05.poolIdToPrice(_poolId);
    }

}