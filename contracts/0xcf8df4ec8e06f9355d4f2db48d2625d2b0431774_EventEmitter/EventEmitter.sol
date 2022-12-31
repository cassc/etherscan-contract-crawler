/**
 *Submitted for verification at Etherscan.io on 2022-12-30
*/

pragma solidity ^0.8.7;
//@SPDX-License-Identifier: UNLICENSED

interface RocketStorage {
    function getBool(bytes32 key) external view returns (bool);
}

contract EventEmitter {
    RocketStorage public rocketStorage;

    constructor(address _rocketStorage) {
        rocketStorage = RocketStorage(_rocketStorage);
    }

    event Event(address indexed callee, string metadata);

    function emitEvent(string memory metadata) public onlyRegisteredMember {
        emit Event(msg.sender, metadata);
    }

    modifier onlyRegisteredMember() {
        require(rocketStorage.getBool(keccak256(abi.encodePacked("dao.trustednodes.", "member", msg.sender))), "Wallet is not a registered trusted node");
        _;
    }
}