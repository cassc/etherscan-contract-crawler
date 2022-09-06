// SPDX-License-Identifier: bsl-1.1
/**
 * Copyright 2022 Unit Protocol V2: Artem Zakharov ([email protected]).
 */
pragma solidity ^0.8.0;

import "./interfaces/IParametersStorage.sol";


/**
 * @dev After new parameter is introduced new lib Parameters(n+1) inherited from Parameters(n) must be created
 * @dev Then use Parameters(n+1) for IParametersStorage
 */
library Parameters {

    /// @dev auction duration in seconds
    uint public constant PARAM_AUCTION_DURATION = 0;

    function getAuctionDuration(IParametersStorage _storage) internal view returns (uint _auctionDurationSeconds) {
        _auctionDurationSeconds = uint(_storage.customParams(PARAM_AUCTION_DURATION));
        require(_auctionDurationSeconds > 0);
    }
}