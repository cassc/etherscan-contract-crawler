// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Vesting is Ownable, ReentrancyGuard {

    using SafeMath for uint;

    uint public constant NUMBER_OF_EPOCHS = 125;
    uint public constant EPOCH_DURATION = 604800; // 1 week duration
    IERC20 private _stakeborgToken;

    uint public lastClaimedEpoch;
    uint private _startTime;
    uint public totalDistributedBalance;

    constructor(address newOwner, address stakeborgTokenAddress, uint startTime, uint totalBalance) public {
        transferOwnership(newOwner);
        _stakeborgToken = IERC20(stakeborgTokenAddress);
        _startTime = startTime;
        totalDistributedBalance = totalBalance;
    }

    function claim () public virtual nonReentrant {
        claimInternal(owner());
    }

    function claimInternal (address to) internal {
        uint balance;
        uint currentEpoch = getCurrentEpoch();
        if (currentEpoch > NUMBER_OF_EPOCHS + 1) {
            lastClaimedEpoch = NUMBER_OF_EPOCHS;
            _stakeborgToken.transfer(to, _stakeborgToken.balanceOf(address (this)));
            return;
        }

        if (currentEpoch > lastClaimedEpoch) {
            balance = (currentEpoch - 1  - lastClaimedEpoch) * totalDistributedBalance / NUMBER_OF_EPOCHS;
        }
        lastClaimedEpoch = currentEpoch - 1;
        if (balance > 0) {
            _stakeborgToken.transfer(to, balance);
        }
    }

    function balance () public view returns (uint){
        return _stakeborgToken.balanceOf(address (this));
    }

    function getCurrentEpoch () public view returns (uint){
        if (block.timestamp < _startTime) return 0;
        return (block.timestamp - _startTime) / EPOCH_DURATION + 1;
    }
    // default
    fallback() external { claim(); }
}