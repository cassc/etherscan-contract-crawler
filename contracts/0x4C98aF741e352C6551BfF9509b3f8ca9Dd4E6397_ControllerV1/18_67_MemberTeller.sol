pragma solidity ^0.8.7;
import "./interfaces/IMemberToken.sol";

contract MemberTeller {
    IMemberToken public immutable memberToken;

    bytes4 public constant ENCODED_SIG_ADD_OWNER =
        bytes4(keccak256("addOwnerWithThreshold(address,uint256)"));
    bytes4 public constant ENCODED_SIG_REMOVE_OWNER =
        bytes4(keccak256("removeOwner(address,address,uint256)"));
    bytes4 public constant ENCODED_SIG_SWAP_OWNER =
        bytes4(keccak256("swapOwner(address,address,address)"));

    uint8 internal constant SYNC_EVENT = 0x02;

    constructor(address _memberToken) {
        memberToken = IMemberToken(_memberToken);
    }

    function getSyncData() internal pure returns (bytes memory) {
        bytes memory data = new bytes(1);
        data[0] = bytes1(uint8(SYNC_EVENT));
        return data;
    }

    // we use burn sync flag to let the controller know to skip side effects
    // controller will reset flag in beforeTokenTransfer
    bool internal BURN_SYNC_FLAG = false;

    function setBurnSyncFlag(bool flag) internal {
        BURN_SYNC_FLAG = flag;
    }

    function memberTellerCheck(uint256 podId, bytes memory data) internal {
        if (bytes4(data) == ENCODED_SIG_ADD_OWNER) {
            address mintMember;
            assembly {
                // shift 0x4 for the sig + 0x20 padding
                mintMember := mload(add(data, 0x24))
            }
            memberToken.mint(mintMember, podId, getSyncData());
        }
        if (bytes4(data) == ENCODED_SIG_REMOVE_OWNER) {
            address burnMember;
            assembly {
                // note: consecutive addresses are packed into a single memory slot
                // shift 0x4 for the sig, 0x40 for prev address and padding
                burnMember := mload(add(data, 0x44))
            }
            setBurnSyncFlag(true);
            memberToken.burn(burnMember, podId);
        }
        if (bytes4(data) == ENCODED_SIG_SWAP_OWNER) {
            address burnMember;
            address mintMember;
            assembly {
                // note: consecutive addresses are packed into a single memory slot
                // shift 0x4 for the sig + 0x40 for prev address and padding
                burnMember := mload(add(data, 0x44))
                // shift 0x4 for the sig + 0x40 for prev address and padding + 0x20 for the new address
                mintMember := mload(add(data, 0x64))
            }
            memberToken.mint(mintMember, podId, getSyncData());
            setBurnSyncFlag(true);
            memberToken.burn(burnMember, podId);
        }
    }
}