interface IDefaultTracker {

    function distributeRewardDividends(uint256 amount) external;
    function setBalance(address payable account, uint256 newBalance) external;
    function process() external returns (uint256, uint256, uint256);
    function getNumberOfTokenHolders() external returns (uint256);
    function getAccountAtIndex(uint256 index) external returns (address);
    function _excludeFromDividendsByAdminContract(address account) external;
    function setRewardToken(address _address) external;
    function lastProcessedIndex() external returns(uint256);
    
}