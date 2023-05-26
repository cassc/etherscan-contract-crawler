// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

contract Killable is Ownable {

    mapping(uint => uint256) internal _killedFunctions;

    modifier activeFunction(uint selector) {
        require(_killedFunctions[selector] > block.timestamp || _killedFunctions[selector] == 0, "deactivated");
        _;
    }

    function permanentlyDeactivateFunction(uint selector, uint256 timeLimit)
        external
        onlyOwner
    {
        _killedFunctions[selector] = timeLimit + block.timestamp;
    }
}