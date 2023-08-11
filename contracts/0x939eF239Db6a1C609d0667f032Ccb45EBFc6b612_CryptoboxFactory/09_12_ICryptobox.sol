// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Participation} from "./lib/Participation.sol";

interface ICryptobox {
    struct Info {
        address token;
        uint32 capacity;
        uint256 prize;
    }

    function info() external view returns (ICryptobox.Info memory);

    function isActive() external view returns (bool);

    function participants() external view returns (uint32);

    function participated(
        Participation.Participant calldata
    ) external view returns (bool);

    function dispense(
        Participation.Participant calldata,
        Participation.Signature calldata
    ) external;

    function dispenseMany(
        Participation.Participant[] calldata,
        Participation.Signature calldata
    ) external;

    function stop() external;

    event CryptoboxFinished();
    event CryptoboxStopped();
}