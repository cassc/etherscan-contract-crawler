// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract AltariusMinterStorage is AccessControl {
    struct PackMetadata {
        uint256 price;
        uint104 freePacksAvailable;
        uint104 payablePacksAvailable;
        uint24 maxFreePacksPerAddress;
        bool freePacksEnabled;
        bool onlyWhitelisted;
        bool paused;
        bytes32 merkleRoot;
        bytes32 merkleTreeCid1;
        bytes32 merkleTreeCid2;
    }

    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");

    mapping(uint256 => PackMetadata) public packsMetadata; // edition => PackMetadata

    mapping(uint256 => mapping(address => uint256))
        public freePacksClaimedPerEdition; // edition => claimer => amount

    mapping(uint256 => mapping(uint256 => mapping(uint256 => mapping(uint256 => mapping(bool => uint256[])))))
        public cardIds; // edition => type => level => rarity => holographic => cardIds

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setPackPrice(
        uint256 edition,
        uint256 price
    ) external onlyRole(CONFIGURATOR_ROLE) {
        packsMetadata[edition].price = price;
    }

    function setFreePacksAvailable(
        uint256 edition,
        uint104 freePacksAvailable
    ) external onlyRole(CONFIGURATOR_ROLE) {
        packsMetadata[edition].freePacksAvailable = freePacksAvailable;
    }

    function setPayablePacksAvailable(
        uint256 edition,
        uint104 payablePacksAvailable
    ) external onlyRole(CONFIGURATOR_ROLE) {
        packsMetadata[edition].payablePacksAvailable = payablePacksAvailable;
    }

    function setMaxFreePacksPerAddress(
        uint256 edition,
        uint24 maxFreePacksPerAddress
    ) external onlyRole(CONFIGURATOR_ROLE) {
        packsMetadata[edition].maxFreePacksPerAddress = maxFreePacksPerAddress;
    }

    function setFreePacksEnabled(
        uint256 edition,
        bool freePacksEnabled
    ) external onlyRole(CONFIGURATOR_ROLE) {
        packsMetadata[edition].freePacksEnabled = freePacksEnabled;
    }

    function setPackOnlyWhitelisted(
        uint256 edition,
        bool onlyWhitelisted
    ) external onlyRole(CONFIGURATOR_ROLE) {
        packsMetadata[edition].onlyWhitelisted = onlyWhitelisted;
    }

    function setPackPaused(
        uint256 edition,
        bool paused
    ) external onlyRole(CONFIGURATOR_ROLE) {
        packsMetadata[edition].paused = paused;
    }

    function setFreePacksClaimed(
        uint256 edition,
        address claimer,
        uint256 amount
    ) external onlyRole(CONFIGURATOR_ROLE) {
        freePacksClaimedPerEdition[edition][claimer] = amount;
    }

    function setCardIds(
        uint256 edition,
        uint256 cardType,
        uint256 level,
        uint256 rarity,
        bool holographic,
        uint256[] memory _cardIds
    ) external onlyRole(CONFIGURATOR_ROLE) {
        cardIds[edition][cardType][level][rarity][holographic] = _cardIds;
    }

    function setPackMerkle(
        uint256 edition,
        bytes32 root,
        bytes32 treeCid1,
        bytes32 treeCid2
    ) external onlyRole(CONFIGURATOR_ROLE) {
        packsMetadata[edition].merkleRoot = root;
        packsMetadata[edition].merkleTreeCid1 = treeCid1;
        packsMetadata[edition].merkleTreeCid2 = treeCid2;
    }

    function getPackMetadata(
        uint256 edition
    ) external view returns (PackMetadata memory) {
        return packsMetadata[edition];
    }

    function getFreePacksClaimed(
        uint256 edition,
        address claimer
    ) external view returns (uint256) {
        return freePacksClaimedPerEdition[edition][claimer];
    }

    function getCardIds(
        uint256 edition,
        uint256 cardType,
        uint256 level,
        uint256 rarity,
        bool holographic
    ) external view returns (uint256[] memory) {
        return cardIds[edition][cardType][level][rarity][holographic];
    }

    function getPackMerkleTreeCid(
        uint256 edition
    ) external view returns (string memory) {
        return
            string.concat(
                _bytes32ToString(packsMetadata[edition].merkleTreeCid1),
                _bytes32ToString(packsMetadata[edition].merkleTreeCid2)
            );
    }

    function _bytes32ToString(
        bytes32 data
    ) private pure returns (string memory) {
        uint i = 0;
        while (i < 32 && uint8(data[i]) != 0) {
            ++i;
        }
        bytes memory result = new bytes(i);
        i = 0;
        while (i < 32 && data[i] != 0) {
            result[i] = data[i];
            ++i;
        }
        return string(result);
    }
}