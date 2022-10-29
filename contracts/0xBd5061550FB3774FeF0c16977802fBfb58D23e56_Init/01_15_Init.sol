//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";

import "./Setters.sol";

/// @dev This is a temporary contract used for the initialization of the base Bridge contract.
/// It's role is to set up the storage layout for the bridge and hide the initialize method.
/// To do that, the initialize method in this contract receives the bridge implementation address
/// as a parameter and upon initializing the contract's state, it immediately upgrades to this implementation.
contract Init is Setters, ERC1967Upgrade {
    constructor() initializer {}

    function initialize(
        address implementation,
        uint16 chainId_,
        uint16 hubChainId_,
        bytes32 governanceContract_,
        address[] calldata initialAuthorities
    ) external initializer {
        require(initialAuthorities.length > 0, "NO_AUTHORITIES");
        __Ownable_init();
        __Pausable_init();
        setAuthorities(initialAuthorities);
        setChainId(chainId_);
        setHubChainId(hubChainId_);
        setGovernanceContract(governanceContract_);
        _upgradeTo(implementation);
    }
}