//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20,SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

//  Crydeal 1 : 1 v0.1.0
//   _______  ______    __   __  ______   _______  _______  ___
//  |       ||    _ |  |  | |  ||      | |       ||   _   ||   |
//  |       ||   | ||  |  |_|  ||  _    ||    ___||  |_|  ||   |
//  |       ||   |_||_ |       || | |   ||   |___ |       ||   |
//  |      _||    __  ||_     _|| |_|   ||    ___||       ||   |___
//  |     |_ |   |  | |  |   |  |       ||   |___ |   _   ||       |
//  |_______||___|  |_|  |___|  |______| |_______||__| |__||_______|
//
//  ASCII art from https://patorjk.com/

contract Crydeal is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Deal {
        bool exists;
        uint256 amount;
        uint256 payment;
        IERC20 token;
        address to;
        address from;
        bool lockTo;
        bool lockFrom;
    }

    uint256 public dealId;

    bool private _pause;

    address private constant ZERO_ADDRESS = address(0);

    mapping (uint256 => Deal) public deals;

    event Create(address indexed user, uint256 amount, uint256 payment, uint256 dealId, address token);

    event LockTo(address indexed user, uint256 dealId);

    event LockFrom(address indexed user, uint256 dealId);

    event UnlockTo(address indexed user, uint256 dealId);

    event UnlockFrom(address indexed user, uint256 dealId);

    event EndLock(uint256 dealId);

    event CancelLock(address indexed user, uint256 dealId);

    constructor() {
        dealId = 1;
        _pause = false;
    }

    function pause(bool value) external onlyOwner {
        _pause = value;
    }

    function _create(uint256 amount, uint256 payment, bool is2, address token) private {
        (address to, address from, bool lt, bool lf) = is2 ? (_msgSender(), ZERO_ADDRESS, false, false) :
            (ZERO_ADDRESS, _msgSender(), false, false);

        deals[dealId] = Deal(true, amount, payment, IERC20(token), to, from, lt, lf);

        emit Create(_msgSender(), amount, payment, dealId, token);
    }

    function create(uint256 amount, uint256 payment, bool is2, address token) external {
        require(!_pause, "Crydeal is pause now");
        IERC20(token).safeTransferFrom(_msgSender(), address(this), amount);
        _create(amount, payment, is2, token);

        if (is2) {
            _lockTo(dealId);
        } else {
            _lockFrom(dealId);
        }

        dealId += 1;
    }

    function _lockTo(uint256 id) private {
        require(deals[id].exists, "LockTo: Lock is not exists");
        require(!deals[id].lockTo, "LockTo: To was already locked");
        deals[id].token.safeTransferFrom(_msgSender(), address(this), deals[id].amount);
        deals[id].to = _msgSender();
        deals[id].lockTo = true;
    }

    function lockTo(uint256 id) external {
        _lockTo(id);
        emit LockTo(_msgSender(), id);
    }

    function _lockFrom(uint256 id) private {
        require(deals[id].exists, "LockFrom: Lock is not exists");
        require(!deals[id].lockFrom, "LockFrom: From was already locked");
        deals[id].token.safeTransferFrom(_msgSender(), address(this), deals[id].amount);
        deals[id].from = _msgSender();
        deals[id].lockFrom = true;
    }

    function lockFrom(uint256 id) external {
        _lockFrom(id);
        emit LockFrom(_msgSender(), id);
    }

    function _refund(uint256 id) private {
        if (deals[id].to != ZERO_ADDRESS) {
            deals[id].token.safeTransfer(deals[id].to, deals[id].amount);
            deals[id].lockTo = false;
            deals[id].to = ZERO_ADDRESS;
        }
        if (deals[id].from != ZERO_ADDRESS) {
            deals[id].token.safeTransfer(deals[id].from, deals[id].amount);
            deals[id].lockFrom = false;
            deals[id].from = ZERO_ADDRESS;
        }
    }

    function cancelLock(uint256 id) external {
        require(deals[id].exists, "CancelLock: Lock is not exists");
        require(deals[id].to == _msgSender() || deals[id].from == _msgSender(),
                "CancelLock: Not this lock");
        require(
            (deals[id].to == ZERO_ADDRESS && deals[id].from != ZERO_ADDRESS) ||
            (deals[id].to != ZERO_ADDRESS && deals[id].from == ZERO_ADDRESS),
            "CancelLock: One of addresses should be zero");

        _refund(id);

        emit CancelLock(_msgSender(), id);
    }

    function _endLock(uint256 id) private {
        require(deals[id].to != ZERO_ADDRESS && deals[id].from != ZERO_ADDRESS,
            "EndLock: Addresses should not be zero");

        uint256 toAmount = deals[id].amount.add(deals[id].payment);
        uint256 fromAmount = deals[id].amount.sub(deals[id].payment);

        deals[id].token.safeTransfer(deals[id].to, toAmount);
        deals[id].token.safeTransfer(deals[id].from, fromAmount);

        deals[id].to = ZERO_ADDRESS;
        deals[id].from = ZERO_ADDRESS;

        emit EndLock(id);
    }

    function unlockTo(uint256 id) external {
        require(deals[id].exists, "Unlock: Lock not exists");
        require(deals[id].to == _msgSender() || deals[id].from == _msgSender(),
                "Unlock: Not this lock");
        require(deals[id].lockTo, "Unlock: Already unlocked");

        deals[id].lockTo = false;

        emit UnlockTo(_msgSender(), id);

        if (!deals[id].lockFrom && !deals[id].lockTo) {
            _endLock(id);
        }
    }

    function unlockFrom(uint256 id) external {
        require(deals[id].exists, "Unlock: Lock not exists");
        require(deals[id].to == _msgSender() || deals[id].from == _msgSender(),
                "Unlock: Not this lock");
        require(deals[id].lockFrom, "Unlock: Already unlocked");

        deals[id].lockFrom = false;

        emit UnlockFrom(_msgSender(), id);

        if (!deals[id].lockFrom && !deals[id].lockTo) {
            _endLock(id);
        }
    }
}