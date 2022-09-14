// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

interface ILevelManager {
    struct Tier {
        string id;
        uint8 multiplier;
        uint256 lockingPeriod; // in seconds
        uint256 minAmount; // tier is applied when userAmount >= minAmount
        bool random;
        uint8 odds; // divider: 2 = 50%, 4 = 25%, 10 = 10%
        bool vip;
    }
    
    function getAlwaysRegister()
    external
    view
    returns (
        address[] memory,
        string[] memory,
        uint256[] memory
    );
    
    function getUserUnlockTime(address account) external view returns (uint256);

    function getTierById(string calldata id)
        external
        view
        returns (Tier memory);

    function getUserTier(address account) external view returns (Tier memory);

    function getTierIds() external view returns (string[] memory);

    function lock(address account, uint256 startTime) external;

    function unlock(address account) external;

    function getUserLatestRegistration(address account)
        external
        view
        returns (address, uint256);
    
    function isUserBlacklisted(address account) external view returns(bool);
}