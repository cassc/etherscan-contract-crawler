// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVesting {
    event Released(uint256 amount, address to);

    struct Beneficiary {
        uint256 start;
        uint256 duration;
        uint256 cliff;
        uint256 amount;
    }

    function vest(
        address beneficiaryAddress,
        uint256 startTimestamp,
        uint256 durationSeconds,
        uint256 amount,
        uint256 cliff
    ) external;

    function release(address _beneficiary) external;

    function releasable(address _beneficiary, uint256 _timestamp)
        external
        view
        returns (uint256 canClaim, uint256 earnedAmount);

    function vestedAmountBeneficiary(address _beneficiary, uint256 _timestamp)
        external
        view
        returns (uint256 vestedAmount, uint256 maxAmount);

    function emergencyVest(IERC20 _token) external;
}