// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ForgottenRunesTricksOrTreats.sol";

contract ForgottenRunesTreats is ForgottenRunesTricksOrTreats {
    string constant name = "TREATS";

    constructor(string memory _uri) ERC1155(_uri) {}
}