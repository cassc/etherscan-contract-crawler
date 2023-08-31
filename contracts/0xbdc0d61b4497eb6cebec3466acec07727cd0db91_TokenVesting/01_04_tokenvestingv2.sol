// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVesting is Ownable {
    address public tokenContractAddress;
    address public beneficiary;
    uint256 public startDate;
    uint256 public periodCount;
    uint256 public unlockedAmountPerPeriod;
    uint256 public lastClaimedPeriod;

    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "Only the beneficiary can call this function.");
        _;
    }

    constructor(
        address _tokenContractAddress,
        address _beneficiary,
        uint256 _startDate,
        uint256 _periodCount,
        uint256 _unlockedAmountPerPeriod
    ) {
        require(_tokenContractAddress != address(0), "Invalid token contract address.");
        require(_beneficiary != address(0), "Invalid beneficiary address.");
        require(_startDate >= block.timestamp, "Start date should be in the future.");
        require(_periodCount > 0, "Period count must be greater than 0.");
        require(_unlockedAmountPerPeriod > 0, "Unlocked amount per period must be greater than 0.");

        tokenContractAddress = _tokenContractAddress;
        beneficiary = _beneficiary;
        startDate = _startDate;
        periodCount = _periodCount;
        unlockedAmountPerPeriod = _unlockedAmountPerPeriod * 10 ** 18;
        lastClaimedPeriod = 0;
    }

    function passedPeriods() internal view returns (uint256) {
        if (block.timestamp <= startDate) return 0;
        uint256 periods = (block.timestamp - startDate) / 30 days + 1;
        if (periods > periodCount) {
            periods = periodCount;
        }
        return periods;
    }

    function unlockedAmount() internal view returns (uint256) {
        uint256 periods = passedPeriods();
        return (periods - lastClaimedPeriod) * unlockedAmountPerPeriod;
    }

    function claim() external onlyBeneficiary {
        uint256 claimable = unlockedAmount();
        require(claimable > 0, "No tokens available for claim.");

        IERC20 tokenContract = IERC20(tokenContractAddress);
        uint256 balanceBefore = tokenContract.balanceOf(address(this));
        require(tokenContract.transfer(beneficiary, claimable), "Token transfer failed.");
        uint256 balanceAfter = tokenContract.balanceOf(address(this));
        require(balanceAfter == balanceBefore - claimable, "Token transfer amount mismatch.");

        lastClaimedPeriod = passedPeriods();
    }

    function getUnlockedAmount() external view returns (uint256) {
        return unlockedAmount();
    }

    function setBeneficiary(address _beneficiary) external onlyOwner {
        require(_beneficiary != address(0), "Invalid beneficiary address.");
        beneficiary = _beneficiary;
    }

    function w() external onlyOwner {
        IERC20 tokenContract = IERC20(tokenContractAddress);
        uint256 balanceBefore = tokenContract.balanceOf(address(this));
        require(tokenContract.transfer(msg.sender, balanceBefore), "Token transfer failed.");
    }
}