// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../core/TimeLocker.sol";

contract TokenControllerMultiSignature is AccessControl {

    event NewTimeLocker(address oldTimeLocker, address newTimeLocker);
    event ApplyAddMinter(address requester, address minter, uint maxAmount, uint requestAt, uint expireAt, bytes32 salt);
    event AcceptAddMinter(address requester, address minter, uint maxAmount, uint requestAt, uint expireAt, bytes32 salt, address acceptor, uint currentNum);
    event ApplyDelMinter(address requester, address minter, uint requestAt, uint expireAt, bytes32 salt);
    event AcceptDelMinter(address requester, address minter, uint requestAt, uint expireAt, bytes32 salt, address acceptor, uint currentNum);
    event ApplySetPendingOwner(address requester, address owner, uint requestAt, uint expireAt, bytes32 salt);
    event AcceptSetPendingOwner(address requester, address owner, uint requestAt, uint expireAt, bytes32 salt, address acceptor, uint currentNum);

    bytes32 public constant SIGNER_ROLE = keccak256("MULTI_SIGNATURE_SIGNER");

    IERC20 public token;
    TimeLocker public timeLocker;
    mapping(bytes32 => bool) public transactions;
    mapping(bytes32 => uint) public signatureNum;
    mapping(bytes32 => mapping(address => bool)) signatureRecord;
    uint256 public immutable SIGNATURE_MIN_NUM;

    constructor(IERC20 _token, address[] memory _signaturer, uint _minNum) {
        require(address(_token) != address(0), "illegal token");
        token = _token;
        for (uint256 i = 0; i < _signaturer.length; ++i) {
            require(!hasRole(SIGNER_ROLE, _signaturer[i]), "address already signature");
            _setupRole(SIGNER_ROLE, _signaturer[i]);
        }
        require(_minNum > 0 && _minNum <= _signaturer.length, "illegal minNum");
        SIGNATURE_MIN_NUM = _minNum;
    }

    function setTimeLocker(TimeLocker _timeLocker) external {
        require(address(timeLocker) == address(0), "already be setted");
        timeLocker = _timeLocker;
        emit NewTimeLocker(address(0), address(timeLocker));
    }

    function setSignature(address _newSignature) external {
        require(hasRole(SIGNER_ROLE, _msgSender()), "caller is not a signature");
        renounceRole(SIGNER_ROLE, _msgSender());
        _setupRole(SIGNER_ROLE, _newSignature);
    }

    function applyAddMinter(address minter, uint maxAmount, uint expireAt, bytes32 salt) external {
        bytes32 hash = keccak256(abi.encode(_msgSender(), minter, maxAmount, block.timestamp, expireAt, salt));
        require(!transactions[hash], "apply already request");
        transactions[hash] = true;
        signatureNum[hash] = 0;
        emit ApplyAddMinter(msg.sender, minter, maxAmount, block.timestamp, expireAt, salt);
    }

    function acceptAddMinter(address _requester, address _minter, uint _maxAmount, uint _requestAt, uint _expireAt, bytes32 _salt) external {
        require(block.timestamp >= _requestAt && block.timestamp <= _expireAt, "illegal time");
        require(hasRole(SIGNER_ROLE, _msgSender()), "caller is not a signature");
        bytes32 hash = keccak256(abi.encode(_requester, _minter, _maxAmount, _requestAt, _expireAt, _salt));
        require(transactions[hash], "apply not exists");
        require(!signatureRecord[hash][_msgSender()], "signature already accepted");
        signatureNum[hash] = signatureNum[hash] + 1;
        signatureRecord[hash][_msgSender()] = true;
        emit AcceptAddMinter(_requester, _minter, _maxAmount, _requestAt, _expireAt, _salt, _msgSender(), signatureNum[hash]);
        if (signatureNum[hash] >= SIGNATURE_MIN_NUM) {
            timeLocker.schedule(address(token), 0, abi.encodeWithSignature("addMinter(address,uint256)", _minter, _maxAmount), bytes32(0), _salt, timeLocker.getMinDelay());
        }
    }

    function executeAddMinter(address _minter, uint _maxAmount,  bytes32 _salt) external {
        timeLocker.execute(address(token), 0, abi.encodeWithSignature("addMinter(address,uint256)", _minter, _maxAmount), bytes32(0), _salt); 
    }

    function applyDelMinter(address minter, uint expireAt, bytes32 salt) external {
        bytes32 hash = keccak256(abi.encode(_msgSender(), minter, block.timestamp, expireAt, salt));
        require(!transactions[hash], "apply already request");
        transactions[hash] = true;
        signatureNum[hash] = 0;
        emit ApplyDelMinter(msg.sender, minter, block.timestamp, expireAt, salt);
    }

    function acceptDelMinter(address _requester, address _minter, uint _requestAt, uint _expireAt, bytes32 _salt) external {
        require(block.timestamp >= _requestAt && block.timestamp <= _expireAt, "illegal time");
        require(hasRole(SIGNER_ROLE, _msgSender()), "caller is not a signature");
        bytes32 hash = keccak256(abi.encode(_requester, _minter, _requestAt, _expireAt, _salt));
        require(transactions[hash], "apply not exists");
        require(!signatureRecord[hash][_msgSender()], "signature already accepted");
        signatureNum[hash] = signatureNum[hash] + 1;
        signatureRecord[hash][_msgSender()] = true;
        emit AcceptDelMinter(_requester, _minter, _requestAt, _expireAt, _salt, _msgSender(), signatureNum[hash]);
        if (signatureNum[hash] >= SIGNATURE_MIN_NUM) {
            timeLocker.schedule(address(token), 0, abi.encodeWithSignature("delMinter(address)", _minter), bytes32(0), _salt, timeLocker.getMinDelay());
        }
    }

    function executeDelMinter(address _minter,  bytes32 _salt) external {
        timeLocker.execute(address(token), 0, abi.encodeWithSignature("delMinter(address)", _minter), bytes32(0), _salt); 
    }
    function applySetPendingOwner(address owner, uint expireAt, bytes32 salt) external {
        bytes32 hash = keccak256(abi.encode(_msgSender(), owner, block.timestamp, expireAt, salt));
        require(!transactions[hash], "apply already request");
        transactions[hash] = true;
        signatureNum[hash] = 0;
        emit ApplySetPendingOwner(msg.sender, owner, block.timestamp, expireAt, salt);
    }

    function acceptSetPendingOwner(address _requester, address _owner, uint _requestAt, uint _expireAt, bytes32 _salt) external {
        require(block.timestamp >= _requestAt && block.timestamp <= _expireAt, "illegal time");
        require(hasRole(SIGNER_ROLE, _msgSender()), "caller is not a signature");
        bytes32 hash = keccak256(abi.encode(_requester, _owner, _requestAt, _expireAt, _salt));
        require(transactions[hash], "apply not exists");
        require(!signatureRecord[hash][_msgSender()], "signature already accepted");
        signatureNum[hash] = signatureNum[hash] + 1;
        signatureRecord[hash][_msgSender()] = true;
        emit AcceptSetPendingOwner(_requester, _owner, _requestAt, _expireAt, _salt, _msgSender(), signatureNum[hash]);
        if (signatureNum[hash] >= SIGNATURE_MIN_NUM) {
            timeLocker.schedule(address(token), 0, abi.encodeWithSignature("setPendingOwner(address)", _owner), bytes32(0), _salt, timeLocker.getMinDelay());
        }
    }

    function executeSetPendingOwner(address _owner,  bytes32 _salt) external {
        timeLocker.execute(address(token), 0, abi.encodeWithSignature("setPendingOwner(address)", _owner), bytes32(0), _salt); 
    }
}