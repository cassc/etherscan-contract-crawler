// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./Events.sol";

contract Lending is Events {
    mapping(address => LendingStr) private _lending;

    LendingStatus public _lending_status = LendingStatus.Online;

    address _lending_owner = msg.sender;

    modifier _onlyOwner() {
        require(msg.sender == _lending_owner, "You are not an owner");
        _;
    }

    struct LendingStr {
        uint256 _lending_value;
        uint256 _lending_timestamp;
    }

    enum LendingStatus {
        Offline,
        Online
    }

    uint256 public _lending_all;

    uint256 public percentMin = 50; 
                                    //0.00005% min

    function addLending() external payable {
        require(_lending[msg.sender]._lending_value == 0, "No Zero funds");
        require(_lending[msg.sender]._lending_timestamp == 0, "No Zero time");
        require(_lending_status == LendingStatus.Online, "Lending is offline");

        _lending[msg.sender]._lending_value += msg.value;
        _lending[msg.sender]._lending_timestamp = block.timestamp;
        _lending_all += msg.value;

        emit AddLengindEvent(msg.sender, msg.value, block.timestamp);
    }

    function removeLending() external {
        require(_lending[msg.sender]._lending_value > 0, "Zero funds");
        require(_lending[msg.sender]._lending_timestamp > 0, "Zero time");

        uint256 _amount = _lending[msg.sender]._lending_value;
        uint256 __time = _lending[msg.sender]._lending_timestamp;

        _lending[msg.sender]._lending_value = 0;
        _lending[msg.sender]._lending_timestamp = 0;
        _lending_all -= _amount;

        uint256 _time = block.timestamp - __time;
        uint256 _mins = _time / 60;
        uint256 _reward_percent = percentMin * _mins; //
        uint256 _reward = (_amount * _reward_percent) / 100000000;

        payable(msg.sender).transfer(_amount + _reward);

        emit RemoveLengindEvent(
            msg.sender,
            _amount,
            _reward,
            _reward_percent,
            _mins,
            block.timestamp
        );
    }

    function lendOff(bool status) external _onlyOwner {
        if (status) {
            _lending_status = LendingStatus.Offline;
        } else {
            _lending_status = LendingStatus.Online;
        }
    }

    function changePercentDay(uint256 _percentMin) external _onlyOwner {
        require(_percentMin < 150, "Too much");
        percentMin = percentMin;
    }

    function returnUserLending(address user)
        external
        view
        returns (uint256 _lending_value, uint256 _lending_timestamp)
    {
        return (
            _lending[user]._lending_value,
            _lending[user]._lending_timestamp
        );
    }
}