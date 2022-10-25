// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.10;

import "./IPunkData.sol";
import "./IURIReturner.sol";

contract Punk is IURIReturner {
    
    IPunkData one;
    IPunkData two;

    constructor(address _one, address _two) {
        one = IPunkData(_one);
        two = IPunkData(_two);
    }

    function uri(uint256 id) external view returns (string memory) {
        return string(abi.encodePacked(one.quote(), two.quote()));
    }

}