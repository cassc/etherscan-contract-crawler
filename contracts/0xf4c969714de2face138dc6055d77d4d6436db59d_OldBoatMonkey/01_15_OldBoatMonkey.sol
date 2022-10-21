/// SPDX-License-Identifier: MIT

pragma solidity >=0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@relicprotocol/contracts/lib/Facts.sol";
import "@relicprotocol/contracts/lib/FactSigs.sol";
import "@relicprotocol/contracts/lib/Storage.sol";
import "@relicprotocol/contracts/interfaces/IReliquary.sol";

interface IURI {
    function uri(uint origId, uint blockNum)
        external
        view
        returns (string memory);
}

struct OwnershipInfo {
    uint64 tokenId;
    uint64 blockNum;
}

contract OldBoatMonkey is ERC721, Ownable {
    bytes32 constant TOKEN_OWNERS_MAP_SLOT = bytes32(uint256(2));
    mapping(address => mapping(uint => uint)) public claimed;
    mapping(uint => OwnershipInfo) tokenIdMap;
    uint totalMinted;

    IReliquary immutable reliquary;
    IURI immutable urimaker;
    address immutable BAYC;

    constructor(
        address _reliquary,
        address _urimaker,
        address _BAYC
    ) ERC721("Old Boat Monkey", "OBM") Ownable() {
        reliquary = IReliquary(_reliquary);
        urimaker = IURI(_urimaker);
        BAYC = _BAYC;
    }

    function slotForToken(uint tokenId) public pure returns (bytes32) {
        return
            Storage.structFieldSlot(
                Storage.dynamicArrayElemSlot(
                    Storage.structFieldSlot(TOKEN_OWNERS_MAP_SLOT, 0),
                    tokenId,
                    2
                ),
                1
            );
    }

    function mint(
        address who,
        uint blockNum,
        uint tokenId
    ) public {
        require(claimed[who][tokenId] == 0, "already claimed");
        (bool exists, , bytes memory data) = reliquary.verifyFactNoFee(
            BAYC,
            FactSigs.storageSlotFactSig(slotForToken(tokenId), blockNum)
        );
        require(exists, "storage proof missing");

        require(who == Storage.parseAddress(data), "wrong owner");

        totalMinted++;
        // keep track of this token's information
        tokenIdMap[totalMinted] = OwnershipInfo(
            uint64(tokenId),
            uint64(blockNum)
        );
        claimed[who][tokenId] = totalMinted;
        _safeMint(who, totalMinted);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        return
            urimaker.uri(
                tokenIdMap[tokenId].tokenId,
                tokenIdMap[tokenId].blockNum
            );
    }
}