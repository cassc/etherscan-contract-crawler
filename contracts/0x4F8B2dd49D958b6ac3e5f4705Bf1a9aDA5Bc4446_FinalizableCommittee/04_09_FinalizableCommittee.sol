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

import "Finalizable.sol";
import "Committee.sol";

/**
  A finalizable version of Committee.
  Until finalized, it allows adding new members and incrementing the number of required signers.
*/
contract FinalizableCommittee is Finalizable, Committee {
    event RequiredSignersIncrement(uint256 newRequiredSigners);
    event NewMemberAdded(address newMember);

    uint256 private _memberCount;

    constructor(address[] memory committeeMembers, uint256 numSignaturesRequired)
        public
        Committee(committeeMembers, numSignaturesRequired)
    {
        _memberCount = committeeMembers.length;
    }

    function incrementRequiredSigners() external notFinalized onlyAdmin {
        require(signaturesRequired < _memberCount, "TOO_MANY_REQUIRED_SIGNATURES");
        signaturesRequired += 1;
        emit RequiredSignersIncrement(signaturesRequired);
    }

    function addCommitteeMemeber(address newMember) external notFinalized onlyAdmin {
        require(newMember != address(0x0), "INVALID_MEMBER");
        require(!isMember[newMember], "ALREADY_MEMBER");
        isMember[newMember] = true;
        _memberCount += 1;
        emit NewMemberAdded(newMember);
    }

    function identify() external pure override returns (string memory) {
        return "StarkWare_FinalizableCommittee_2022_1";
    }
}
