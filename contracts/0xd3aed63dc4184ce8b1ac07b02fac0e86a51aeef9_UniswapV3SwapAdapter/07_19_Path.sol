//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

library Path {
    function buildPath(address[] memory path, uint24[] memory fee) internal pure returns (bytes memory) {
        require(path.length >= 2 && path.length <= 5, "Path: path length should between 2 and 5");
        require(path.length == fee.length + 1, "Path: path length should match fee length");
        if (path.length == 2) {
            return abi.encodePacked(path[0], fee[0], path[1]);
        } else if (path.length == 3) {
            return abi.encodePacked(path[0], fee[0], path[1], fee[1], path[2]);
        } else if (path.length == 4) {
            return abi.encodePacked(path[0], fee[0], path[1], fee[1], path[2], fee[2], path[3]);
        } else {
            return abi.encodePacked(path[0], fee[0], path[1], fee[1], path[2], fee[2], path[3], fee[3], path[4]);
        }
    }
}