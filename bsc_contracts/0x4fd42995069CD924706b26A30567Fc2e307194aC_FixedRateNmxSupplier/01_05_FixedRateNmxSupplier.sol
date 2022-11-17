// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import "./RecoverableByOwner.sol";

contract FixedRateNmxSupplier is RecoverableByOwner {

    address immutable nmx;
    uint128 public nmxPerSecond;
    uint40 public fromTime;

    constructor(address _nmx) {
        nmx = _nmx;
    }

    function updateRate(uint128 _nmxPerSecond) onlyOwner public {
        nmxPerSecond = _nmxPerSecond;
        fromTime = uint40(block.timestamp);
    }

    function supplyNmx(uint40 maxTime) external returns (uint256) {
        uint128 _nmxPerSecond = nmxPerSecond;
        if (_nmxPerSecond == 0) return 0;
        if (uint40(block.timestamp) < maxTime) maxTime = uint40(block.timestamp);
        uint40 _fromTime = fromTime;
        if (_fromTime >= maxTime) return 0;
        uint40 secondsPassed = maxTime - _fromTime;
        uint256 amount = _nmxPerSecond * secondsPassed;
        uint256 balance = IERC20(nmx).balanceOf(address(this));
        if (balance < amount) amount = balance;
        if (amount > 0) {
            bool transferred = IERC20(nmx).transfer(msg.sender, amount);
            require(transferred, "FixedRateNmxSupplier: NMX_FAILED_TRANSFER");
            fromTime = maxTime;
        }
        return amount;
    }

}