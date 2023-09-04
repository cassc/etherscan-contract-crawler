// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../libraries/LibDiamond.sol";
import "../libraries/LibAppStore.sol";

contract TransferFacet {
    event SaveTransferRequest(address requester, uint amount, uint txid);
    event ConfirmTransaction(address signer, uint txid);
    event ExecuteTransaction(address requester, uint amount, uint txid, string result);
    event RevokeTransaction(address signer, uint txId);

    /** @dev 유효한 gateway address인지 확인 */
    modifier onlyGateway() {
        LibAppStore.AppStorage storage ls = LibAppStore.appStorage();
        require(ls.gateway == msg.sender, "not valid address");
        _;
    }

    /** @dev 유효한 approver address인지 확인 */
    modifier onlySigner() {
        LibAppStore.AppStorage storage ls = LibAppStore.appStorage();
        require(ls.approver[msg.sender], "not valid address");
        _;
    }

    /** @dev 유효한 트랜잭션인지 확인 
      * @param _txId 트랜잭션 키
    */
    modifier txExists(uint _txId) {
        LibAppStore.AppStorage storage ls = LibAppStore.appStorage();
        require(ls.transactions[_txId].amount > 0, "tx is not exist");
        _;
    }

    /** @dev 입력된 트랜잭션을 저장하고, 조건에 맞으면 실행
      * @param _txId 트랜잭션 키 
      * @param _to  trnasfer 트랜잭션을 보낼 address
      * @param _amount trnasfer 트랜잭션 보낼 값 
      */
    function addTransaction(
        uint _txId,
        address _to,
        uint _amount
    ) external onlyGateway {
        LibAppStore.AppStorage storage ls = LibAppStore.appStorage();
        if(_amount > ls.boundaryTwo) {
            LibAppStore.addTransaction(_txId, _to, _amount, 2);
            emit SaveTransferRequest(_to, _amount, _txId);
        } else if(_amount > ls.boundaryOne) {
            LibAppStore.addTransaction(_txId, _to, _amount, 1);
            emit SaveTransferRequest(_to, _amount, _txId);
        } else {
            (bool success, bytes memory returnData) = ls.deployed.call(abi.encodeWithSignature("transfer(address,uint256)", _to, _amount));
            require(success, string(returnData));
            emit ExecuteTransaction(_to, _amount, _txId, string(returnData));
        }
    }

    /** @dev 트랜잭션을 승인하고, 조건에 맞으면 실행 
      * @param _txId 트랜잭션 키 
      */
    function confirmTransaction(
        uint _txId
    ) external onlySigner txExists(_txId) {
        LibAppStore.AppStorage storage ls = LibAppStore.appStorage();
        LibAppStore.Transaction storage transaction = ls.transactions[_txId];
        transaction.numConfirmations += 1;
        ls.isConfirmed[_txId][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txId);
        if(transaction.numConfirmations >= transaction.needConfirmation) {
            executeTransaction(_txId);
        }
    }

    /** @dev 트랜잭션 실행하고 성공하면 트랜잭션을 제거
      * @param _txId 트랜잭션 키 
      */
    function executeTransaction(
        uint _txId
    ) internal txExists(_txId) {
        LibAppStore.AppStorage storage ls = LibAppStore.appStorage();
        LibAppStore.Transaction storage t = ls.transactions[_txId];

        (bool success, bytes memory returnData) = ls.deployed.call(abi.encodeWithSignature("transfer(address,uint256)", t.requester, t.amount));
        require(success, string(returnData));

        emit ExecuteTransaction(t.requester, t.amount, _txId, string(returnData));

        LibAppStore.removeTransaction(_txId);
    }

    /** @dev 트랜잭션 반려하고 트랜잭션을 제거
      * @param _txId 트랜잭션 키 
      */
    function revokeTransaction(
        uint _txId
    ) external onlySigner txExists(_txId) {
        LibAppStore.removeTransaction(_txId);

        emit RevokeTransaction(msg.sender, _txId);
    }
}