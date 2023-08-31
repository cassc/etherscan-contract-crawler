// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IBaseOracle {
    function quote(
        address token,
        uint256 amount,
        bytes memory securityParams
    ) external view returns (address[] memory tokens, uint256[] memory prices);
}