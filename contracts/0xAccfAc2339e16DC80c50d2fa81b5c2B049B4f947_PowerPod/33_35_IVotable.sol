// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
pragma abicoder v1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVotable is IERC20 {
    /// @dev we assume that voting power is a function of balance that preserves order
    function votingPowerOf(address account) external view returns (uint256);
}