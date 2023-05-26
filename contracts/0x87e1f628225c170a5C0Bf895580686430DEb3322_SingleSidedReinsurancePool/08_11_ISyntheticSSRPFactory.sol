// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface ISyntheticSSRPFactory {
    function newSyntheticSSRP(address _owner, address _lpToken) external returns (address);
}