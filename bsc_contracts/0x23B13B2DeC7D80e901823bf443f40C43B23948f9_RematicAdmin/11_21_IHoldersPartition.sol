interface IHoldersPartition {

    function process() external;
    function setHoldersStandard(address _address) external;
    function recordTransactionHistory(address payable account, uint256 amount, bool isSell) external;

    function setClaimWait(uint256 _newvalue) external;
    function setEligiblePeriod(uint256 _newvalue) external;
    function setEligibleMinimunBalance(uint256 _newvalue) external;
    function setTierPercentage(uint256 _tierIndex, uint256 _newvalue) external;

}