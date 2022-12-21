// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IEDEFundQUtils {
    function fundManager() external view returns (address);
    function isPublic() external view returns (bool);
  
    function vadlidOpeTrigger(uint256 _opeId ) external view returns (bool);
    function grantCondition(uint16 _trigType, int256[] memory _dataCoef, uint16[] memory _dataSourceIDs, int256[] memory _dataSetting) external  returns (uint256);
    function grantOperation(uint256[] memory _conditionIds, address _tradeToken, address _colToken, uint256 _opeSizeUSD,
            uint256 _opeDef, uint256 _leverage) external returns (uint256);
    function grantOpeProtectTime(uint256 _ope1, uint256 _ope2, uint256 _time) external;
    function revokeOperation(uint256 _id) external;
    function readCondition(uint256 _id) external  view returns (uint16, int256[] memory, uint16[] memory, int256[] memory);
    function conditionLength( ) external  view returns (uint256);
    function readOperation(uint256 _id) external  view returns (uint256[] memory, address, address, uint256, uint256, uint256);
    function operationLength( ) external  view returns (uint256);
    function opeTokens(uint256 _opeId) external view returns (bool, address, address[] memory);
    function opeAum(uint256 _opeId) external view returns (uint256, uint256, uint256);
    function opeType(uint256 _opeId) external view returns (uint256);
    function validCondition(uint256 _conditionId) external view returns (bool);
    function setCorFund(address _fundAddress) external;
    function recordOperation(uint256 _id) external;

}