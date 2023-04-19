// deployscript 5107fcb7552eafd7f45e5d52da8b277e6844dc1b
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "IVersion.sol";

abstract contract BaseVersion is IVersion {
    function _NAME() external view virtual returns (string memory) {
        return string(abi.encodePacked(this.NAME()));
    }
}