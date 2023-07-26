/**
 *Submitted for verification at Etherscan.io on 2023-03-26
*/

// SPDX-License-Identifier: MIT

// Copyright (c) 2023 Sebastian Supreme

// IPFS CID Database Version 2.0

pragma solidity ^0.8.0;

contract IpfsCidDatabaseV2 {

    struct Element {
        string name;
        string bafybei_cid;
        string bafkrei_cid;
    }

    address public administrator;
    uint256 public counter;
    mapping(uint256 => Element) elements;

    event newElementAdded(uint256 index, Element new_element);

    constructor() {
        administrator = msg.sender;
        counter = 0;
    }

    function getElement(uint256 _index) public view returns(Element memory) {
        return elements[_index];
    }

    function addElement(string memory _name, string memory _bafybei_cid, string memory _bafkrei_cid) public {
        require(msg.sender == administrator, "Access denied. Only the administrator can add new elements.");
        elements[counter] = Element(_name, _bafybei_cid, _bafkrei_cid);
        emit newElementAdded(counter, elements[counter]);
        counter++;
    }

}