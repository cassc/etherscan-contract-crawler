// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../HandlerBase.sol";

contract HMath is HandlerBase {
    function getContractName() public pure override returns (string memory) {
        return "HMath";
    }

    function add(uint256 a, uint256 b) external payable returns (uint256 ret) {
        ret = a + b;
    }

    function addMany(
        uint256[] calldata a
    ) external payable returns (uint256 ret) {
        for (uint256 i; i < a.length; ) {
            ret += a[i];
            unchecked {
                ++i;
            }
        }
    }

    function sub(uint256 a, uint256 b) external payable returns (uint256 ret) {
        ret = a - b;
    }
}