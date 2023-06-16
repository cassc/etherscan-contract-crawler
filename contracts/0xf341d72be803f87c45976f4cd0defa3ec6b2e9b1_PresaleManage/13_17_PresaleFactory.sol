// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Presale.sol";

contract PresaleFactory {
    function deploy(
        address manage,
        address wethfact,
        address setting,
        address lockaddr
    ) external payable returns (PresaleV1) {
        return
            (new PresaleV1){value: msg.value}(
                manage,
                wethfact,
                setting,
                lockaddr
            );
    }
}