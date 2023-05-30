// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IESZTHV1 {

    function balanceOf(address account) external view returns(uint256);

    function getLockPosition(uint256 lockId)
        external
        view
        returns (address holder, uint256 amount, uint256 unlockTime);
}