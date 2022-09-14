// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract SlippageManager is Ownable {

    uint constant public DEFAULT_SLIPPAGE_NUMERATOR = 9500;
    uint constant public DEFAULT_SLIPPAGE_DENOMINATOR = 10000;

    uint[2] slippage;

    event SlippageUpdate(address indexed updater, uint slippageNumerator);
    event OwnerOperation(address indexed invoker, string method);

    constructor() public {
        slippage = [DEFAULT_SLIPPAGE_NUMERATOR, DEFAULT_SLIPPAGE_DENOMINATOR];
    }

    function setSlippage(uint _slippageNumerator) external onlyOwner {
        require(_slippageNumerator <= DEFAULT_SLIPPAGE_DENOMINATOR, "_slippageNumerator>DEFAULT_SLIPPAGE_DENOMINATOR");
        slippage[0] = _slippageNumerator;

        emit SlippageUpdate(msg.sender, _slippageNumerator);
        emit OwnerOperation(msg.sender, "SlippageManager.setSlippage");
    }
}