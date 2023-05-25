// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Wad and Ray Math library
/// @dev Math operations for wads (fixed point with 18 digits) and rays (fixed points with 27 digits)
pragma solidity ^0.8.0;

library WadRayMath {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant RATIO = 1e9;

    function wmul(uint256 a, uint256 b) internal pure returns (uint256) {
        return ((WAD / 2) + (a * b)) / WAD;
    }

    function wdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 halfB = b / 2;
        return (halfB + (a * WAD)) / b;
    }

    function rmul(uint256 a, uint256 b) internal pure returns (uint256) {
        return ((RAY / 2) + (a * b)) / RAY;
    }

    function rdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 halfB = b / 2;
        return (halfB + (a * RAY)) / b;
    }

    function ray2wad(uint256 a) internal pure returns (uint256) {
        uint256 halfRatio = RATIO / 2;
        return (halfRatio + a) / RATIO;
    }

    function wad2ray(uint256 a) internal pure returns (uint256) {
        return a * RATIO;
    }
}