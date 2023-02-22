// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./subscription_V2.sol";

contract SubscribeV3 is SubscribeV2 {
    using SafeMath for uint256;

    /**
     * @notice Write off by tariff USDT from _addr if subscriber is exists and not paused.
     * Transfer tokens to treasury.
     * @dev Send subscriber and wroteOff events
     * @param _addr Address of subscriber
     */
    function writeOffTariff(address _addr)
        internal
        override
        onlyForUser(_addr)
    {
        User memory _user = users[_addr];
        if (!_user.isPaused && _user.untilTime <= block.timestamp) {
            uint256 allowance = usdt.allowance(_addr, address(this));
            Tariff memory _userTariff = tariffs[userTariff[_addr]];
            if (_userTariff.price <= allowance) {
                uint256 _balance = usdt.balanceOf(_addr);
                if (_userTariff.price <= _balance) {
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
    }

    /**
     * @notice Get all tariffs on contract
     * @return Array of tariffs with duration and price
     */
    function getTariffs() external view virtual returns (Tariff[] memory) {
        return tariffs;
    }

    /**
     * @notice Set usdt token
     * @dev Only for owner
     * @param _usdt Address of token
     */
    function setUSDT(address _usdt) external onlyOwner {
        usdt = IERC20(_usdt);
    }

    /**
     * @notice Get user tariff
     * @param _user Address of token
     * @return Structure of user tariff
     */
    function getUserTariff(address _user)
        external
        view
        virtual
        returns (Tariff memory)
    {
        if (users[_user].untilTime > 0) {
            return tariffs[userTariff[_user]];
        }

        return Tariff(0, 0);
    }

    function writeOffAfterRenewTariff(address _addr) internal override {
        User memory _user = users[_addr];

        uint256 allowance = usdt.allowance(_addr, address(this));
        Tariff memory _userTariff = tariffs[userTariff[_addr]];
        require(_userTariff.price <= allowance, "Not enough USDT");
        usdt.transferFrom(_addr, address(this), _userTariff.price);
        usdt.transfer(treasury, _userTariff.price);
        if (_user.untilTime < block.timestamp) {
            _user.untilTime = block.timestamp.add(_userTariff.duration);
        } else {
            _user.untilTime = _user.untilTime.add(_userTariff.duration);
        }
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

    /**
     * @notice Set new tariff for themself user and paied it
     * @param _tariffId Identifier of tariff
     */
    function set_userTariffPay(uint8 _tariffId)
        external
        virtual
        onlyForUser(msg.sender)
    {
        userTariff[msg.sender] = _tariffId;
        users[msg.sender].isPaused = false;
        writeOffAfterRenewTariff(msg.sender);
    }

    /**
     * @notice Set new tariff for themself user and set auto write off
     * @param _tariffId Identifier of tariff
     */
    function set_userTariff(uint8 _tariffId)
        external
        override
        onlyForUser(msg.sender)
    {
        userTariff[msg.sender] = _tariffId;
        users[msg.sender].isPaused = false;
        emit subscriberV2(
            msg.sender,
            false,
            users[msg.sender].untilTime,
            _tariffId,
            false
        );
    }
}