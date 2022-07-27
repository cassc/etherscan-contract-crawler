// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "./IRewards.sol";

interface IESVSP is IERC20Metadata {
    function totalLocked() external view returns (uint256);

    function totalBoosted() external view returns (uint256);

    function locked(address _account) external view returns (uint256);

    function boosted(address _account) external view returns (uint256);

    function lock(uint256 amount_, uint256 lockPeriod_) external;

    function lockFor(
        address to_,
        uint256 amount_,
        uint256 lockPeriod_
    ) external;

    function updateExitPenalty(uint256 exitPenalty_) external;

    function unlock(uint256 tokenId_, bool unexpired_) external;

    function kick(uint256 tokenId_) external;

    function kickAllExpiredOf(address account_) external;

    function lockedBalanceOf(address account_) external view returns (uint256);

    function transferPosition(uint256 tokenId_, address to_) external;
}