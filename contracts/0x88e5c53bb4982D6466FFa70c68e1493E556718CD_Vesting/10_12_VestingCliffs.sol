// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract VestingCliffs is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct Cliff {
        uint256 ClaimablePercentage;
        uint256 RequiredTime;
    }

    Cliff[] public cliffs;
    uint256 public numCliffs;

    IERC20 private token;

    uint256 public lastClaimedCliff;
    uint256 public startTime;
    uint256 public totalAmount;

    constructor(address newOwner, address tokenAddr, uint256 _startTime, uint256 _totalAmount) public {
        transferOwnership(newOwner);

        token = IERC20(tokenAddr);
        startTime = _startTime;
        totalAmount = _totalAmount;

        // add an empty cliff 0 because the 0-value of `lastClaimedCliff` will be 0
        cliffs.push(Cliff(0, 0));
        cliffs.push(Cliff(10, 30 days));
        cliffs.push(Cliff(30, 120 days));
        cliffs.push(Cliff(30, 270 days));
        cliffs.push(Cliff(30, 450 days));
        numCliffs = cliffs.length;
    }

    function claim() public virtual nonReentrant {
        claimInternal(owner());
    }

    function claimInternal(address to) internal {
        uint256 amount;

        while (true) {
            uint256 nextCliff = lastClaimedCliff + 1;

            // break if no more cliffs left
            if (nextCliff >= cliffs.length) {
                break;
            }

            // break if all valid cliffs were processed
            if (timePassed() < cliffs[nextCliff].RequiredTime) {
                break;
            }

            // if we reached last cliff, transfer all the balance (including any leftover dust)
            if (nextCliff == cliffs.length - 1) {
                amount = balance();
                lastClaimedCliff = nextCliff;

                break;
            }

            amount = amount + totalAmount * cliffs[nextCliff].ClaimablePercentage / 100;
            lastClaimedCliff = nextCliff;
        }

        require(amount > 0, "nothing to claim");

        token.transfer(to, amount);
    }

    function timePassed() public view returns (uint256) {
        if (block.timestamp < startTime) {
            return 0;
        }

        return block.timestamp - startTime;
    }

    function balance() public view returns (uint){
        return token.balanceOf(address(this));
    }

    // default
    fallback() external {claim();}
}