// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "./LockRequestable.sol";

struct AdminUpdateRequest {
    address proposed;
}

contract Registry is LockRequestable {

    address public custodian;

    mapping(bytes32 => AdminUpdateRequest) public custodianChangeReqs;

    event CustodianChangeRequested(
        bytes32 _lockId,
        address _msgSender,
        address _proposedCustodian,
        uint256 _lockRequestIdx
    );
    event CustodianChangeConfirmed(bytes32 _lockId, address _newCustodian);

    mapping(address => address) public _validSenderSet;
    uint256 public setSize;
    address constant GUARD = address(1);

    mapping(bytes32 => AdminUpdateRequest) public ownerAddReqs;

    event ValidSenderAddRequested(
        bytes32 _lockId,
        address _msgSender,
        address _proposed,
        uint256 _lockRequestIdx
    );
    event ValidSenderAddConfirmed(bytes32 _lockId, address _newValidSender);
    
    string internal constant ERROR_INVALID_MSG_SENDER = "Invalid msg.sender";

    constructor(address custodian_, address[] memory validSenders_) LockRequestable() {
        custodian = custodian_;
        _validSenderSet[GUARD] = GUARD;
        for(uint256 i = 0; i < validSenders_.length; i++) {
            address sender = validSenders_[i];
            _addValidSender(sender);
        }
    }

    modifier onlyCustodian {
        require(msg.sender == custodian, ERROR_INVALID_MSG_SENDER);
        _;
    }

    function _requireOnlyValidSender() internal view {       
        require(isValidSender(msg.sender), ERROR_INVALID_MSG_SENDER);
    }

    function confirmCustodianChange(bytes32 lockId) external onlyCustodian {
        custodian = _getRequest(custodianChangeReqs, lockId);
        delete custodianChangeReqs[lockId];
        emit CustodianChangeConfirmed(lockId, custodian);
    }

    function confirmValidSenderAdd(bytes32 lockId) external onlyCustodian {
        address proposed = _getRequest(ownerAddReqs, lockId);
        _addValidSender(proposed);
        delete ownerAddReqs[lockId];
        emit ValidSenderAddConfirmed(lockId, proposed);
    }

    function _getRequest(mapping(bytes32 => AdminUpdateRequest) storage _m, bytes32 _lockId) private view returns (address proposed) {
        AdminUpdateRequest storage adminRequest = _m[_lockId];
        // reject ‘null’ results from the map lookup
        // this can only be the case if an unknown `_lockId` is received
        require(adminRequest.proposed != address(0), "no such lockId");
        return adminRequest.proposed;
    }

    function _requestChange(mapping(bytes32 => AdminUpdateRequest) storage _m, bytes4 _selector, address _proposed) private returns (bytes32 lockId, uint256 lockRequestIdx) {
        require(_proposed != address(0), "zero address");

        (bytes32 preLockId, uint256 idx) = generatePreLockId();
        lockId = keccak256(
            abi.encodePacked(
                preLockId,
                _selector,
                _proposed
            )
        );
        lockRequestIdx = idx;

        _m[lockId] = AdminUpdateRequest({
            proposed : _proposed
        });
    }

    function requestCustodianChange(address _proposedCustodian) external returns (bytes32 lockId) {
        (bytes32 preLockId, uint256 lockRequestIdx) = _requestChange(custodianChangeReqs, this.requestCustodianChange.selector, _proposedCustodian);
        emit CustodianChangeRequested(preLockId, msg.sender, _proposedCustodian, lockRequestIdx);
        return preLockId;
    }

    function requestValidSenderAdd(address _sender) external returns (bytes32 lockId) {
        (bytes32 preLockId, uint256 lockRequestIdx) = _requestChange(ownerAddReqs, this.requestValidSenderAdd.selector, _sender);
        emit ValidSenderAddRequested(preLockId, msg.sender, _sender, lockRequestIdx);
        return preLockId;
    }

    function _getPrevSender(address student) private view returns(address) {
        address currentAddress = GUARD;
        while(_validSenderSet[currentAddress] != GUARD) {
            if (_validSenderSet[currentAddress] == student) {
                return currentAddress;
            }
            currentAddress = _validSenderSet[currentAddress];
        }
        return address(0);
    }

    function removeValidSender(address sender) external {
        _requireOnlyValidSender();
        _removeValidSender(sender);
    }

    function removeAllValidSenders() external {
        _requireOnlyValidSender();
        address currentAddress = GUARD;
        while(_validSenderSet[currentAddress] != GUARD) {
            address sender = _validSenderSet[currentAddress];
            _removeValidSender(sender);
        }
    }

    function isValidSender(address sender) public view returns (bool) {
        return _validSenderSet[sender] != address(0);
    }

    function _addValidSender(address sender) private {
        require(!isValidSender(sender));
        _validSenderSet[sender] = _validSenderSet[GUARD];
        _validSenderSet[GUARD] = sender;
        setSize++;
    }

    function _removeValidSender(address sender) private {
        address prevSender = _getPrevSender(sender);
        _validSenderSet[prevSender] = _validSenderSet[sender];
        _validSenderSet[sender] = address(0);
        setSize--;
    }

    function getValidSenderSet() public view returns (address[] memory) {
        address[] memory validSenderList = new address[](setSize);
        address currentAddress = _validSenderSet[GUARD];
        for(uint256 i = 0; currentAddress != GUARD; ++i) {
            validSenderList[i] = currentAddress;
            currentAddress = _validSenderSet[currentAddress];
        }
        return validSenderList; 
    }

}