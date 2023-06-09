// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../core/SafeOwnable.sol";

contract MultiSignature is AccessControl {
    using SafeERC20 for IERC20;

    event NewReceiver(address _oldReceiver, address _newReceiver);
    event ApplyToken(address requester, uint amount, uint requestAt, uint expireAt, bytes32 salt);
    event AcceptApplyToken(address requester, uint amount, uint requestAt, uint expireAt, bytes32 salt, address acceptor, uint currentNum);
    event ProcessApplyToken(address requester, uint amount, uint requestAt, uint expireAt, bytes32 salt);
    event ApplySetReceiver(address requester, address receiver, uint requestAt, uint expireAt, bytes32 salt);
    event AcceptApplySetReceiver(address requester, address receiver, uint requestAt, uint expireAt, bytes32 salt, address acceptor, uint currentNum);
    event ProcessApplySetReceiver(address requester, address receiver, uint requestAt, uint expireAt, bytes32 salt);

    bytes32 public constant SIGNER_ROLE = keccak256("MULTI_SIGNATURE_SIGNER");

    address public receiver;
    IERC20 immutable reward;
    mapping(bytes32 => bool) public transactions;
    mapping(bytes32 => uint) public signatureNum;
    mapping(bytes32 => mapping(address => bool)) signatureRecord;
    uint256 public immutable SIGNATURE_MIN_NUM;

    constructor(IERC20 _reward, address _receiver, address[] memory _signaturer, uint _minNum) {
        reward = _reward; 
        require(_receiver != address(0), "receiver address is zero");
        receiver = _receiver;
        emit NewReceiver(address(0), receiver);
        for (uint256 i = 0; i < _signaturer.length; ++i) {
            require(!hasRole(SIGNER_ROLE, _signaturer[i]), "address already signature");
            _setupRole(SIGNER_ROLE, _signaturer[i]);
        }
        require(_minNum > 0 && _minNum <= _signaturer.length, "illegal minNum");
        SIGNATURE_MIN_NUM = _minNum;
    }

    function setSignature(address _newSignature) external {
        require(hasRole(SIGNER_ROLE, _msgSender()), "caller is not a signature");
        renounceRole(SIGNER_ROLE, _msgSender());
        _setupRole(SIGNER_ROLE, _newSignature);
    }

    function applyToken(uint amount, uint expireAt, bytes32 salt) external {
        bytes32 hash = keccak256(abi.encode(_msgSender(), amount, block.timestamp, expireAt, salt));
        require(!transactions[hash], "apply already request");
        transactions[hash] = true;
        signatureNum[hash] = 0;
        emit ApplyToken(msg.sender, amount, block.timestamp, expireAt, salt);
    }

    function acceptApplyToken(address _requester, uint _amount, uint _requestAt, uint _expireAt, bytes32 _salt) external {
        require(block.timestamp >= _requestAt && block.timestamp <= _expireAt, "illegal time");
        require(hasRole(SIGNER_ROLE, _msgSender()), "caller is not a signature");
        bytes32 hash = keccak256(abi.encode(_requester, _amount, _requestAt, _expireAt, _salt));
        require(transactions[hash], "apply not exists");
        require(!signatureRecord[hash][_msgSender()], "signature already accepted");
        signatureNum[hash] = signatureNum[hash] + 1;
        signatureRecord[hash][_msgSender()] = true;
        emit AcceptApplyToken(_requester, _amount, _requestAt, _expireAt, _salt, _msgSender(), signatureNum[hash]);
        if (signatureNum[hash] >= SIGNATURE_MIN_NUM) {
            reward.safeTransfer(receiver, _amount); 
            delete transactions[hash];
            delete signatureNum[hash];
            emit ProcessApplyToken(_requester, _amount, _requestAt, _expireAt, _salt);
        }
    }

    function applySetReceiver(address _receiver, uint expireAt, bytes32 salt) external {
        require(_receiver != address(0) && _receiver != receiver, "receiver is zero or the same");
        bytes32 hash = keccak256(abi.encode(_msgSender(), _receiver, block.timestamp, expireAt, salt));
        require(!transactions[hash], "apply already request");
        transactions[hash] = true;
        signatureNum[hash] = 0;
        emit ApplySetReceiver(msg.sender, _receiver, block.timestamp, expireAt, salt);
    }

    function acceptApplySetReceiver(address _requester, address _receiver, uint _requestAt, uint _expireAt, bytes32 _salt) external {
        require(block.timestamp >= _requestAt && block.timestamp <= _expireAt, "illegal time");
        require(hasRole(SIGNER_ROLE, _msgSender()), "caller is not a signature");
        bytes32 hash = keccak256(abi.encode(_requester, _receiver, _requestAt, _expireAt, _salt));
        require(transactions[hash], "apply not exists");
        require(!signatureRecord[hash][_msgSender()], "signature already accepted");
        signatureNum[hash] = signatureNum[hash] + 1;
        signatureRecord[hash][_msgSender()] = true;
        emit AcceptApplySetReceiver(_requester, _receiver, _requestAt, _expireAt, _salt, _msgSender(), signatureNum[hash]);
        if (signatureNum[hash] >= SIGNATURE_MIN_NUM) {
            emit NewReceiver(receiver, _receiver);
            receiver = _receiver;
            delete transactions[hash];
            delete signatureNum[hash];
            emit ProcessApplySetReceiver(_requester, _receiver, _requestAt, _expireAt, _salt);
        }
    }
}