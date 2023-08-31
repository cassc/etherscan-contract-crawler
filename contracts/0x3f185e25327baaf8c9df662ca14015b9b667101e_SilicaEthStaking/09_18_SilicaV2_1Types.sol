// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library SilicaV2_1Types {
    enum Status {
        Open,
        Running,
        Expired,
        Defaulted,
        Finished
    }
}