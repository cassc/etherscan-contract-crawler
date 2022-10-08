interface IDefaultTracker {

    function distributeRewardDividends(uint256 amount) external;
    function setBalance(address payable account, uint256 newBalance) external;
    function process() external returns (uint256, uint256, uint256);
    function getNumberOfTokenHolders() external view returns (uint256);
    function getAccountAtIndex(uint256 index) external view returns (address);
    function _excludeFromDividendsByAdminContract(address account) external;
    function setRewardToken(address _address) external;
    function setFour01Programe(address _address, address _four01TeamWallet) external;
    function lastProcessedIndex() external returns(uint256);

    function mintDividendTrackerToken(address account, uint256 amount) external;
    
}