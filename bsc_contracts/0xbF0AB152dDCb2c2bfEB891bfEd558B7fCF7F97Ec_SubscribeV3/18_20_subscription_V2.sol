// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./subscription.sol";

contract SubscribeV2 is Subscribe {
    using SafeMath for uint256;
    struct Tariff {
        uint256 duration;
        uint256 price;
    }

    Tariff[] public tariffs;
    mapping(address => uint8) public userTariff;

    /**
     * @notice Emitted when one of the subscriber properties (isPaused or untilTime) changes
     * @dev If untilTime = 0 subscription is turned off.
     * @param user Address of subscriber. Indexed
     * @param isPaused True if subcriber turn off auto-renewal. Indexed
     * @param untilTime Timestamp of subscription is end (millisecons count)
     * @param tariffId Identifier of tariff
     * @param isTrial True if trial
     */
    event subscriberV2(
        address indexed user,
        bool indexed isPaused,
        uint256 untilTime,
        uint8 tariffId,
        bool isTrial
    );

    function newSubscription(uint8 _tariffId) external {
        User memory _user = users[msg.sender];
        require(_user.untilTime == 0, "Subscriber already exists");
        _user = User(block.timestamp.add(trialDuration), false);
        users[msg.sender] = _user;
        userTariff[msg.sender] = _tariffId;
        emit subscriberV2(msg.sender, false, _user.untilTime, _tariffId, true);
    }

    function newSubscription() external override {
        User memory _user = users[msg.sender];
        require(_user.untilTime == 0, "Subscriber already exists");
        _user = User(block.timestamp.add(trialDuration), false);
        users[msg.sender] = _user;
        userTariff[msg.sender] = 0;
        emit subscriberV2(msg.sender, false, _user.untilTime, 0, true);
    }

    /**
     * @notice Set tariff for user
     * @dev Only for owner
     * @param _user Address of user
     * @param _tariffId Identifier of tariff
     */
    function set_userTariff(address _user, uint8 _tariffId) external onlyOwner {
        userTariff[_user] = _tariffId;
    }

    /**
     * @notice Set new tariff for themself user
     * @param _tariffId Identifier of tariff
     */
    function set_userTariff(uint8 _tariffId) external virtual {
        userTariff[msg.sender] = _tariffId;
    }

    /**
     * @notice Write off by tariff USDT from _addr if subscriber is exists and not paused.
     * Transfer tokens to treasury.
     * @dev Send subscriber and wroteOff events
     * @param _addr Address of subscriber
     */
    function writeOffTariff(address _addr) internal virtual onlyForUser(_addr) {
        User memory _user = users[_addr];
        if (!_user.isPaused && _user.untilTime <= block.timestamp) {
            uint256 allowance = usdt.allowance(_addr, address(this));
            Tariff memory _userTariff = tariffs[userTariff[_addr]];
            if (_userTariff.price <= allowance) {
                usdt.transferFrom(_addr, address(this), _userTariff.price);
                usdt.transfer(treasury, _userTariff.price);
                _user.untilTime = block.timestamp.add(_userTariff.duration);
                users[_addr].untilTime = _user.untilTime;
                emit wroteOff(_addr, _userTariff.price, _user.untilTime);
                emit subscriberV2(
                    _addr,
                    false,
                    _user.untilTime,
                    userTariff[_addr],
                    false
                );
            }
        }
    }

    /**
     * @notice Write off by tariff USDT from list of addresses if subscriber is exists and not paused.
     * Transfer tokens to treasury.
     * @dev Send subscriber and wroteOff events
     * @param _addr Array of subscriber address
     */
    function writeOffArray(address[] calldata _addr) external virtual {
        for (uint256 i; i < _addr.length; i = _unsafe_inc(i)) {
            if (users[_addr[i]].untilTime > 0) {
                writeOffTariff(_addr[i]);
            }
        }
    }

    function writeOffAfterRenewTariff(address _addr) internal virtual {
        User memory _user = users[_addr];
        require(!_user.isPaused, "Subscriber: auto-renewal is stop");
        if (_user.untilTime <= block.timestamp) {
            uint256 allowance = usdt.allowance(_addr, address(this));
            Tariff memory _userTariff = tariffs[userTariff[_addr]];
            require(_userTariff.price <= allowance, "Not enough USDT");
            usdt.transferFrom(_addr, address(this), _userTariff.price);
            usdt.transfer(treasury, _userTariff.price);
            _user.untilTime = block.timestamp.add(_userTariff.duration);
            users[_addr].untilTime = _user.untilTime;
            emit wroteOff(_addr, _userTariff.price, _user.untilTime);
        }
        emit subscriberV2(
            _addr,
            false,
            _user.untilTime,
            userTariff[_addr],
            false
        );
    }

    /**
     * @notice Set false to isPaused property of subscriber with address _addr and
     * try to write off by tariff tokens from the subscriber.
     * @dev Send subscriber and wroteOff events.
     * Only for owner
     * @param _addr Address of subscriber
     */
    function renewSubscriptionTariff(address _addr)
        external
        virtual
        onlyForUser(_addr)
        onlyOwner
    {
        require(users[_addr].isPaused, "User not stop");
        users[_addr].isPaused = false;
        writeOffAfterRenewTariff(_addr);
    }

    function _unsafe_inc(uint256 x) internal pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }

    /**
     * @notice Set tariff for user
     * @dev Only for owner. Tariff[0] must be set duration = subscriptionDuration and price=subscriptionPrice .
     * @dev NB! Index of tariff must be equal to prev data.
     * @param _tariff Address of use
     */
    function set_tariffs(Tariff[] calldata _tariff) external onlyOwner {
        for (uint256 i = 0; i < _tariff.length; i = _unsafe_inc(i)) {
            if (tariffs.length <= i) {
                tariffs.push(Tariff(_tariff[i].duration, _tariff[i].price));
            } else {
                tariffs[i] = Tariff(_tariff[i].duration, _tariff[i].price);
            }
        }

        if (_tariff.length < tariffs.length) {
            for (
                uint256 i = _tariff.length;
                i < tariffs.length;
                i = _unsafe_inc(i)
            ) {
                tariffs[i] = Tariff(0, 0);
            }
        }
    }

    function extendSubscribe(address _addr, uint256 duration)
        external
        override
        onlyOwner
    {
        uint256 _untilTime = users[_addr].untilTime;
        if (_untilTime == 0) {
            _untilTime = block.timestamp.add(duration);
        } else {
            _untilTime = _untilTime.add(duration);
        }
        users[_addr] = User(_untilTime, true);
        emit subscriberV2(_addr, true, _untilTime, userTariff[_addr], true);
    }
}