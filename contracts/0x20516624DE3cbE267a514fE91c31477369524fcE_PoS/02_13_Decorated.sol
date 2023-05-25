// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.7.0;


contract Decorated {
    // This contract defines several modifiers but does not use
    // them - they will be used in derived contracts.
    modifier onlyBy(address user) {
        require(msg.sender == user, "Cannot be called by user");
        _;
    }

    modifier onlyAfter(uint256 time) {
        require(block.timestamp > time, "Cannot be called now");
        _;
    }
}