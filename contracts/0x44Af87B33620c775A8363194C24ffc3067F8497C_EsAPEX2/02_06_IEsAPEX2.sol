// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../../interfaces/IERC20.sol";

interface IEsAPEX2 is IERC20 {
    event ForceWithdrawMinRemainRatioChanged(uint256 oldRatio, uint256 newRatio);
    event VestTimeChanged(uint256 oldVestTime, uint256 newVestTime);
    event Vest(address indexed user, uint256 amount, uint256 endTime, uint256 vestId);
    event Withdraw(address indexed user, address indexed to, uint256 amount, uint256 vestId);
    event ForceWithdraw(
        address indexed user,
        address indexed to,
        uint256 withdrawAmount,
        uint256 penalty,
        uint256 vestId
    );

    struct VestInfo {
        uint256 startTime;
        uint256 endTime;
        uint256 vestAmount;
        uint256 claimedAmount;
        bool forceWithdrawn;
    }

    function apeXToken() external view returns (address);

    function treasury() external view returns (address);

    function forceWithdrawMinRemainRatio() external view returns (uint256);

    function vestTime() external view returns (uint256);

    function getVestInfo(address user, uint256 vestId) external view returns (VestInfo memory);

    function getVestInfosByPage(
        address user,
        uint256 offset,
        uint256 size
    ) external view returns (VestInfo[] memory vestInfos);

    function getVestInfosLength(address user) external view returns (uint256 length);

    function getClaimable(address user, uint256 vestId) external view returns (uint256 claimable);

    function getTotalClaimable(address user, uint256[] memory vestIds) external view returns (uint256 claimable);

    function getLocking(address user, uint256 vestId) external view returns (uint256 locking);

    function getTotalLocking(address user, uint256[] memory vestIds) external view returns (uint256 locking);

    function getForceWithdrawable(address user, uint256 vestId)
        external
        view
        returns (uint256 withdrawable, uint256 penalty);

    function getTotalForceWithdrawable(address user, uint256[] memory vestIds)
        external
        view
        returns (uint256 withdrawable, uint256 penalty);

    function mint(address to, uint256 apeXAmount) external returns (bool);

    function vest(uint256 amount) external;

    function withdraw(
        address to,
        uint256 vestId,
        uint256 amount
    ) external;

    function batchWithdraw(
        address to,
        uint256[] memory vestIds,
        uint256[] memory amounts
    ) external;

    function forceWithdraw(address to, uint256 vestId) external returns (uint256 withdrawAmount, uint256 penalty);

    function batchForceWithdraw(address to, uint256[] memory vestIds)
        external
        returns (uint256 withdrawAmount, uint256 penalty);
}