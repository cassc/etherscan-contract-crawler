// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

/// @title ISwapper
/// @author Angle Core Team
/// @notice Interface for a generic swapper, that supports swaps of higher complexity than aggregators
interface ISwapper {
    function swap(
        IERC20 inToken,
        IERC20 outToken,
        address outTokenRecipient,
        uint256 outTokenOwed,
        uint256 inTokenObtained,
        bytes memory data
    ) external;
}