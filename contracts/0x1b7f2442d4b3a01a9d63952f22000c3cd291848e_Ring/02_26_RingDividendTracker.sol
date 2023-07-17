// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IUniswapV2Pair.sol";
import "./IWETH.sol";
import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./Ring.sol";

contract RingDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    Ring public immutable token;

    mapping (address => bool) public excludedFromDividends;

    event ExcludeFromDividends(address indexed account);

    constructor(address payable owner) DividendPayingToken("RingDividendTracker", "$RING_DIV") {
        token = Ring(owner);
        transferOwnership(owner);
    }

    bool private silenceWarning;

    function _transfer(address, address, uint256) internal override {
        silenceWarning = true;
        require(false, "RingDividendTracker: No transfers allowed");
    }

    function excludeFromDividends(address account) external onlyOwner {
        if(excludedFromDividends[account]) {
            return;
        }

    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);

    	emit ExcludeFromDividends(account);
    }

    function getDividendInfo(address account) external view returns (uint256[] memory dividendInfo) {
        uint256 withdrawableDividends = withdrawableDividendOf(account);
        uint256 totalDividends = accumulativeDividendOf(account);

        dividendInfo = new uint256[](4);

        dividendInfo[0] = withdrawableDividends;
        dividendInfo[1] = totalDividends;

        uint256 balance = balanceOf(account);
        dividendInfo[2] = balance;
        uint256 totalSupply = totalSupply();
        dividendInfo[3] = totalSupply > 0 ? balance * 1000000 / totalSupply : 0;
    }


    function increaseBalance(address account, uint256 increase) public onlyOwner {
    	if(excludedFromDividends[account]) {
    		return;
    	}

        uint256 newBalance = balanceOf(account) + increase;

        _setBalance(account, newBalance);
    }


    function claimDividends(address account, bool enterTheRing, uint256 minimumAmountOut)
        external onlyOwner returns (bool) {
        uint256 withdrawableDividend = withdrawableDividendOf(account);

        if(withdrawableDividend == 0) {
            return false;
        }

        withdrawnDividends[account] = withdrawnDividends[account].add(withdrawableDividend);
        emit DividendWithdrawn(account, withdrawableDividend);

        bool success;

        if(!enterTheRing) {
            (success,) = account.call{value: withdrawableDividend}("");
            require(success, "Could not send dividends");
        }
        else {
            token.zapInTheWellEther{value: withdrawableDividend}(account, minimumAmountOut);
        }

        return true;
    }
}