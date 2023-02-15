// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { LibACL } from "src/diamonds/nayms/libs/LibACL.sol";
import { LibHelpers } from "src/diamonds/nayms/libs/LibHelpers.sol";
import { LibConstants } from "src/diamonds/nayms/libs/LibConstants.sol";
import { LibDiamond } from "src/diamonds/shared/libs/LibDiamond.sol";
import { OwnershipFacet } from "src/diamonds/shared/facets/OwnershipFacet.sol";
import { Modifiers } from "src/diamonds/nayms/Modifiers.sol";

contract NaymsOwnershipFacet is OwnershipFacet, Modifiers {
    function transferOwnership(address _newOwner) public override assertSysAdmin {
        bytes32 systemID = LibHelpers._stringToBytes32(LibConstants.SYSTEM_IDENTIFIER);
        bytes32 newAcc1Id = LibHelpers._getIdForAddress(_newOwner);

        require(!LibACL._isInGroup(newAcc1Id, systemID, LibHelpers._stringToBytes32(LibConstants.GROUP_SYSTEM_ADMINS)), "NEW owner MUST NOT be sys admin");
        require(!LibACL._isInGroup(newAcc1Id, systemID, LibHelpers._stringToBytes32(LibConstants.GROUP_SYSTEM_MANAGERS)), "NEW owner MUST NOT be sys manager");

        super.transferOwnership(_newOwner);
    }
}