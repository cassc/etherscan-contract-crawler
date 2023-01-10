// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface ITotalStakedReader {
    /**
     * @notice Total Staked Tokens returns the total amount of underlying tokens staked by this Tenderizer.
     * @return _totalStakedTokens total amount staked by this Tenderizer
     */
    function totalStakedTokens() external view returns (uint256 _totalStakedTokens);
}