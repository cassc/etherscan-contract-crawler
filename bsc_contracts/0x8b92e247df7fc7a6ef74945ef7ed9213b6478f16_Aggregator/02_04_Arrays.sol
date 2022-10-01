// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Arrays {
    function last(uint256[] memory a) internal pure returns (uint256) {
        return a[a.length - 1];
    }
    
    function new2d(address a0, address a1) internal pure returns (address[] memory) {
        address[] memory res = new address[](2);
        res[0] = a0;
        res[1] = a1;
        return res;
    }

    function new3d(address a0, address a1, address a2) internal pure returns (address[] memory) {
        address[] memory res = new address[](3);
        res[0] = a0;
        res[1] = a1;
        res[2] = a2;
        return res;
    }
    function getLastUint(bytes memory data) internal pure returns (uint res) {
        require(data.length >= 32, "Arrays::getLastUint: Cannot get last uint");
        uint i = data.length - 32;
        assembly {
            res := mload(add(data, add(0x20, i)))
        }
    }
}