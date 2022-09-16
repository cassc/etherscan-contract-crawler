// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";

contract RevenuePath is PaymentSplitterUpgradeable {

    string public walletName;

    function initialize(address[] memory payees, uint256[] memory shares, string memory name) initializer public {
        super.__PaymentSplitter_init(payees, shares);

        walletName = name;
    }


}