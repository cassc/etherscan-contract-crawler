//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Create3.sol";

contract Child {
    uint256 meaningOfLife;
    address owner;

    constructor(uint256 _meaning, address _owner) {
        meaningOfLife = _meaning;
        owner = _owner;
    }
}

contract Deployer {
    function deployChild() external {
        Create3.create3(
            keccak256("101"),
            abi.encodePacked(
                type(Child).creationCode,
                abi.encode(
                    42,
                    msg.sender
                )
            )
        );
    }
}