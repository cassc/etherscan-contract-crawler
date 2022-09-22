// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IESVSP is IERC20, IERC20Metadata {
    /// Emitted when a new position is created (i.e. when user locks VSP)
    event VspLocked(uint256 tokenId, address account, uint256 amount, uint256 lockPeriod);
    /// Emitted when a position is burned (i.e. when user withdraws VSP)
    event VspUnlocked(uint256 tokenId);
    /// Emitted when a position is kicked (i.e. when expired)
    event PositionKicked(uint256 tokenId);
    /// Emitted when the exit penalty is updated
    event ExitPenaltyUpdated(uint256 oldExitPenalty, uint256 newExitPenalty);
    /// Emitted when the treasury address is updated
    event TreasuryUpdated(address oldTreasury, address newTreasury);

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

    function VSP() external view returns (address);

    function esVSP721() external view returns (address);
}