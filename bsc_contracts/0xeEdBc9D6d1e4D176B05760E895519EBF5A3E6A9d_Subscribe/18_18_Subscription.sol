// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../common/ACBase.sol";
import "../common/ISubscribers.sol";
import "../common/BaseProxy.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Subscriptions
 * @notice Accounting for subscriptions for users who want to bill
 * @dev Using on Invoices contract
 */
contract Subscribe is BaseProxy, ISubscribers {
    using SafeMath for uint256;
    struct User {
        uint256 untilTime;
        bool isPaused;
    }

    mapping(address => User) public users;

    uint256 public subscriptionPrice;
    uint256 public subscriptionDuration;
    uint256 public paymentDelta;
    uint256 public trialDuration;

    IERC20 usdt;

    /**
     * @notice Emitted when one of the subscriber properties (isPaused or untilTime) changes
     * @dev If untilTime = 0 subscription is turned off.
     * @param user Address of subscriber. Indexed
     * @param isPaused True if subcriber turn off auto-renewal. Indexed
     * @param untilTime Timestamp of subscription is end (millisecons count)
     */
    event subscriber(
        address indexed user,
        bool indexed isPaused,
        uint256 untilTime
    );
    /**
     * @notice Emitted when a subscriber is charged
     * @param user Address of subscriber. Indexed
     * @param amount Number of USDT written off
     * @param untilTime New timestamp of subscription is end (millisecons count)
     */
    event wroteOff(address indexed user, uint256 amount, uint256 untilTime);

    modifier onlyForUser(address _addr) {
        require(users[_addr].untilTime > 0, "User not exists");
        _;
    }

    address public treasury;

    function initialize(
        address _usdt,
        uint256 _subscriptionPrice,
        uint256 _subscriptionDuration,
        uint256 _paymentDelta,
        uint256 _trialDuration,
        address _treasury
    ) public initializer {
        usdt = IERC20(_usdt);
        subscriptionPrice = _subscriptionPrice;
        subscriptionDuration = _subscriptionDuration;
        paymentDelta = _paymentDelta;
        trialDuration = _trialDuration;
        treasury = _treasury;

        __Ownable_init();
    }

    function set_treasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    /**
     * @notice Set true to isPaused property of subscriber with address _addr.
     * It will not be possible to call Write off function for this subscriber.
     * @dev Send subscriber event.
     * Only for owner
     * @param _addr Address of subscriber
     */
    function cancelSubscription(
        address _addr
    ) external onlyForUser(_addr) onlyOwner {
        User memory _user = users[_addr];
        require(!_user.isPaused, "Subscriber: auto-renewal already stop");
        users[_addr].isPaused = true;
        emit subscriber(_addr, true, _user.untilTime);
    }

    /**
     * @notice Set true to isPaused property of subscriber with sender's address.
     * It will not be possible to call Write off function for this subscriber.
     * @dev Send subscriber event
     */
    function cancelSubscription() external onlyForUser(msg.sender) {
        User memory _user = users[msg.sender];
        require(!_user.isPaused, "Subscriber: auto-renewal already stop");
        users[msg.sender].isPaused = true;
        emit subscriber(msg.sender, true, _user.untilTime);
    }

    /**
     * @notice Write off USDT from _addr if subscriber is exists and not paused
     * Transfer tokens to treasury.
     * @dev Send subscriber and wroteOff events
     * @param _addr Address of subscriber
     */
    function writeOff(address _addr) external onlyForUser(_addr) {
        User memory _user = users[_addr];
        require(!_user.isPaused, "User is paused");
        require(
            _user.untilTime <= block.timestamp,
            "Subscription is still active"
        );
        uint256 allowance = usdt.allowance(_addr, address(this));
        require(subscriptionPrice <= allowance, "Not enough USDT");
        usdt.transferFrom(_addr, address(this), subscriptionPrice);
        usdt.transfer(treasury, subscriptionPrice);
        _user.untilTime = block.timestamp.add(subscriptionDuration);
        users[_addr].untilTime = _user.untilTime;
        emit wroteOff(_addr, subscriptionPrice, _user.untilTime);
        emit subscriber(_addr, false, _user.untilTime);
    }

    function writeOffAfterRenew(address _addr) internal {
        User memory _user = users[_addr];
        require(!_user.isPaused, "Subscriber: auto-renewal is stop");
        if (_user.untilTime <= block.timestamp) {
            uint256 allowance = usdt.allowance(_addr, address(this));
            require(subscriptionPrice <= allowance, "Not enough USDT");
            usdt.transferFrom(_addr, address(this), subscriptionPrice);
            usdt.transfer(treasury, subscriptionPrice);
            _user.untilTime = block.timestamp.add(subscriptionDuration);
            users[_addr].untilTime = _user.untilTime;
            emit wroteOff(_addr, subscriptionPrice, _user.untilTime);
        }
        emit subscriber(_addr, false, _user.untilTime);
    }

    /**
     * @notice Set false to isPaused property of subscriber with sender's address and
     * try to write off tokens from the subscriber.
     * @dev Send subscriber and wroteOff events
     */
    function renewSubscription() external onlyForUser(msg.sender) {
        require(
            users[msg.sender].isPaused,
            "Subscriber: auto-renewal already active"
        );
        users[msg.sender].isPaused = false;
        writeOffAfterRenew(msg.sender);
    }

    /**
     * @notice Set false to isPaused property of subscriber with address _addr and
     * try to write off tokens from the subscriber.
     * @dev Send subscriber and wroteOff events.
     * Only for owner
     * @param _addr Address of subscriber
     */
    function renewSubscription(
        address _addr
    ) external onlyForUser(_addr) onlyOwner {
        require(users[_addr].isPaused, "User not stop");
        users[_addr].isPaused = false;
        writeOffAfterRenew(_addr);
    }

    /**
     * @notice Check subscription status
     * @dev from interface ISubscribers
     * @param _addr Address of subscriber
     * @return User with _addr subscription status
     */
    function isSubscribed(address _addr) external view returns (bool) {
        if (users[_addr].untilTime.add(paymentDelta) >= block.timestamp) {
            return true;
        }
        return false;
    }

    /**
     * @notice Add new subscriber with trial period
     * @dev Send subscriber event
     */
    function newSubscription() external {
        User memory _user = users[msg.sender];
        require(_user.untilTime == 0, "Subcsriber already exists");
        _user = User(block.timestamp.add(trialDuration), false);
        users[msg.sender] = _user;
        emit subscriber(msg.sender, false, _user.untilTime);
    }

    /**
     * @notice Set trial duration
     * @dev Only for owner
     * @param _trialDuration Count of milliseconds
     */
    function set_trial(uint256 _trialDuration) external onlyOwner {
        trialDuration = _trialDuration;
    }

    /**
     * @notice Set price for subscription
     * @dev Only for owner
     * @param _subscriptionPrice USDT format
     */
    function set_subscriptionPrice(
        uint256 _subscriptionPrice
    ) external onlyOwner {
        subscriptionPrice = _subscriptionPrice;
    }

    /**
     * @notice Set subscription duration
     * @dev Only for owner
     * @param _subscriptionDuration Count of milliseconds
     */
    function set_subscriptionDuration(
        uint256 _subscriptionDuration
    ) external onlyOwner {
        subscriptionDuration = _subscriptionDuration;
    }

    /**
     * @notice Set period for runner duration
     * @dev Only for owner
     * @param _paymentDelta Count of milliseconds
     */
    function set_paymentDelta(uint256 _paymentDelta) external onlyOwner {
        paymentDelta = _paymentDelta;
    }

    /**
     * @notice Set new values for 4 proprties of the contract
     * @dev Only for owner
     * @param _subscriptionPrice USDT format
     * @param _subscriptionDuration Count of milliseconds
     * @param _paymentDelta Count of milliseconds
     * @param _trialDuration Count of milliseconds
     */
    function set_subscriptionOptions(
        uint256 _subscriptionPrice,
        uint256 _subscriptionDuration,
        uint256 _paymentDelta,
        uint256 _trialDuration
    ) external onlyOwner {
        subscriptionPrice = _subscriptionPrice;
        subscriptionDuration = _subscriptionDuration;
        paymentDelta = _paymentDelta;
        trialDuration = _trialDuration;
    }

    /**
     * @notice Add new subscriber with custom period. isPaused - true.
     * @dev Only for owner. Send subscriber event
     * @param _addr Address of subscriber
     * @param duration Count of milliseconds. Added to current timestamp
     */
    function addFreeSubs(address _addr, uint256 duration) external onlyOwner {
        require(users[_addr].untilTime == 0, "Subscriber already exists");
        users[_addr] = User(block.timestamp.add(duration), true);
        emit subscriber(_addr, true, users[_addr].untilTime);
    }

    /**
     * @notice Add custom period to exists subscriber and untilTime increases to duration.
     * Or create new subscriber with untilTime  - curremt time plus duration. isPaused - true.
     * @dev Only for owner. Send subscriber event
     * @param _addr Address of subscriber
     * @param duration Count of milliseconds.
     */
    function extendSubscribe(
        address _addr,
        uint256 duration
    ) external onlyOwner {
        uint256 _untilTime = users[_addr].untilTime;
        if (_untilTime == 0) {
            _untilTime = block.timestamp.add(duration);
        } else {
            _untilTime = _untilTime.add(duration);
        }
        users[_addr] = User(_untilTime, true);
        emit subscriber(_addr, true, _untilTime);
    }
}