//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IBKRegistry {    
    function setFeature( bytes4 _methodId, address _proxy, bool _isLib, bool _isActive) external;

    function getFeature(bytes4 _methodId) external view returns(address proxy, bool isLib);

    function setCallTarget(bytes4 _methodId, address [] memory _targets, bool _isEnable) external;

    function isCallTarget(bytes4 _methodId, address _target) external view returns(bool);

    function setApproveTarget(bytes4 _methodId, address [] memory _targets, bool _isEnable) external;

    function isApproveTarget(bytes4 _methodId, address _target) external view returns(bool);
}