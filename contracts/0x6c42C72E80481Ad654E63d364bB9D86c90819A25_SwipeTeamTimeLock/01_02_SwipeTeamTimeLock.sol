pragma solidity ^0.5.0;

import "./SwipeToken.sol";

// ----------------------------------------------------------------------------

// Swipe Tokens Team Time Lock Contract

// ----------------------------------------------------------------------------

contract SwipeTeamTimeLock is Owned {
    using SafeMath for uint;
    SwipeToken token;
    uint lastCompleteRelease;
    uint restRelease;
    uint constant releasePerMonth = 6 * 10**23; //600k
    
    constructor(address payable addrToken) public {
        token = SwipeToken(addrToken);
        restRelease = 0;
        lastCompleteRelease = now;
    }
    
    function getLockedTokenAmount() public view returns (uint) {
        return token.balanceOf(address(this));
    }
    
    function getAllowedAmount() public view returns (uint) {
        uint amount = restRelease;
        if (now < lastCompleteRelease) return amount;
        
        uint lockedAmount = getLockedTokenAmount();

        uint months = (now - lastCompleteRelease) / (30 days) + 1;
        uint possible = lockedAmount.sub(restRelease).div(releasePerMonth);
        if (possible > months) {
            possible = months;
        }
        amount = amount.add(possible.mul(releasePerMonth));
        return amount;
    }
    
    function withdraw(uint amount) external onlyOwner {
        uint allowedAmount = getAllowedAmount();

        require(allowedAmount >= amount, 'not enough tokens');

        if (token.transfer(msg.sender, amount)) {
            restRelease = allowedAmount.sub(amount);
            while(now > lastCompleteRelease) {
                lastCompleteRelease += 30 days;
            }
        }
    }
    
    // ------------------------------------------------------------------------

    // Don't accept ETH

    // ------------------------------------------------------------------------

    function () external payable {

        revert();

    }
}
