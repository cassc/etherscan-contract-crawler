// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;
import "../interfaces/IPendleData.sol";

abstract contract PendleRouterNonReentrant {
    uint8 internal _guardCounter;

    modifier nonReentrant() {
        _checkNonReentrancy(); // use functions to reduce bytecode size
        _;
        _guardCounter--;
    }

    constructor() {
        _guardCounter = 1;
    }

    /**
    * We allow markets to make at most ONE Reentrant call
    in the case of redeemLpInterests
    * The flow of redeemLpInterests will be: Router.redeemLpInterests -> market.redeemLpInterests
    -> Router.redeemDueInterests (so there is at most ONE Reentrant call)
    */
    function _checkNonReentrancy() internal {
        if (_getData().isMarket(msg.sender)) {
            require(_guardCounter <= 2, "REENTRANT_CALL");
        } else {
            require(_guardCounter == 1, "REENTRANT_CALL");
        }
        _guardCounter++;
    }

    function _getData() internal view virtual returns (IPendleData);
}