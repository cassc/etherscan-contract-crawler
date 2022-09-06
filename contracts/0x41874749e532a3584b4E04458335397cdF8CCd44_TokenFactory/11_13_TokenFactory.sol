// SPDX-License-Identifier: MIT
// solium-disable linebreak-style
pragma solidity 0.8.15;

import "../tokens/DepositToken.sol";
import "../utils/Interfaces.sol";

contract TokenFactory is ITokenFactory {
    error Unauthorized();

    address public immutable operator;

    constructor(address _operator) {
        operator = _operator;
    }

    function createDepositToken(address _lptoken) external returns (address) {
        if (msg.sender != operator) {
            revert Unauthorized();
        }
        DepositToken dtoken = new DepositToken(msg.sender, _lptoken);
        return address(dtoken);
    }
}