// SPDX-License-Identifier: MIT

/// @title A library to hold our Queen's Royal Knowledge

pragma solidity 0.8.9;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library RoyalLibrary {
    struct sTRAIT {
        uint256 id;
        string traitName;
        uint8 enabled; //0 - disabled; 1 - enabled;
    }

    struct sRARITY {
        uint256 id;
        string rarityName;
        uint256 percentage; //1 ~ 100
    }

    struct sART {
        uint256 traitId;
        uint256 rarityId;
        bytes artName;
        bytes uri;
    }

    struct sDNA {
        uint256 traitId;
        uint256 rarityId;
        uint256 trace;
    }

    struct sBLOOD {
        uint256 traitId;
        uint256 rarityId;
        string artName;
        string artUri;
    }

    struct sQUEEN {
        uint256 queeneId;
        uint256 description; //index of the description
        string finalArt;
        sDNA[] dna;
        uint8 queenesGallery;
        uint8 sirAward;
    }

    struct sSIR {
        address sirAddress;
        uint256 queene;
    }

    struct sAUCTION {
        uint256 queeneId;
        uint256 lastBidAmount;
        uint256 auctionStartTime;
        uint256 auctionEndTime;
        uint256 initialBidPrice;
        address payable bidder;
        bool ended;
    }

    enum queeneRarity {
        COMMON,
        RARE,
        SUPER_RARE,
        LEGENDARY
    }

    address constant burnAddress = 0x0000000000000000000000000000000000000000;
    uint8 constant houseOfLords = 1;
    uint8 constant houseOfCommons = 2;
    uint8 constant houseOfBanned = 3;

    error InvalidAddressError(string _caller, string _msg, address _address);
    error AuthorizationError(string _caller, string _msg, address _address);
    error MinterLockedError(
        string _caller,
        string _msg,
        address _minterAddress
    );
    error StorageLockedError(
        string _caller,
        string _msg,
        address _storageAddress
    );
    error LabLockedError(string _caller, string _msg, address _labAddress);
    error InvalidParametersError(
        string _caller,
        string _msg,
        string _arg1,
        string _arg2,
        string _arg3
    );

    function concat(string memory self, string memory part2)
        public
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(self, part2));
    }

    function stringEquals(string storage self, string memory b)
        public
        view
        returns (bool)
    {
        if (bytes(self).length != bytes(b).length) {
            return false;
        } else {
            return
                keccak256(abi.encodePacked(self)) ==
                keccak256(abi.encodePacked(b));
        }
    }

    function extractRevertReason(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}