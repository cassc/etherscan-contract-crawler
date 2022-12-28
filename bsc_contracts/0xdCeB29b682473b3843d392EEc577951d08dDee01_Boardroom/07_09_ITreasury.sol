// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface ITreasury {
    function epoch() external view returns (uint256);

    function polWallet() external view returns (address);

    function rewardLockupEpochs() external view returns (uint256);

    function withdrawLockupEpochs() external view returns (uint256);
}