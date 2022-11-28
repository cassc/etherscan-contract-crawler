// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/IDefiiFactory.sol";
import "./interfaces/IDefii.sol";


contract DefiiFactory is IDefiiFactory {
    address immutable _executor;
    address immutable public defiiImplementation;

    address[] public wallets;

    constructor(address defiiImplementation_, address executor_) {
        defiiImplementation = defiiImplementation_;
        _executor = executor_;
    }

    function executor() external view returns (address) {
        return _executor;
    }

    function createDefiiFor(address owner) public {
        address defii = Clones.cloneDeterministic(
            defiiImplementation,
            keccak256(abi.encodePacked(owner))
        );
        IDefii(defii).init(owner, address(this));
        wallets.push(owner);
    }

    function createDefii() external {
        createDefiiFor(msg.sender);
    }

    function getDefiiFor(address wallet) external view returns (address defii) {
        defii = Clones.predictDeterministicAddress(
            defiiImplementation,
            keccak256(abi.encodePacked(wallet)), address(this)
        );
    }
}