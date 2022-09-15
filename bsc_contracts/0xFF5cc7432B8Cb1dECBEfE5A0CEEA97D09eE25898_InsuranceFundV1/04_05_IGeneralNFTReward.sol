interface IGeneralNFTReward {
    function _periodFinish() external view returns (uint256);
    function notifyReward(uint256 reward) external;
    function setGovernance(address governance) external;
    function setDepositFeeRate( uint256 depositFeeRate ) external;
    function setBurnFeeRate( uint256 burnFeeRate ) external;
    function setSpynFeeRate( uint256 spynFeeRate ) external;
    function setHarvestFeeRate( uint256 harvestFeeRate ) external;
    function setHarvestInterval( uint256  harvestInterval ) external;
    function setExtraHarvestInterval( uint256  extraHarvestInterval ) external;
    function setRewardPool( address  rewardPool ) external;
    function setMaxStakedDego(uint256 amount) external;
    function setMigrateToContract(address migrateToContract) external;
    function setMigrateFromContract(address migrateFromContract) external;
}