pragma solidity ^0.8.10;

interface IAdapter {
    struct RewardData {
        address token;
        uint256 amount;
    }

    function underlyingBalance() external view returns (uint256);
    function withdraw(uint256, uint256) external;
    function deposit(uint256, uint256) external;
    function claim() external;
    function lpBalance() external view returns (uint256);
    function totalClaimable() external view returns (RewardData[] memory);
    function isHealthy() external view returns (bool);
    function setHealthFactor(uint256 _newHealthFactor) external;
}