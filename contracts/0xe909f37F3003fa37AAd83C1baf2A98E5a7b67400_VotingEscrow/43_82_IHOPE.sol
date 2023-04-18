// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

interface IHOPE {
    /**
     * @dev HOPE token mint
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev return HOPE agent remaining credit
     */
    function getRemainingCredit(address account) external view returns (uint256);

    /**
     * @dev HOPE token burn self address
     */
    function burn(uint256 amount) external;
}