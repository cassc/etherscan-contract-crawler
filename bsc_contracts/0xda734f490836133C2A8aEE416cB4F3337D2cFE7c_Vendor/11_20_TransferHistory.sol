// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "../security/Administered.sol";

contract TransferHistory is Context, Administered {
    // @dev Event

    // @dev struct for sale limit
    struct SoldOnDay {
        uint256 amount;
        uint256 startOfDay;
    }

    // @dev lock time per wallet
    uint256 public lockTime = 24;

    // @dev struct for buy limit
    struct BuyOnDay {
        uint256 amount;
        uint256 startOfDay;
    }

    // @dev
    uint256 public dayBuyLimit = 100 ether;
    mapping(address => BuyOnDay) public buyInADay;

    // @dev
    uint256 public daySellLimit = 100 ether;
    mapping(address => SoldOnDay) public salesInADay;

    // @dev  Throws if you exceed the Sell limit
    modifier limitSell(uint256 sellAmount) {
        SoldOnDay storage soldOnDay = salesInADay[_msgSender()];
        if (block.timestamp >= soldOnDay.startOfDay + getTimeLock()) {
            soldOnDay.amount = sellAmount;
            soldOnDay.startOfDay = block.timestamp;
        } else {
            soldOnDay.amount += sellAmount;
        }

        require(
            soldOnDay.amount <= daySellLimit,
            "Limit Sell: Exceeded token sell limit"
        );
        _;
    }

    // @dev  Throws if you exceed the Buy limit
    modifier limitBuy(uint256 buyAmount) {
        BuyOnDay storage buyOnDay = buyInADay[_msgSender()];

        if (block.timestamp >= buyOnDay.startOfDay + getTimeLock()) {
            buyOnDay.amount = buyAmount;
            buyOnDay.startOfDay = block.timestamp;
        } else {
            buyOnDay.amount += buyAmount;
        }

        require(
            buyOnDay.amount <= dayBuyLimit,
            "Limit Buy: Exceeded token buy limit"
        );
        _;
    }

    // @dev  get Time Lock
    function getTimeLock() public view returns (uint256) {
        return lockTime * 1 hours;
    }

    // @dev changes to the token sale limit
    function setLockTimePerWallet(uint256 newLimit) external onlyUser {
        lockTime = newLimit;
    }

    // @dev changes to the token sale limit
    function setSellLimit(uint256 newLimit) external onlyUser {
        daySellLimit = newLimit;
    }

    // @dev Token purchase limit changes
    function setBuyLimit(uint256 newLimit) external onlyUser {
        dayBuyLimit = newLimit;
    }
}