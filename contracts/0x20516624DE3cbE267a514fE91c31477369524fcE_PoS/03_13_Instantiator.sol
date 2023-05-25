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


interface Instantiator {

    modifier onlyInstantiated(uint256 _index) virtual;

    modifier onlyActive(uint256 _index) virtual;

    modifier increasesNonce(uint256 _index) virtual;

    function isActive(uint256 _index) external view returns (bool);

    function getNonce(uint256 _index) external view returns (uint256);

    function isConcerned(uint256 _index, address _user) external view returns (bool);

    function getSubInstances(uint256 _index, address) external view returns (address[] memory _addresses, uint256[] memory _indices);
}