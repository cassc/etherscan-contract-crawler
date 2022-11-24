// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ocfi.sol";
import "./OcfiClaim.sol";

import "./IOcfiDividendTrackerBalanceCalculator.sol";

contract OcfiDividendTrackerBalanceCalculator is IOcfiDividendTrackerBalanceCalculator, Ownable {
    Ocfi public immutable token;
    OcfiClaim public immutable claim;

    constructor(address payable _token, address payable _claim) {
        token = Ocfi(_token);
        claim = OcfiClaim(_claim);
    }

    function calculateBalance(address account) external override view returns (uint256) {
        if(account == address(0)) {
            return 0;
        }
        
        return token.balanceOf(account) + claim.getTotalClaimRemaining(account);
    }
}