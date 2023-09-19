// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../libraries/LibDiamond.sol";
import "../libraries/LibAppStore.sol";

contract ControlFacet {
    event SetTokenStorage(address indexed tokenStorage);
    event StoreToken(uint256 amount, address to, string result);
    event GatewayTransferred(address indexed newGateway);
    event AddApprovers(address[] approvers);
    event TurnoffApprovers(address[] approvers);
    event SetBoundary(uint first, uint second);
    event SetTokenContract(address token);

    /** @dev token storage address 지정
      * @param _newStorage token storage address
      */
    function setTokenStorage(address _newStorage) external {
        LibDiamond.enforceIsContractOwner();
        LibAppStore.setTokenStorage(_newStorage);
        emit SetTokenStorage(_newStorage);
    }

    /** @dev store token
      * @param _amount store token amount
      */
    function storeToken(uint256 _amount) external {
        LibDiamond.enforceIsContractOwner();
        LibAppStore.AppStorage storage ls = LibAppStore.appStorage();
        (bool success, bytes memory returnData) = ls.deployed.call(abi.encodeWithSignature("transfer(address,uint256)", ls.tokenStorage, _amount));
        require(success, string(returnData));
        emit StoreToken(_amount, ls.tokenStorage, string(returnData));
    }

    /** @dev gateway address 지정
      * @param _newGateway gateway address
      */
    function setGateway(address _newGateway) external {
        LibDiamond.enforceIsContractOwner();
        LibAppStore.setGateway(_newGateway);
        emit GatewayTransferred(_newGateway);
    }

    /** @dev approver 추가
      * @param _newApprovers approver addresses
      */
    function addApprovers(address[] calldata _newApprovers) external {
        LibDiamond.enforceIsContractOwner();
        LibAppStore.addApprovers(_newApprovers);
        emit AddApprovers(_newApprovers);
    }

    /** @dev approver 비활성화
      * @param _delApprovers approver addresses
      */
    function removeApprovers(address[] calldata _delApprovers) external {
        LibDiamond.enforceIsContractOwner();
        LibAppStore.removeApprovers(_delApprovers);
        emit TurnoffApprovers(_delApprovers);
    }

    /** @dev 인증 조건 설정
      * @param _low low boundary
      * @param _high high boundary
      */
    function setBoundary(uint256 _low, uint256 _high) external {
        LibDiamond.enforceIsContractOwner();
        LibAppStore.setBoundary(_low, _high);
        emit SetBoundary(_low, _high);
    }

    /** @dev deployed token contract address 설정
      * @param _deployed deployed token contract address
      */
    function setDeployedContract(address _deployed) external {
        LibDiamond.enforceIsContractOwner();
        LibAppStore.setDeployedContract(_deployed);
        emit SetTokenContract(_deployed);
    }
}