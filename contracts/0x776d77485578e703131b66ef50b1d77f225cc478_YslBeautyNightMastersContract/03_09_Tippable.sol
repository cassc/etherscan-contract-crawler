// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Teams.sol";

abstract contract Tippable is Teams {
    bool public strictPricing = true;

    function setStrictPricing(bool _newStatus) public onlyTeamOrOwner {
        strictPricing = _newStatus;
    }

    // @dev check if msg.value is correct according to pricing enforcement
    // @param _msgValue -> passed in msg.value of tx
    // @param _expectedPrice -> result of getPrice(...args)
    function priceIsRight(uint256 _msgValue, uint256 _expectedPrice) internal view returns (bool) {
        return strictPricing ? _msgValue == _expectedPrice : _msgValue >= _expectedPrice;
    }
}