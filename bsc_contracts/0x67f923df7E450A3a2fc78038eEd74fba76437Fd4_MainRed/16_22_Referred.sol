// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../secutiry/Administered.sol";

contract Referred is Administered {
    /// @dev all user
    struct User {
        address _addr;
        address referredBy;
        uint256 totalReferrals;
        uint256 totalReferralEarnings;
        uint timestamp;
        bool active;
    }

    mapping(string => User) public ListUsers;

    /// @dev my referral code
    struct Referrals {
        string code;
        address _addrs;
        address referredBy;
        uint256 amount;
        uint256 _time;
        bool active;
    }
    mapping(string => Referrals) public ListReferrals;

    /// @dev bunus direct
    uint256 public bonusDirect = 10;

    /// @dev set bonus direct
    function setBonusDirect(uint256 _bonusDirect) external onlyAdmin {
        bonusDirect = _bonusDirect;
    }

    /// @dev add referral only admin/user
    function addReferral(
        string memory _code,
        address _addrs,
        address _referredBy,
        uint256 _amount
    ) external onlyUser {
        _addReferral(
            _code,
            _addrs,
            _referredBy,
            _amount,
            block.timestamp,
            true
        );
    }

    /// @dev add user
    function addUser(
        string memory _code,
        address _referrer,
        address _referredBy
    ) external onlyUser {
        _addUser(_code, _referrer, _referredBy);
    }

    /// @dev add internal user
    function _addUser(
        string memory _code,
        address _referrer,
        address _referredBy
    ) internal {
        /// @dev is exist user
        require(
            ListUsers[_code]._addr == address(0),
            "Referred: user is exist"
        );

        ListUsers[_code] = User(
            _referrer,
            _referredBy,
            0,
            0,
            block.timestamp,
            true
        );
    }

    /// @dev add internal referral
    function _addReferral(
        string memory _code,
        address _addrs,
        address _referredBy,
        uint256 _amount,
        uint256 _time,
        bool _active
    ) internal {
        /// @dev is exist referral
        require(
            ListReferrals[_code]._addrs == address(0),
            "Referred: referral is exist"
        );

        ListReferrals[_code] = Referrals(
            _code,
            _addrs,
            _referredBy,
            _amount,
            _time,
            _active
        );
    }

    /// @dev get user
    function getUser(string memory _code) public view returns (User memory) {
        return ListUsers[_code];
    }

    /// @dev get referral
    function getReferral(
        string memory _code
    ) public view returns (Referrals memory) {
        return ListReferrals[_code];
    }

    /// @dev Edit  User
    function editUser(
        string memory _code,
        uint256 _type,
        uint256 _number,
        address _addrs,
        bool _bool
    ) external onlyUser {
        if (_type == 1) {
            ListUsers[_code].totalReferrals = _number;
        } else if (_type == 2) {
            ListUsers[_code].totalReferralEarnings = _number;
        } else if (_type == 3) {
            ListUsers[_code]._addr = _addrs;
        } else if (_type == 4) {
            ListUsers[_code].active = _bool;
        }
    }

    /// @dev Edit  referral
    function editReferral(
        string memory _code,
        uint256 _type,
        uint256 _number,
        address _addrs,
        bool _bool
    ) external onlyUser {
        if (_type == 1) {
            ListReferrals[_code].amount = _number;
        } else if (_type == 3) {
            ListReferrals[_code]._addrs = _addrs;
        } else if (_type == 4) {
            ListReferrals[_code].referredBy = _addrs;
        } else if (_type == 5) {
            ListReferrals[_code]._time = _number;
        } else if (_type == 6) {
            ListReferrals[_code].active = _bool;
        }
    }
}