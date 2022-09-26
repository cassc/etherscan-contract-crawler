// contracts/CreaturaeArmy.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "solmate/src/tokens/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./external/IPFS.sol";

contract CreaturaeArmy is ERC721 {
    // Army's General
    address payable public general;

    // General location
    string generalLocation;
    
    // The great signature of the spell book
    bytes32 public immutable spellBookSignature;

    // A spell to set location in stone
    event PermanentURI(string _value, uint256 indexed _id);

    // Fees to summon
    uint256[2] summonFees = [
        0 ether, // Conscript
        0.25 ether  // Mercenary
    ];

    // The Creator blessed the Creatures from the underworuld and assigned a
    // fearless General to lead the great war.
    constructor(bytes32 _signature, address _general, string memory _generalLocation) ERC721("CreaturaeArmy", "ARMY") {
        // The Creator added signature to the Book of Spells.
        spellBookSignature = _signature;

        // General of the Army has been summoned by the Creator.
        general = payable(msg.sender);
        generalLocation = _generalLocation;
        _mint(_general, 0);

        // General is the only one and cannot be changed.
        emit PermanentURI(generalLocation, 0);
    }

    // Raise my child from the ashes
    function summon(
        uint256 tokenId,
        uint8 rankIndex,
        address to,
        bytes32[] calldata spell
    ) external payable {
        require(rankIndex == 0 || rankIndex == 1, "CreaturaeArmy#summon: Unknown recruit");
        require(msg.value >= summonFees[rankIndex], "CreaturaeArmy#summon: Pay More");
        require(
            MerkleProof.verify(
                spell,
                spellBookSignature,
                keccak256(abi.encodePacked(tokenId, rankIndex))
            )
        , "CreaturaeArmy#summon: Invalid spell");

        // it is happening, behold the new Soldier of the realm
        // infinitely summoned to the world of people
        _mint(to, tokenId);
        emit PermanentURI(string(abi.encodePacked("ipfs://", IPFS.encode(tokenId))), tokenId);
    }
    
    // Ah the location of our Soldiers is permanent and well known
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        // Only General has a unique location.
        if(tokenId == 0) {
            return generalLocation;
        }

        // The entire army resides on the battlefield.
        return string(abi.encodePacked("ipfs://", IPFS.encode(tokenId)));
    }

    function reap(address payable to) external {
        require(msg.sender == general);

        uint amount = address(this).balance;
        require(amount > 0);

        (bool success, ) = to.call{value: amount}("");
        require(success);
    }
}