// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IOracle.sol';

interface IOracleOffChain is IOracle {

    event NewValue(uint256 indexed timestamp, uint256 indexed value);

    function signer() external view returns (address);

    function delayAllowance() external view returns (uint256);

    function updateValue(
        uint256 timestamp,
        uint256 value,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

}