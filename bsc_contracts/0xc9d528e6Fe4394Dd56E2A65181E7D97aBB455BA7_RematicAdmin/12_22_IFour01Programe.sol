interface IFour01Programe {

    function process(address _address, uint256 rewwardCount, uint256 _standardAmount) external ;
    function addUser401OptIn(address _address, uint256 percentage ) external;
    function removeUser401OptIn(address _address ) external;
    
    function updateCreditPercentageMap(uint256 index,  uint256 minPercentage, uint256 creditPercentage) external;
    function getUserPercentageIn401Programe(address _address ) external view returns (uint256);

}