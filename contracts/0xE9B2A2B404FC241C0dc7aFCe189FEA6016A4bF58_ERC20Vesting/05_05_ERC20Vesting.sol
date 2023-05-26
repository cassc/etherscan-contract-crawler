// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract ERC20Vesting {
    event ERC20Released(uint256 amount);

    uint256 public released;
    address public immutable token;
    address public immutable beneficiary;
    uint64 public immutable start;
    uint64 public immutable duration;

    constructor(
        address tokenAddress,
        address beneficiaryAddress,
        uint64 startTimestamp,
        uint64 durationSeconds
    ) {
        require(
            beneficiaryAddress != address(0) && tokenAddress != address(0),
            "AddressZero"
        );
        token = tokenAddress;
        beneficiary = beneficiaryAddress;
        start = startTimestamp;
        duration = durationSeconds;
    }

    receive() external payable {
        revert();
    }

    function releasable() public view returns (uint256) {
        return vestedAmount(uint64(block.timestamp)) - released;
    }

    function release() public {
        uint256 amount = releasable();
        released += amount;
        emit ERC20Released(amount);
        SafeERC20.safeTransfer(IERC20(token), beneficiary, amount);
    }

    function vestedAmount(uint64 timestamp) public view returns (uint256) {
        return
            _vestingSchedule(
                IERC20(token).balanceOf(address(this)) + released,
                timestamp
            );
    }

    function _vestingSchedule(
        uint256 totalAllocation,
        uint64 timestamp
    ) internal view returns (uint256) {
        if (timestamp < start) {
            return 0;
        } else if (timestamp > start + duration) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start)) / duration;
        }
    }
}