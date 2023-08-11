// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./Ownable.sol";

error ContractsCannotMint();
error NotAuthorized();
error SaleNotActive();
error WhitelistNotActive();

abstract contract Administrable is AccessControlEnumerable, Ownable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyOperator() {
        if (!hasRole(OPERATOR_ROLE, msg.sender)) revert NotAuthorized();
        _;
    }

    modifier onlyOperatorsAndOwner() {
        if (owner() != msg.sender && !hasRole(OPERATOR_ROLE, msg.sender))
            revert NotAuthorized();
        _;
    }

    modifier noContracts() {
        if (msg.sender != tx.origin) revert ContractsCannotMint();
        _;
    }

    bool public saleIsActive = false;
    bool public whitelistIsActive = false;

    function flipWhitelistState() external onlyOperatorsAndOwner {
        whitelistIsActive = !whitelistIsActive;
    }

    function flipSaleState() external onlyOperatorsAndOwner {
        saleIsActive = !saleIsActive;
    }

    modifier requireActiveSale() {
        if (!saleIsActive) revert SaleNotActive();
        _;
    }

    modifier requireActiveWhitelist() {
        if (!whitelistIsActive) revert WhitelistNotActive();
        _;
    }
}