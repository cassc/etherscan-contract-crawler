// SPDX-License-Identifier: MIT

// Developed by @SignorCrypto (SignorCrypto.com)
//
//  #####                                 #####
// #     # #  ####  #    #  ####  #####  #     # #####  #   # #####  #####  ####
// #       # #    # ##   # #    # #    # #       #    #  # #  #    #   #   #    #
//  #####  # #      # #  # #    # #    # #       #    #   #   #    #   #   #    #
//       # # #  ### #  # # #    # #####  #       #####    #   #####    #   #    #
// #     # # #    # #   ## #    # #   #  #     # #   #    #   #        #   #    #
//  #####  #  ####  #    #  ####  #    #  #####  #    #   #   #        #    ####

pragma solidity 0.8.11;

contract DutchAuctionSC {
    uint256 private startPrice;
    uint256 private endPrice;
    uint256 private stepTime;
    uint256 private stepPrice;
    uint256 private duration;
    uint256 private startTime;

    constructor(
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _stepTime,
        uint256 _stepPrice
    ) {
        _setDutchAcutionParams(_startPrice, _endPrice, _stepTime, _stepPrice);
    }

    function _setStartTime(uint256 _startTime) internal {
        startTime = _startTime;
    }

    function currentPrice() public view returns (uint256) {
        require(isDutchAuctionStarted(), "Impossible to get the current price");
        uint256 elapsed = block.timestamp - startTime;

        if (elapsed == 0) {
            return startPrice;
        } else if (elapsed < duration) {
            uint256 price = startPrice -
                (elapsed * (startPrice - endPrice)) /
                duration;
            return _roundPrice(price);
        } else {
            return endPrice;
        }
    }

    function _roundPrice(uint256 _price) private view returns (uint256) {
        uint256 result = (_price / stepPrice) + 1;
        return result * stepPrice;
    }

    function _setDutchAcutionParams(
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _stepTime,
        uint256 _stepPrice
    ) internal {
        startPrice = _startPrice;
        endPrice = _endPrice;
        stepTime = _stepTime;
        stepPrice = _stepPrice;

        duration = ((startPrice - endPrice) * stepTime) / stepPrice;
    }

    function isDutchAuctionStarted() public view returns (bool) {
        if (startTime == 0) {
            return false;
        }
        return block.timestamp >= startTime;
    }

    function getDutchAuctionInfo() public view returns (
        uint256 startPrice_, 
        uint256 endPrice_,
        uint256 stepTime_,
        uint256 stepPrice_,
        uint256 duration_,
        uint256 startTime_
    ){
        return (startPrice, endPrice, stepTime, stepPrice, duration, startTime);
    }
}