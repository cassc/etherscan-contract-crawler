// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IDelegationPod.sol";
import "./IDelegatedShare.sol";

interface ITokenizedDelegationPod is IDelegationPod {
    event RegisterDelegatee(address delegatee);

    function register(string memory name, string memory symbol) external returns(IDelegatedShare shareToken);
    function registration(address account) external returns(IDelegatedShare shareToken);
}