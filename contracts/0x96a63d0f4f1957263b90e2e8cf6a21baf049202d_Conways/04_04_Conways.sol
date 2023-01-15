/* SPDX-License-Identifier: MIT
..........
....[]....
......[]..
..[][][]..
..........
*/

pragma solidity 0.8.15;

import {IZooOfNeuralAutomata} from "../interfaces/IZooOfNeuralAutomata.sol";
import {Owned} from "../../lib/solmate/src/auth/Owned.sol";

contract Conways is Owned {
    address public zona;
    uint256 public startTime;

    mapping(address => bool) public claimed;

    constructor(
        address _owner, 
        address _zona, 
        uint256 _startTime
    ) Owned(_owner) {
        zona = _zona;
        startTime = _startTime;
    }

    function mint() external {
        require(startTime <= block.timestamp || msg.sender == owner);
        require(!claimed[msg.sender]);
        claimed[msg.sender] = true;
        IZooOfNeuralAutomata(zona).mint(msg.sender, 0, 1);
    }
}