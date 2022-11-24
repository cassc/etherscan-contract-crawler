// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IUniswapV2Pair.sol";
import "./IWETH.sol";
import "./DividendDelayedPayingToken.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./Ocfi.sol";
import "./OcfiDividendTrackerBalanceCalculator.sol";
import "./IUniswapV2Router.sol";

contract OcfiDividendTracker is DividendDelayedPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    Ocfi public immutable token;
    OcfiDividendTrackerBalanceCalculator public balanceCalculator;

    mapping (address => bool) public excludedFromDividends;
    mapping (address => uint256) public lastClaimTimes;

    event OcfiDividendTrackerBalanceCalculatorUpdated(address balanceCalculator);
    event ExcludeFromDividends(address indexed account);

    event Claim(address indexed account, uint256 amount);
    event Reinvest(address indexed account, uint256 amount);

    event ClaimInactive(address indexed account, uint256 amount);

    modifier onlyToken() {
        require(address(token) == _msgSender(), "caller is not the token");
        _;
    }

    constructor(address payable _token) DividendDelayedPayingToken("OcfiDividendTracker", "$OCFI_DIVS") {
        token = Ocfi(_token);
    }

    function updateBalanceCalculator(address _balanceCalculator) external onlyOwner {
        balanceCalculator = OcfiDividendTrackerBalanceCalculator(_balanceCalculator);

        balanceCalculator.calculateBalance(address(0x0));

        emit OcfiDividendTrackerBalanceCalculatorUpdated(_balanceCalculator);
    }
    
    bool private silenceWarning;

    function _transfer(address, address, uint256) internal override {
        silenceWarning = true;
        require(false, "OcfiDividendTracker: No transfers allowed");
    }

    function excludeFromDividends(address account) external onlyToken {
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

        dividendInfo = new uint256[](6);

        dividendInfo[0] = withdrawableDividends;
        dividendInfo[1] = totalDividends;

        uint256 balance = balanceOf(account);
        dividendInfo[2] = balance;
        uint256 totalSupply = totalSupply();
        dividendInfo[3] = totalSupply > 0 ? balance * 1000000 / totalSupply : 0;
        dividendInfo[4] = lastClaimTimes[account];
        dividendInfo[5] = delayedDividends;
    }

    function updateAccountBalance(address account) public {
        if(excludedFromDividends[account]) {
    		return;
    	}

        uint256 newBalance;

        if(address(balanceCalculator) != address(0x0)) {            
            try balanceCalculator.calculateBalance(account) returns (uint256 result) {
                newBalance = result;
            } catch {
                newBalance = token.balanceOf(account);
            }
        }
        else {
            newBalance = token.balanceOf(account);
        }

        _setBalance(account, newBalance);

        if(newBalance > 0 && lastClaimTimes[account] == 0) {
            lastClaimTimes[account] = block.timestamp;
        }
    }


    function claimDividends(address account, bool reinvest)
        external onlyToken returns (bool) {
        uint256 withdrawableDividend = withdrawableDividendOf(account);

        if(withdrawableDividend == 0) {
            return false;
        }

        withdrawnDividends[account] = withdrawnDividends[account].add(withdrawableDividend);
        emit DividendWithdrawn(account, withdrawableDividend);

        lastClaimTimes[account] = block.timestamp;

        bool success;

        if(!reinvest) {
            (success,) = account.call{value: withdrawableDividend}("");
            require(success, "Could not send dividends");

            emit Claim(account, withdrawableDividend);
        } else {
            token.reinvestDividends{value: withdrawableDividend}(account);

            emit Reinvest(account, withdrawableDividend);
        }

        return true;
    }

    function claimInactiveAccountsDividends(address[] memory accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            claimInactiveAccountDividends(accounts[i]);
        }
    }

    function claimInactiveAccountDividends(address account) public onlyOwner {
        uint256 withdrawableDividend = withdrawableDividendOf(account);

        if(withdrawableDividend == 0) {
            return;
        }

        require(block.timestamp - lastClaimTimes[account] >= 180 days);

        withdrawnDividends[account] = withdrawnDividends[account].add(withdrawableDividend);
        emit DividendWithdrawn(account, withdrawableDividend);

        (bool success,) = msg.sender.call{value: withdrawableDividend}("");
        require(success, "Could not send dividends");

        lastClaimTimes[account] = block.timestamp;
        emit ClaimInactive(account, withdrawableDividend);
    }

    function withdrawTokens(uint256 amount) external onlyOwner {
        if(amount == 0) {
            amount = token.balanceOf(address(this));
        }

        token.transfer(owner(), amount);
    }
}