// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract PaymentSplitterConnector is AccessControl {
    address public PAYMENT_SPLITTER_ADDRESS;
    address public PAYMENT_DEFAULT_ADMIN;
    address public SPLITTER_ADMIN;
    bytes32 private constant SPLITTER_ADMIN_ROLE = keccak256("SPLITTER_ADMIN");

    constructor(address admin, address splitterAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(SPLITTER_ADMIN_ROLE, admin);

        SPLITTER_ADMIN = admin;
        PAYMENT_DEFAULT_ADMIN = admin;
        PAYMENT_SPLITTER_ADDRESS = splitterAddress;
    }

    modifier onlySplitterAdmin() {
        require(
            hasRole(SPLITTER_ADMIN_ROLE, msg.sender),
            "Splitter: No Splitter Role"
        );
        _;
    }

    modifier onlyDefaultAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Splitter: No Admin Permission"
        );
        _;
    }

    function setSplitterAddress(address _splitterAddress)
        public
        onlySplitterAdmin
    {
        PAYMENT_SPLITTER_ADDRESS = _splitterAddress;
    }

    function withdraw() public {
        address payable recipient = payable(PAYMENT_SPLITTER_ADDRESS);
        uint256 balance = address(this).balance;

        Address.sendValue(recipient, balance);
    }

    function transferSplitterAdminRole(address admin) public onlyDefaultAdmin {
        require(SPLITTER_ADMIN != admin, "Splitter: Should be different");

        grantRole(SPLITTER_ADMIN_ROLE, admin);
        revokeRole(SPLITTER_ADMIN_ROLE, SPLITTER_ADMIN);
        SPLITTER_ADMIN = admin;
    }

    function transferDefaultAdminRole(address admin) public onlyDefaultAdmin {
        require(
            PAYMENT_DEFAULT_ADMIN != admin,
            "Splitter: Should be different"
        );

        grantRole(DEFAULT_ADMIN_ROLE, admin);
        revokeRole(DEFAULT_ADMIN_ROLE, PAYMENT_DEFAULT_ADMIN);
        PAYMENT_DEFAULT_ADMIN = admin;
    }
}