/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: Apache-2.0
*/
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./Subaccount.sol";

pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

contract SubaccountFactory {
    // ========== storage ==========

    // Subaccount template that can be cloned
    address immutable template;
    address immutable dealer;

    // Subaccount can only be added.
    mapping(address => address[]) subaccountRegistry;

    // ========== event ==========

    event NewSubaccount(
        address indexed master,
        uint256 subaccountIndex,
        address subaccountAddress
    );

    // ========== constructor ==========

    constructor(address _dealer) {
        template = address(new Subaccount());
        dealer = _dealer;
        Subaccount(template).init(address(this), dealer);
    }

    // ========== functions ==========

    /// @notice https://eips.ethereum.org/EIPS/eip-1167[EIP 1167]
    /// is a standard protocol for deploying minimal proxy contracts,
    /// also known as "clones".
    function newSubaccount() external returns (address subaccount) {
        subaccount = Clones.clone(template);

        Subaccount(subaccount).init(msg.sender, dealer);
        subaccountRegistry[msg.sender].push(subaccount);
        emit NewSubaccount(
            msg.sender,
            subaccountRegistry[msg.sender].length - 1,
            subaccount
        );
    }

    function getSubaccounts(address master)
        external
        view
        returns (address[] memory)
    {
        return subaccountRegistry[master];
    }

    function getSubaccount(address master, uint256 index)
        external
        view
        returns (address)
    {
        return subaccountRegistry[master][index];
    }
}