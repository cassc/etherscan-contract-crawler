// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/proxy/Clones.sol";

import "./Shardwallet.sol";

contract ShardwalletFactory {
    event ShardwalletCreation(Shardwallet shardwallet, address owner);

    Shardwallet immutable implementation_;

    constructor() {
        implementation_ = new Shardwallet();
        // Lock the master copy just to prevent shenanigans. (Doesn't actually
        // affect the integrity of clones.)
        implementation_.initialize(address(this), "", "");
    }

    function summon(
        bytes32 salt,
        string calldata name,
        string calldata symbol
    ) external returns (Shardwallet) {
        if (bytes20(salt) != bytes20(msg.sender)) {
            // Prevent mempool salt sniping.
            revert("ShardwalletFactory: unauthorized");
        }
        address clone = Clones.cloneDeterministic(
            address(implementation_),
            salt
        );
        Shardwallet sw = Shardwallet(payable(clone));
        sw.initialize(msg.sender, name, symbol);
        emit ShardwalletCreation(sw, msg.sender);
        return sw;
    }

    function implementation() external view returns (Shardwallet) {
        return implementation_;
    }

    function predictAddress(bytes32 salt) external view returns (address) {
        return
            Clones.predictDeterministicAddress(address(implementation_), salt);
    }
}