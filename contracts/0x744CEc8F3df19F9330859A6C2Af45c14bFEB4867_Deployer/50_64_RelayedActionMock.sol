// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@mimic-fi/v2-helpers/contracts/utils/Denominations.sol';

import '../../actions/RelayedAction.sol';

contract RelayedActionMock is RelayedAction {
    // Cost in gas of a call op + gas cost computation + withdraw form SV
    uint256 public constant override BASE_GAS = 21e3 + 20e3;

    address public token;

    constructor(address admin, address registry) BaseAction(admin, registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function setToken(address _token) external {
        token = _token;
    }

    function call() external redeemGas(token) {
        // solhint-disable-previous-line no-empty-blocks
    }
}