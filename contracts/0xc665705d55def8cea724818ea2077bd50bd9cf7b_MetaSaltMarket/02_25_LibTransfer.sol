// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

library LibTransfer {
    function transferEth1(address to, uint value) internal {
        (bool success,) = to.call{ value: value }("");
        require(success, "transfer failed1");
    }

    function transferEth2(address to, uint value) internal {
        (bool success,) = to.call{ value: value }("");
        require(success, "transfer failed2");
    }

    function transferEth3(address to, uint value) internal {
        (bool success,) = to.call{ value: value }("");
        require(success, "transfer failed3");
    }

    function transferEth4(address to, uint value) internal {
        (bool success,) = to.call{ value: value }("");
        require(success, "transfer failed4");
    }
}