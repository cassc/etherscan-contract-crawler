// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IUniswapV2Pair.sol";
import "./IWETH.sol";
import "./Chameleon.sol";
import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract ChameleonDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    Chameleon public immutable token;
    IUniswapV2Pair public immutable uniswapV2Pair;
    IWETH public immutable WETH;

    mapping (address => bool) public excludedFromDividends;
    mapping (address => uint256) public lastClaimTimes;

    uint256 public vestingDuration;
    uint256 private vestingDurationUpdateTime;

    uint256 public unvestedDividendsMarketingFee;

    /*
        Users must claim their dividends within 60 days
        of first buy, or previous claim, or the owner
        has the ability to claim for them assuming
        they have forgotten about the token
    */
    uint256 public constant mustClaimDuration = 5184000;

    event ExcludeFromDividends(address indexed account);
    event UpdateeVestingDuration(uint256 vestingDuration);
    event UpdateUnvestedDividendsMarketingFee(uint256 unvestedDividendsMarketingFee);

    event Claim(address indexed account, bool isFromSell, uint256 factor, uint256 amount, uint256 toLiquidity, uint256 toMarketing);

    event ClaimInactive(address indexed account, uint256 amount);

    modifier onlyOwnerOfOwner() {
        require(Ownable(owner()).owner() == _msgSender(), "caller is not the owner's owner");
        _;
    }

    constructor(address payable owner, address pair, address weth) DividendPayingToken("ChameleonDividendTracker", "$CMLN_DIVS") {
        token = Chameleon(owner);
        uniswapV2Pair = IUniswapV2Pair(pair);
        WETH = IWETH(weth);

        updateVestingDuration(259200); //3 days
        updateUnvestedDividendsMarketingFee(25); //25%

        transferOwnership(owner);
    }

    bool private silenceWarning;

    function _transfer(address, address, uint256) internal override {
        silenceWarning = true;
        require(false, "ChameleonDividendTracker: No transfers allowed");
    }

    function excludeFromDividends(address account) external onlyOwner {
        if(excludedFromDividends[account]) {
            return;
        }

    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);

    	emit ExcludeFromDividends(account);
    }

    function updateVestingDuration(uint256 newVestingDuration) public onlyOwner {
        require(newVestingDuration <= 2592000, "ChameleonDividendTracker: max vesting duration is 30 days");

        //If not initial set, then it can only be updated every 24h, and only increasing by 25% if over 1 day
        if(vestingDurationUpdateTime > 0) {
            require(block.timestamp >= vestingDurationUpdateTime + 1 days, "too soon");
            require(
                newVestingDuration <= 1 days ||
                newVestingDuration <= vestingDuration * 125 / 100,
                "too high");
        }

        vestingDuration = newVestingDuration;
        vestingDurationUpdateTime = block.timestamp;
        emit UpdateeVestingDuration(newVestingDuration);
    }

    function updateUnvestedDividendsMarketingFee(uint256 newUnvestedDividendsMarketingFee) public onlyOwner {
        require(newUnvestedDividendsMarketingFee <= 30, "ChameleonDividendTracker: max marketing fee is 30%");

        unvestedDividendsMarketingFee = newUnvestedDividendsMarketingFee;
        emit UpdateUnvestedDividendsMarketingFee(unvestedDividendsMarketingFee);
    }

    function getDividendInfo(address account) external view returns (uint256[] memory dividendInfo) {
        uint256 withdrawableDividends = withdrawableDividendOf(account);
        uint256 totalDividends = accumulativeDividendOf(account);
        uint256 claimFactor = getAccountClaimFactor(account);
        uint256 vestingPeriodStart = lastClaimTimes[account];
        uint256 vestingPeriodEnd = vestingPeriodStart > 0 ? vestingPeriodStart + vestingDuration : 0;

        dividendInfo = new uint256[](5);

        dividendInfo[0] = withdrawableDividends;
        dividendInfo[1] = totalDividends;
        dividendInfo[2] = claimFactor;
        dividendInfo[3] = vestingPeriodStart;
        dividendInfo[4] = vestingPeriodEnd;
    }


    function setBalance(address account, uint256 newBalance) public onlyOwner {
    	if(excludedFromDividends[account]) {
    		return;
    	}

        _setBalance(account, newBalance);

        //Set this so vesting calculations work after the account first
        //interacts with the token
        if(newBalance > 0 && lastClaimTimes[account] == 0) {
            lastClaimTimes[account] = block.timestamp;
        }
    }

    uint256 public constant WITHDRAW_MAX_FACTOR = 10000;

    function getAccountClaimFactor(address account) public view returns (uint256) {
        uint256 lastClaimTime = lastClaimTimes[account];

        if(lastClaimTime == 0) {
            return 0;
        }

        uint256 elapsed = block.timestamp - lastClaimTime;

        uint256 factor;

        if(elapsed >= vestingDuration) {
            factor = WITHDRAW_MAX_FACTOR;
        }
        else {
            factor = WITHDRAW_MAX_FACTOR * elapsed / vestingDuration;
        }

        return factor;
    }

    function claimDividends(address account, address marketingWallet1, address marketingWallet2, bool isFromSell)
        external onlyOwner returns (bool) {
        uint256 withdrawableDividend = withdrawableDividendOf(account);

        if(withdrawableDividend == 0) {
            return false;
        }

        uint256 factor = getAccountClaimFactor(account);

        withdrawnDividends[account] = withdrawnDividends[account].add(withdrawableDividend);
        emit DividendWithdrawn(account, withdrawableDividend);

        uint256 vestedAmount = withdrawableDividend * factor / WITHDRAW_MAX_FACTOR;
        uint256 unvestedAmount = withdrawableDividend - vestedAmount;

        bool success;

        (success,) = account.call{value: vestedAmount}("");
        require(success, "Could not send dividends");

        uint256 toLiquidity = 0;
        uint256 toMarketing = 0;

        //Any unvested dividends are automatically re-added to liquidity and
        //sent to marketing wallet
        if(unvestedAmount > 0) {
            toMarketing = unvestedAmount * unvestedDividendsMarketingFee / 100;
            toLiquidity = unvestedAmount - toMarketing;

            uint256 marketing1 = toMarketing / 2;
            uint256 marketing2 = toMarketing - marketing1;

            if(toMarketing > 0) {
                (success,) = marketingWallet1.call{value: marketing1, gas: 5000}("");
                if(!success) {
                    toLiquidity += marketing1;
                }

                (success,) = marketingWallet2.call{value: marketing2, gas: 5000}("");
                if(!success) {
                    toLiquidity += marketing2;
                }
            }

            WETH.deposit{value: toLiquidity}();
            WETH.transfer(address(uniswapV2Pair), toLiquidity);

            if(!isFromSell) {
                uniswapV2Pair.sync();
            }
        }

        lastClaimTimes[account] = block.timestamp;
        emit Claim(account, isFromSell, factor, vestedAmount, toLiquidity, toMarketing);

        return true;
    }

    function claimInactiveAccountDividends(address account) external onlyOwnerOfOwner returns (bool) {
        uint256 withdrawableDividend = withdrawableDividendOf(account);

        require(withdrawableDividend > 0);
        require(block.timestamp - lastClaimTimes[account] >= mustClaimDuration);

        withdrawnDividends[account] = withdrawnDividends[account].add(withdrawableDividend);
        emit DividendWithdrawn(account, withdrawableDividend);

        (bool success,) = msg.sender.call{value: withdrawableDividend}("");
        require(success, "Could not send dividends");

        lastClaimTimes[account] = block.timestamp;
        emit ClaimInactive(account, withdrawableDividend);

        return true;
    }
}