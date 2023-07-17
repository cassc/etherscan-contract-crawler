pragma solidity ^0.8.7;

interface IRNG2 {
    function requestRandomNumber( ) external returns (uint256);
    function requestRandomNumberWithCallback( ) external returns (uint256);
    function isRequestComplete(uint256 requestId) external view returns (bool isCompleted);
    function randomNumber(uint256 requestId) external view returns (uint256 randomNum);
    function setAuth(address user, bool grant) external;
    function requestRandomWords(uint32 numberOfWords, uint speed) external returns (uint256);
    function requestRandomWordsAdvanced(uint32 numberOfWords, uint speed , uint32 _callbackGasLimit, uint16 _requestConfirmations) external returns (uint256) ;
    function requestRandomWordsWithCallback(uint32 numberOfWords, uint speed) external returns (uint256);
    function requestRandomWordsAdvancedWithCallback(uint32 numberOfWords, uint speed, uint32 _callbackGasLimit, uint16 _requestConfirmations) external returns (uint256) ;

}