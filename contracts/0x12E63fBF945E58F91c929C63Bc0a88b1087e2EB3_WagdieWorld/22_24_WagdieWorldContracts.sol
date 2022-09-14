//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./WagdieWorldState.sol";

abstract contract WagdieWorldContracts is WagdieWorldState {

    function __WagdieWorldContracts_init() internal initializer {
        WagdieWorldState.__WagdieWorldState_init();
    }

    function setContracts(
        address _wagdieAddress,
        address _tokensOfConcordAddress)
    external
    requiresRole(OWNER_ROLE)
    {
        wagdie = IWagdie(_wagdieAddress);
        tokensOfConcord = ITokensOfConcord(_tokensOfConcordAddress);
    }

    modifier contractsAreSet() {
        require(areContractsSet(), "Contracts aren't set");
        _;
    }

    function areContractsSet() public view returns(bool) {
        return address(wagdie) != address(0)
            && address(tokensOfConcord) != address(0);
    }
}