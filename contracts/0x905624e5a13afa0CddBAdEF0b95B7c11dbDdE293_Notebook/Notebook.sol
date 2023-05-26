/**
 *Submitted for verification at Etherscan.io on 2023-03-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Notebook {

    address public administrator;
    uint256 public counter;
    mapping(uint256 => string) notes;

    event newNote(uint256 index, string note);

    constructor() {
        administrator = msg.sender;
        counter = 0;
    }

    function readNote(uint256 _index) public view returns(string memory) {
        return notes[_index];
    }

    function writeNote(string memory _note) public {
        require(msg.sender == administrator, "Access denied.");
        notes[counter] = _note;
        emit newNote(counter, notes[counter]);
        counter++;
    }

}