// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IGloryLocked.sol";
import "./interfaces/IGloryToken.sol";
import "./interfaces/IGGlory.sol";

contract GloryLocked is IGloryLocked, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IGloryToken public glory;
    IGGlory public gGlory;
    // MAINNET config
    uint256 public unlockTime = 1682208000; // Sunday, April 23, 2023 12:00:00 AM

    mapping(address => uint256) public lockedBalance;

    event Unlock(address account, uint256 amount);

    modifier onlyGGlory() {
        require(msg.sender == address(gGlory), "only gGlory");
        _;
    }

    constructor(IGloryToken _glory, IGGlory _gGlory) {
        glory = _glory;
        gGlory = _gGlory;
        glory.approve(address(_gGlory), type(uint256).max);
    }

    function balanceOf(
        address _account
    ) external view override returns (uint256) {
        return lockedBalance[_account];
    }

    function lockGlory(
        address[] memory _accounts,
        uint256[] memory _amount
    ) external onlyOwner {
        require(_accounts.length == _amount.length, "invalid input array");
        for (uint i = 0; i < _accounts.length; i++) {
            lockedBalance[_accounts[i]] = _amount[i];
        }
    }

    function stakeGlory(
        address _account,
        uint256 _amount
    ) external override onlyGGlory {
        lockedBalance[_account] -= _amount;
        glory.transfer(address(gGlory), _amount);
    }

    function withdraw() external nonReentrant {
        address account = msg.sender;
        require(block.timestamp > unlockTime, "not unlocked yet");
        uint256 unlockAmount = lockedBalance[account];
        require(unlockAmount > 0, "already withdraw");
        lockedBalance[account] = 0;
        glory.transfer(account, unlockAmount);
        emit Unlock(account, unlockAmount);
    }
}