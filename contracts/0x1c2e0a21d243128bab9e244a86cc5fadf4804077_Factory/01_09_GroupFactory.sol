// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "./Buffer.sol";

contract Factory {
    address public immutable implementation;
    event ContractDeployed(
        address indexed owner,
        address indexed group,
        string title
    );

    constructor() {
        implementation = address(new Buffer());
    }

    function genesis(
        string memory title,
        address _owner
    ) external returns (address) {
        address payable clone = payable(
            ClonesUpgradeable.clone(implementation)
        );
        Buffer b = Buffer(clone);
        b.initialize(
            _owner
        );
        emit ContractDeployed(msg.sender, clone, title);
        return clone;
    }
}