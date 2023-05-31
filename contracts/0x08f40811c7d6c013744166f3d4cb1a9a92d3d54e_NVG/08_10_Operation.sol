// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IOperation.sol";
import "./Ownables.sol";

abstract contract Operation is IOperation, Ownables {
    struct Op {
        bool isAuthorized;
        bool isVaild;
        mapping(address => bool) auth;
    }
    mapping(bytes32 => Op) private _operation_hash;

    modifier Existential(bytes32 opHash) {
        _checkOperation(opHash);
        _;
    }

    modifier Complete(bytes32 opHash) {
        _;
        address[2] memory _o = Owners();
        if ((_operation_hash[opHash].auth[_o[0]] == true) && (_operation_hash[opHash].auth[_o[1]] == true)) {
            _operation_hash[opHash].isAuthorized = true;
            emit AllDone(opHash);
        }
    }

    function _closeOperation(bytes32 opHash) private {
        delete (_operation_hash[opHash]);
    }

    function _checkOperation(bytes32 opHash) internal view virtual {
        require(_operation_hash[opHash].isVaild == true, "Operation: operation does not exist");
    }

    function _checkAuthorization(bytes32 opHash) internal virtual {
        require(_operation_hash[opHash].isAuthorized == true, "Operation: authorization is not complete");
        _closeOperation(opHash);
    }

    function authorizedOperation(bytes32 opHash) public onlyOwner Existential(opHash) Complete(opHash) {
        require(_operation_hash[opHash].auth[_msgSender()] == false, "Operation: do not repeat the operation");
        _operation_hash[opHash].auth[_msgSender()] = true;
        emit AuthorizedOperation(_msgSender(), opHash);
    }

    function applicationOperation(bytes32 opHash) public {
        require(_operation_hash[opHash].isVaild == false, "Operation: operation already exists");
        _operation_hash[opHash].isVaild = true;
        emit ApplicationOperation(_msgSender(), opHash);
    }
}