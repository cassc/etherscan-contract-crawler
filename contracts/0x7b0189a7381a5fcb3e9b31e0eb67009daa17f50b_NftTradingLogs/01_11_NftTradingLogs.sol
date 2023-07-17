// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract NftTradingLogs is Context,  AccessControlEnumerable{

    event TradingLog(
        bytes32 TxnHash,
        address From,
        address To,
        address Contract,
        uint256 TokenID,
        string Price,
        string ServiceCharge,
        string ActualReceived
    );

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    modifier onlyAdmin(bytes32 role) {
        require(
            hasRole(role, _msgSender()),
            "Permission denied"
        );
        _;
    }

    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OPERATOR_ROLE, _msgSender());
    }

    function addTradingLog(
        bytes32 TxnHash,
        address From,
        address To,
        address Contract,
        uint256 TokenID,
        string calldata Price,
        string calldata ServiceCharge,
        string calldata ActualReceived
    ) external onlyAdmin(OPERATOR_ROLE){
        emit TradingLog(
            TxnHash,
            From,
            To,
            Contract,
            TokenID,
            Price,
            ServiceCharge,
            ActualReceived
        );
    }
}