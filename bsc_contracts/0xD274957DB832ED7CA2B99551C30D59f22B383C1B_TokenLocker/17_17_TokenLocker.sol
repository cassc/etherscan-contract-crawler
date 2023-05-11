// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../access/OperatorsUpgradeable.sol";
import "../interfaces/ITokenLocker.sol";

contract TokenLocker is
    OperatorsUpgradeable,
    ReentrancyGuardUpgradeable,
    ITokenLocker
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    ITokenMinter public override token;

    LockedItem[] public items;

    uint256 public feeRate;
    uint256 public feeLockTime;

    uint256[50] private __gap;

    constructor() {}

    function initialize(address _token) external initializer {
        __Operators_init();
        token = ITokenMinter(_token);
        feeLockTime = 7 days;
        feeRate = 3e8;
    }

    function setLockTimeRate(
        uint256 _feeLockTime,
        uint256 _feeRate
    ) external override onlyOwner {
        feeLockTime = _feeLockTime;
        feeRate = _feeRate;
        require(feeRate < 1e9, "!feeRate");
    }

    function getLockTimeRate()
        external
        view
        override
        returns (uint256, uint256)
    {
        return (feeLockTime, feeRate);
    }

    function getItem(
        uint256 lid
    ) external view override returns (LockedItem memory) {
        return items[lid];
    }

    function pending(
        uint256 lid
    ) public view override returns (uint256, uint256) {
        LockedItem memory item = items[lid];
        if (item.unlocked) {
            return (0, 0);
        }
        uint256 unlocktime = item.timestamp.add(feeLockTime);
        if (unlocktime <= block.timestamp) {
            return (item.amount, 0);
        }
        uint256 fee = item
            .amount
            .mul(feeRate)
            .mul(unlocktime.sub(block.timestamp))
            .div(feeLockTime)
            .div(1e9);
        return (item.amount.sub(fee), fee);
    }

    function claimBatch(
        uint256[] memory lid,
        address _touser
    ) external override onlyOper {
        uint256 amount = 0;
        for (uint256 i = 0; i < lid.length; i++) {
            uint256 tid = lid[i];
            require(!items[tid].unlocked, "released");
            require(items[tid].user == _touser, "user");
            (uint256 itemamount, ) = pending(tid);
            amount = amount.add(itemamount);
            items[tid].unlocked = true;
            emit ClaimToken(items[tid].sid, items[tid].user, itemamount);
        }
        if (amount > 0) {
            uint256 balance = token.balanceOf(address(this));
            if (balance < amount) {
                token.mint(amount.sub(balance));
            }
            require(token.balanceOf(address(this)) >= amount, "balanceOf!");
            token.transfer(_touser, amount);
        }
    }

    function gameOut(
        uint256 _serialid,
        address _user,
        uint256 _timestamp,
        uint256 _value
    ) public override onlyOper {
        items.push(LockedItem(_serialid, _user, _value, _timestamp, false));
        emit PullFromGame(_serialid, items.length.sub(1), _user, _value);
    }

    function gameOutBatch(
        uint256[] memory _serialid,
        address[] memory _user,
        uint256[] memory _timestamp,
        uint256[] memory _value
    ) external override onlyOper {
        require(_serialid.length == _user.length, "length1!");
        require(_timestamp.length == _value.length, "length2!");
        require(_user.length == _timestamp.length, "length3!");
        for (uint256 i = 0; i < _serialid.length; i++) {
            gameOut(_serialid[i], _user[i], _timestamp[i], _value[i]);
        }
    }
}