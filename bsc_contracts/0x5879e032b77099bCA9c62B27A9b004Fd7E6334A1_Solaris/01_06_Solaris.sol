// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Solaris is ERC20, Ownable {

    uint256 private initialSupply = 100_000_000_000 * (10 ** 18);

    uint256 public constant taxLimit = 10;
    uint256 public taxSell = 10;

    uint256 public maxRewardLimit;
    uint256 public prevRewardPeriodStart;
    uint256 public prevRewardLimit;
    uint256 public prevRewardTotal;
    uint256 public prevRewardClaimed;

    uint256 public nextRewardPeriodStart;
    uint256 public nextRewardLimit;
    uint256 public nextRewardTotal;
    
    uint256 private constant denominator = 100;

    mapping(address => bool) public sniperList;
    uint256 private sniperTaxSell = 10;
    uint256 private sniperTaxBuy = 10;
    
    mapping(address => bool) public excludedList;

    address public tokenPairAddr;
    address public appAddr;
    address public rewardPoolAddr;


    event Rewarded(address indexed player, uint256 appTokens, uint256 realTokens);
    event AppScoreAdded(address indexed player, uint256 appTokens);

    constructor() ERC20("Solaris Betting Token", "SBT")
    {
        exclude(msg.sender);
        exclude(address(this));
        _mint(msg.sender, initialSupply);
        maxRewardLimit = initialSupply / 100;
    }

    receive() external payable {}

    function checkRewardPeriod(uint256 periodStart) private {
        if (periodStart > nextRewardPeriodStart) {
            (prevRewardPeriodStart, nextRewardPeriodStart) = (nextRewardPeriodStart, periodStart);
            prevRewardTotal = nextRewardTotal;
            prevRewardClaimed = 0;
            nextRewardTotal = 0;
            if (nextRewardLimit < 1) {
                nextRewardLimit = prevRewardLimit;
            }
        }
    }

    function setRewardLimit(uint256 _rewardLimit) external onlyOwner {
        require(_rewardLimit <= maxRewardLimit);
        uint256 dayStart = (block.timestamp / 86400) * 86400;
        require(block.timestamp > dayStart && block.timestamp < dayStart + 3600);
        checkRewardPeriod(dayStart);
        prevRewardLimit = _rewardLimit;
    }

    function addEntireReward(uint256 _appScore, address _addr) external {
        require(appAddr == msg.sender);
        uint256 periodStart = (block.timestamp / 86400) * 86400;
        checkRewardPeriod(periodStart);
        nextRewardTotal += _appScore;
        emit AppScoreAdded(_addr, _appScore);
    }

    function getReward(uint256 _appScore, address _addr) external returns (uint256) {
        require(appAddr == msg.sender);
        uint256 periodStart = (block.timestamp / 86400) * 86400;
        require(periodStart + 3600 <= block.timestamp, "Reward time starts at 1:00 AM UTC");
        checkRewardPeriod(periodStart);
        require(prevRewardTotal - prevRewardClaimed >= _appScore);
        require(balanceOf(address(this)) > 0 && _appScore > 0);
        uint256 paySum = (((prevRewardLimit * 1000) / prevRewardTotal) * _appScore) / 1000;
        _transfer(address(this), _addr, paySum);
        prevRewardClaimed += _appScore;
        emit Rewarded(_addr, paySum, _appScore);
        return paySum;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override virtual {

        if (isExcluded(sender) || isExcluded(recipient) || recipient == rewardPoolAddr) {
            super._transfer(sender, recipient, amount);
            return;
        }

        uint256 baseUnit = amount / denominator;
        uint256 tax = 0;

        if (isSniper(sender) || isSniper(recipient)) {
            if (sender == tokenPairAddr) {
                tax = baseUnit * sniperTaxBuy;
            } else {
                tax = baseUnit * sniperTaxSell;
            }
        } else if (recipient == tokenPairAddr) {
            tax = baseUnit * taxSell;
        }

        if (tax > 0) {
            _transfer(sender, rewardPoolAddr, tax);
        }

        amount -= tax;

        super._transfer(sender, recipient, amount);
    }

    function setTax(uint256 _sell) public onlyOwner {
        require(_sell <= taxLimit, "ERC20: sell tax higher than tax limit");
        taxSell = _sell;
    }

    function setSniperTax(uint256 _buy, uint256 _sell) public onlyOwner {
        require(_buy <= 100 && _sell <= 100, "ERC20: sniper tax higher than tax limit");
        sniperTaxBuy = _buy;
        sniperTaxSell = _sell;
    }

    function setApp(address _addr) external onlyOwner {
        appAddr = _addr;
    }

    function setRewardPool(address _addr) external onlyOwner {
        rewardPoolAddr = _addr;
    }

    function setTokenPair(address _addr) external onlyOwner {
        tokenPairAddr = _addr;
    }

    function exclude(address account) public onlyOwner {
        require(!isExcluded(account), "ERC20: Account is already excluded");
        excludedList[account] = true;
    }

    function deleteExcluded(address account) public onlyOwner {
        require(isExcluded(account), "ERC20: Account is not excluded");
        excludedList[account] = false;
    }

    function sniper(address account) public onlyOwner {
        require(!isSniper(account), "ERC20: Account is already marked as sniper");
        sniperList[account] = true;
    }

    function deleteSniper(address account) public onlyOwner {
        require(isSniper(account), "ERC20: Account is not sniper");
        sniperList[account] = false;
    }

    function isExcluded(address account) public view returns (bool) {
        return excludedList[account];
    }

    function isSniper(address account) public view returns (bool) {
        return sniperList[account];
    }
}