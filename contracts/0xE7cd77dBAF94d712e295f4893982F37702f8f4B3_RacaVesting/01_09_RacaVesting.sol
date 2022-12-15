// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract RacaVesting is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // beneficiary of tokens after they are released
    address public beneficiary;
    // cliff period in seconds
    uint256 public immutable cliff;
    // start time of the vesting period
    uint256 public immutable start;
    // duration of the vesting period in seconds
    uint256 public immutable duration;
    // duration of a slice period for the vesting in seconds
    uint256 public immutable slicePeriod;
    // total amount of tokens to be released at the end of the vesting
    uint256 public immutable amountTotal;
    // amount of tokens released
    uint256 public released;

    IERC20 public immutable token;

    event Released(uint256 amount);

    constructor() {
        token = IERC20(0x12BB890508c125661E03b09EC06E404bc9289040);

        beneficiary = 0x6B986bd61983A6A2ad9c9aD9fDaa02F186A0DA6C;

        cliff = 0;
        // 2023-01-01 00:00:00 (UTC)
        start = 1672531200;
        // 18 months
        duration = 18 * 30 * 24 * 3600;
        // 1 month
        slicePeriod = 1 * 30 * 24 * 3600;
        // 0.86 billion
        amountTotal = 860000000 ether;
    }

    function release() external nonReentrant {
        require(
            _msgSender() == beneficiary,
            "RacaVesting: only beneficiary can release vested tokens"
        );
        require(block.timestamp > start, "RacaVesting: not released period");

        uint256 vestedAmount = computeReleasableAmount(block.timestamp);
        require(vestedAmount > 0, "RacaVesting: no released token");

        released = released.add(vestedAmount);
        token.safeTransfer(beneficiary, vestedAmount);

        emit Released(vestedAmount);
    }

    function computeReleasableAmount(uint256 currentTime)
        public
        view
        returns (uint256)
    {
        if (currentTime < start.add(slicePeriod)) {
            return 0;
        } else if (currentTime >= start.add(duration)) {
            return amountTotal.sub(released);
        } else {
            uint256 timeFromStart = currentTime.sub(start);
            uint256 vestedSlicePeriods = timeFromStart.div(slicePeriod);
            uint256 vestedSeconds = vestedSlicePeriods.mul(slicePeriod);
            uint256 vestedAmount = amountTotal.mul(vestedSeconds).div(duration);
            vestedAmount = vestedAmount.sub(released);
            return vestedAmount;
        }
    }

    function changeBeneficiary(address _beneficiary) external onlyOwner {
        beneficiary = _beneficiary;
    }

    function withdraw(uint256 amount) external nonReentrant onlyOwner {
        require(
            token.balanceOf(address(this)) >= amount,
            "RacaVesting: not enough withdrawable funds"
        );
        token.safeTransfer(owner(), amount);
    }
}