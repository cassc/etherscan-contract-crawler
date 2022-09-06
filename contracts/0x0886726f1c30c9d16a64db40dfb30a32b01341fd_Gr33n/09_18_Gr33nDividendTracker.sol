// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract Gr33nDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private tokenHoldersCount;
    mapping(address => bool) private tokenHoldersMap;

    mapping(address => bool) public excludedFromDividends;

    mapping(address => bool) public brokeOutOfGreenWall;

    mapping(address => uint256) public lastDateClaimed;

    bool public greenWallEnded = false;
    uint256 public greenWallEndedTimestamp;

    event ExcludeFromDividends(address indexed account);
    event ClaimInactive(address indexed account, uint256 amount);


    constructor() DividendPayingToken("Gr33n_Dividend_Tracker","Gr33n_Dividend_Tracker") {
    }

    function _approve(address, address, uint256) internal pure override {
        require(false, "Gr33n_Dividend_Tracker: No approvals allowed");
    }

    function _transfer(address, address, uint256) internal pure override {
        require(false, "Gr33n_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(false,
            "Gr33n_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main Gr33n contract."
        );
    }

    function excludeFromDividends(address account) external onlyOwner {
        excludedFromDividends[account] = true;

        _setBalance(account, 0);

        if (tokenHoldersMap[account] == true) {
            tokenHoldersMap[account] = false;
            tokenHoldersCount.decrement();
        }

        emit ExcludeFromDividends(account);
    }

    function includeFromDividends(address account, uint256 balance) external onlyOwner {
        excludedFromDividends[account] = false;

        _setBalance(account, balance);

        if (tokenHoldersMap[account] == false) {
            tokenHoldersMap[account] = true;
            tokenHoldersCount.increment();
        }
        

        emit ExcludeFromDividends(account);
    }

    function isExcludeFromDividends(address account) external view onlyOwner returns (bool) {
        return excludedFromDividends[account];
    }

    function _brokeOutOfGreenWall(address account, bool brokeOut) external onlyOwner {
        brokeOutOfGreenWall[account] = brokeOut;
    }

    function isBrokeOutOfGreenWall(address account) external view onlyOwner returns (bool) {
        return brokeOutOfGreenWall[account];
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersCount.current();
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
        if (excludedFromDividends[account]) {
            return;
        }

        _setBalance(account, newBalance);

        if (tokenHoldersMap[account] == false) {
            tokenHoldersMap[account] = true;
            tokenHoldersCount.increment();
        }
    }

    function setGreenWallEnded() external onlyOwner {
        greenWallEnded = true;
        greenWallEndedTimestamp = block.timestamp;
    }

    function processAccount(address account, address toAccount) public onlyOwner returns (uint256) {
        uint256 amount = _withdrawDividendOfUser(
            payable(account),
            payable(toAccount)
        );

        lastDateClaimed[account] = block.timestamp;

        return amount;
    }

}