// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./CrowdPool.sol";

contract CrowdPoolFactory {
    function deploy(
        address manage,
        address wethfact,
        address setting,
        address lockaddr
    ) external payable returns (CrowdPoolV1) {
        return
            (new CrowdPoolV1){value: msg.value}(
                manage,
                wethfact,
                setting,
                lockaddr
            );
    }
}