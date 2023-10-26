// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IArcadeTreasury {
    // ====== Structs ======

    /// @notice struct of spend thresholds
    struct SpendThreshold {
        uint256 small;
        uint256 medium;
        uint256 large;
    }

    // ====== Treasury Operations ======

    function gscSpend(address token, uint256 amount, address destination) external;

    function smallSpend(address token, uint256 amount, address destination) external;

    function mediumSpend(address token, uint256 amount, address destination) external;

    function largeSpend(address token, uint256 amount, address destination) external;

    function gscApprove(address token, address spender, uint256 amount) external;

    function approveSmallSpend(address token, address spender, uint256 amount) external;

    function approveMediumSpend(address token, address spender, uint256 amount) external;

    function approveLargeSpend(address token, address spender, uint256 amount) external;

    function setThreshold(address token, SpendThreshold memory thresholds) external;

    function setGSCAllowance(address token, uint256 newAllowance) external;

    function batchCalls(address[] memory targets, bytes[] calldata calldatas) external;
}