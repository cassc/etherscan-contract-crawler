// SPDX-License-Identifier: MIT

// pragma solidity 0.6.12;
pragma solidity >=0.4.22 <0.9.0;

contract Governable {
    address public gov;

    constructor() public {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}