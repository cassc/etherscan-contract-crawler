// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface IDexFiTreasury {
    struct FeeReceiverInfo {
        address receiver;
        uint256 percent;
    }

    function receivers(uint256 index) external view returns (address);
    function receiversCount() external view returns (uint256);
    function receiversContains(address receiver) external view returns (bool);
    function receiversList(uint256 offset, uint256 limit) external view returns (address[] memory output);
    function receiverPercent(address receiver) external view returns (uint256);

    event FeeReceiversInfoUpdated(FeeReceiverInfo[] info);
    event TreasuryClaimed(address indexed token, uint256 amount);

    function claimTreasury(address[] memory tokens) external returns (bool);
    function updateFeeReceiversInfo(FeeReceiverInfo[] memory info) external returns (bool);
}