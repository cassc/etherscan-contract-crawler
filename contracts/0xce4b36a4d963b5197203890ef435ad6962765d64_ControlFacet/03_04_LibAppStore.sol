// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/** @title 트랜잭션 인증 및 기타 설정을 저장 */
library LibAppStore {
    bytes32 constant STORAGE_POSITION = keccak256("diamond.AppStorage");

    /** 
      * @param requester trnasfer 트랜잭션을 보낼 address
      * @param amount  trnasfer 트랜잭션 보낼 값
      * @param needConfirmation 필요한 인증 수 
      * @param numConfirmations 인증한 수
      */
    struct Transaction {
        address requester;
        uint256 amount;
        uint needConfirmation;
        uint numConfirmations;
    }

    /** 
      * @param gateway 저장된 gateway address
      * @param deployed 저장된 token contract address
      * @param approver trnasfer 트랜잭션을 보낼 address
      * @param boundaryOne 1인 인증 요구 값
      * @param boundaryTwo 2인 인증 요구 값 
      * @param transactions 저장된 트랜잭션 
      * @param isConfirmed 해당 트랜잭션 인증 여부
      */
    struct AppStorage {
        address tokenStorage;
        address gateway;
        address deployed;
        mapping(address => bool) approver;
        uint256 boundaryOne;
        uint256 boundaryTwo;
        mapping(uint => Transaction) transactions;
        mapping(uint => mapping(address => bool)) isConfirmed;
    }

    /** @dev 저장소를 불러온다
      * @return ls 저장소
      */
    function appStorage() internal pure returns (AppStorage storage ls) {
        bytes32 position = STORAGE_POSITION;
        assembly { ls.slot := position }
    }

    /** @dev token storage를 설정한다
      * @param _newTokenStorage 설정할 token storage address
      */
    function setTokenStorage(address _newTokenStorage) internal {
        AppStorage storage ls = appStorage();
        ls.tokenStorage = _newTokenStorage;
    }

    /** @dev gateway를 설정한다
      * @param _newGateway 설정할 gateway address
      */
    function setGateway(address _newGateway) internal {
        AppStorage storage ls = appStorage();
        ls.gateway = _newGateway;
    }

    /** @dev 인증 조건을 설정한다
      * @param one 1인 인증 조건
      * @param two 2인 인증 조건
      */
    function setBoundary(uint256 one, uint256 two) internal {
        AppStorage storage ls = appStorage();
        ls.boundaryOne = one;
        ls.boundaryTwo = two;
    }

    /** @dev approver 추가
      * @param _newApprovers approver addresses
      */
    function addApprovers(address[] calldata _newApprovers) internal {
        AppStorage storage ls = appStorage();
        for(uint idx; idx < _newApprovers.length; idx++) {
            ls.approver[_newApprovers[idx]] = true;
        }
    }

    /** @dev approver 비활성화
      * @param _delApprovers approver addresses
      */
    function removeApprovers(address[] calldata _delApprovers) internal {
        AppStorage storage ls = appStorage();
        for(uint idx; idx < _delApprovers.length; idx++) {
            ls.approver[_delApprovers[idx]] = false;
        }
    }

    /** @dev deployed token contract address 설정
      * @param _deployed deployed token contract address
      */
    function setDeployedContract(address _deployed) internal {
        AppStorage storage ls = appStorage();
        ls.deployed = _deployed;
    } 

    /** @dev 입력된 트랜잭션을 저장
      * @param _txId 트랜잭션 키 
      * @param _to  trnasfer 트랜잭션을 보낼 address
      * @param _amount trnasfer 트랜잭션 보낼 값 
      * @param cnt approver count
      */
    function addTransaction(uint _txId, address _to, uint _amount, uint cnt) internal {
        AppStorage storage ls = appStorage();
        ls.transactions[_txId] = Transaction({
            requester: _to,
            amount: _amount,
            needConfirmation: cnt,
            numConfirmations: 0
        });
    }

    /** @dev 트랜잭션을 제거
      * @param _txId 트랜잭션 키 
      */
    function removeTransaction(uint _txId) internal {
        AppStorage storage ls = appStorage();
        delete ls.transactions[_txId]; 
    }
}