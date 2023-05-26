// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Vesting is Ownable, ReentrancyGuard {

    uint public constant NUMBER_OF_EPOCHS = 100;
    uint public constant EPOCH_DURATION = 604800; // 1 week duration
    IERC20 private _xyz;

    uint public lastClaimedEpoch;
    uint private _startTime;
    uint public totalDistributedBalance;

    constructor(address newOwner, address xyzTokenAddress, uint startTime, uint totalBalance) {
        transferOwnership(newOwner);
        _xyz = IERC20(xyzTokenAddress);
        _startTime = startTime;
        totalDistributedBalance = totalBalance;
    }

    function claim () public nonReentrant {
        uint balanceToClaim;
        uint currentEpoch = getCurrentEpoch();
        if (currentEpoch > NUMBER_OF_EPOCHS + 1) {
            lastClaimedEpoch = NUMBER_OF_EPOCHS;
            _xyz.transfer(owner(), _xyz.balanceOf(address (this)));
            return;
        }

        if (currentEpoch > lastClaimedEpoch) {
            balanceToClaim = (currentEpoch - 1  - lastClaimedEpoch) * totalDistributedBalance / NUMBER_OF_EPOCHS;
        }
        lastClaimedEpoch = currentEpoch - 1;
        if (balanceToClaim > 0) {
            _xyz.transfer(owner(), balanceToClaim);
        }
    }

    function balance () public view returns (uint){
        return _xyz.balanceOf(address(this));
    }

    function getCurrentEpoch () public view returns (uint){
        if (block.timestamp < _startTime) return 0;
        return (block.timestamp - _startTime) / EPOCH_DURATION + 1;
    }
    // default
    fallback() external { claim(); }
}