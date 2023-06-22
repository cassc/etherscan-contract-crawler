// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ISdTokenV2 {
    function setMinterOperator(address _minter) external;
    function setBurnerOperator(address _burner) external;
}