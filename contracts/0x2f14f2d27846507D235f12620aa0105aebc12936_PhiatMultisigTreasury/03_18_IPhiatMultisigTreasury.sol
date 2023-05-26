// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IPhiatMultisigTreasury {
    function mintPhiat() external;

    function mintPhiatByTreasury(address account) external;

    function getReward() external;
}