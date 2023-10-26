// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import {VestEntity} from "./structs/VestEntity.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract CCCVesting is OwnableUpgradeable, ERC20Upgradeable {
    using SafeERC20 for IERC20;

    uint256 public lockUpTime;

    address private _token;

    mapping(address => VestEntity[]) private _vestedEntities;

    event SetTokenAddress(address indexed token);
    event SetLockUpTime(uint256 lockUpTime);
    event Vest(address indexed user, uint256 indexed amount);
    event Refund(address indexed user, uint256 indexed amount);
    event Claim(address indexed user, uint256 indexed amount);

    error NA(address from, address to, uint256 amount);

    function initialize(address token_) external initializer {
        __Ownable_init();
        _token = token_;
        __ERC20_init("Co2Coin", "CCC");
        lockUpTime = 60 * 60 * 24 * 367;
    }

    constructor() {
        _disableInitializers();
    }

    function setTokenAddress(address newTokenAddress) external onlyOwner {
        require(newTokenAddress != address(0), "Zero address");

        _token = newTokenAddress;

        emit SetTokenAddress(newTokenAddress);
    }

    function vest(address user, uint256 amount) external onlyOwner {
        require(user != address(0), "Zero address");
        require(amount != 0, "Zero value");

        _vestedEntities[user].push(
            VestEntity(amount, block.timestamp + lockUpTime)
        );

        IERC20(_token).safeTransferFrom(msg.sender, address(this), amount);

        emit Vest(user, amount);
    }

    function refund(address user, uint256 idx) external onlyOwner {
        require(_vestedEntities[user].length > 0, "User didn't invest");
        uint256 vestedAmount = _vestedEntities[user][idx].amount;

        _vestedEntities[user][idx].amount = 0;

        IERC20(_token).safeTransfer(user, vestedAmount);

        emit Refund(user, vestedAmount);
    }

    function balanceOf(address user) public view override returns (uint256) {
        VestEntity[] memory entities = _vestedEntities[user];
        uint256 sum;
        for (uint256 i = 0; i < entities.length; i++) {
            sum += entities[i].amount;
        }
        return sum;
    }

    function refundBatch(
        address user,
        uint256[] memory idxs
    ) external onlyOwner {
        VestEntity[] memory entities = _vestedEntities[user];

        require(entities.length > 0, "User didn't invest");
        uint256 amount = 0;

        for (uint256 i = 0; i < idxs.length; i++) {
            amount += entities[i].amount;

            _vestedEntities[user][i].amount = 0;
        }

        IERC20(_token).safeTransfer(user, amount);

        emit Refund(user, amount);
    }

    function claim() external {
        _transfer(true, address(0), 0);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        revert NA(from, to, amount);
    }

    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        _transfer(false, to, amount);
        return true;
    }

    function setLockUpTime(uint256 newLockUpTime) external onlyOwner {
        require(newLockUpTime != 0, "Zero value");

        lockUpTime = newLockUpTime;

        emit SetLockUpTime(newLockUpTime);
    }

    function getVestedEntity(
        address user,
        uint256 idx
    ) external view returns (VestEntity memory) {
        return _vestedEntities[user][idx];
    }

    function getAllVestedEntities(
        address user
    ) external view returns (VestEntity[] memory) {
        return _vestedEntities[user];
    }

    function getTokenAddress() external view returns (address) {
        return _token;
    }

    function _transfer(
        bool isClaim,
        address to,
        uint256 transferAmount
    ) internal {
        address user = msg.sender;

        require(_vestedEntities[user].length > 0, "User didn't invest");

        uint256 maxIdx;
        VestEntity[] memory entities = _vestedEntities[user];
        uint256 amountToSend = 0;

        for (uint256 i = 0; i < entities.length; i++) {
            if (entities[i].amount == 0) {
                continue;
            }
            if (block.timestamp > entities[i].lockUpTime) {
                amountToSend += entities[i].amount;
                maxIdx = i;

                if (
                    !isClaim &&
                    amountToSend >= transferAmount &&
                    transferAmount != 0
                ) {
                    break;
                }
            } else if (!isClaim) {
                revert("Insufficient unlocked balance");
            }
        }

        _clearUserData(user, maxIdx);

        if (isClaim) {
            IERC20(_token).safeTransfer(user, amountToSend);

            emit Claim(user, amountToSend);
        } else {
            IERC20(_token).safeTransfer(to, transferAmount);
            uint256 remainingAmount = amountToSend - transferAmount;

            if (remainingAmount > 0) {
                IERC20(_token).safeTransfer(user, remainingAmount);
            }

            emit Transfer(msg.sender, to, transferAmount);
        }
    }

    function _clearUserData(address user, uint256 maxIdx) internal {
        VestEntity[] memory vestedEntities = _vestedEntities[user];
        delete _vestedEntities[user];

        for (uint256 i = 0; i < vestedEntities.length; i++) {
            if (i > maxIdx) {
                _vestedEntities[user].push(
                    VestEntity(
                        vestedEntities[i].amount,
                        vestedEntities[i].lockUpTime
                    )
                );
            }
        }
    }
}