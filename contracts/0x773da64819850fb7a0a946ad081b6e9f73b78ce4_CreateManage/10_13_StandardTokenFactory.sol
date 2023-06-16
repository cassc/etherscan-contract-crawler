// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./StandardToken.sol";

contract StandardTokenFactory {
    function deploy(
        address creator_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 tokenSupply_,
        SharedStructs.status memory _state
    ) external returns (StandardToken) {
        return
            new StandardToken(
                creator_,
                name_,
                symbol_,
                decimals_,
                tokenSupply_,
                _state
            );
    }
}