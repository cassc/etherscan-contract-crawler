/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

abstract contract SimpleAdminable {
    address owner;
    address ownerCandidate;
    mapping(address => bool) admins;

    constructor() internal {
        owner = msg.sender;
        admins[msg.sender] = true;
    }

    // Admin/Owner Modifiers.
    modifier onlyOwner() {
        require(isOwner(msg.sender), "ONLY_OWNER");
        _;
    }

    function isOwner(address testedAddress) public view returns (bool) {
        return owner == testedAddress;
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "ONLY_ADMIN");
        _;
    }

    function isAdmin(address testedAddress) public view returns (bool) {
        return admins[testedAddress];
    }

    function registerAdmin(address newAdmin) external onlyOwner {
        if (!isAdmin(newAdmin)) {
            admins[newAdmin] = true;
        }
    }

    function removeAdmin(address removedAdmin) external onlyOwner {
        require(!isOwner(removedAdmin), "OWNER_CANNOT_BE_REMOVED_AS_ADMIN");
        delete admins[removedAdmin];
    }

    function nominateNewOwner(address newOwner) external onlyOwner {
        require(!isOwner(newOwner), "ALREADY_OWNER");
        ownerCandidate = newOwner;
    }

    function acceptOwnership() external {
        // Previous owner is still an admin.
        require(msg.sender == ownerCandidate, "NOT_A_CANDIDATE");
        owner = ownerCandidate;
        admins[ownerCandidate] = true;
        ownerCandidate = address(0x0);
    }
}