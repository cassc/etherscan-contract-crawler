// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract MetarunCollection is ERC1155Upgradeable, AccessControlUpgradeable, ERC1155BurnableUpgradeable, ERC1155SupplyUpgradeable {
    uint256 internal constant KIND_MASK = 0xffffffff0000;

    uint256 public constant BRONZE_TICKET_KIND = 0x00000400;
    uint256 public constant SILVER_TICKET_KIND = 0x00000401;
    uint256 public constant GOLD_TICKET_KIND = 0x00000402;
    uint256 public constant BRONZE_GIVEAWAY_KIND = 0x00000403;
    uint256 public constant SILVER_GIVEAWAY_KIND = 0x00000404;
    uint256 public constant GOLD_GIVEAWAY_KIND = 0x00000405;

    uint256 public constant MYSTERY_BOX_KIND = 0x00000406;

    uint256 public constant ARTIFACT_TOKEN_KIND = 0x00000100;
    uint256 public constant PET_TOKEN_KIND = 0x00000200;

    uint256 public constant IGNIS_CLASSIC_COMMON = 0x00010600;
    uint256 public constant IGNIS_CLASSIC_RARE = 0x000010601;
    uint256 public constant IGNIS_CLASSIC_MYTHICAL = 0x00010602;
    uint256 public constant IGNIS_EPIC_COMMON = 0x00010700;
    uint256 public constant IGNIS_EPIC_RARE = 0x00010701;
    uint256 public constant IGNIS_EPIC_MYTHICAL = 0x00010702;
    uint256 public constant IGNIS_LEGENDARY_COMMON = 0x00010800;
    uint256 public constant IGNIS_LEGENDARY_RARE = 0x00010801;
    uint256 public constant IGNIS_LEGENDARY_MYTHICAL = 0x00010802;

    uint256 public constant PENNA_CLASSIC_COMMON = 0x00020600;
    uint256 public constant PENNA_CLASSIC_RARE = 0x00020601;
    uint256 public constant PENNA_CLASSIC_MYTHICAL = 0x00020602;
    uint256 public constant PENNA_EPIC_COMMON = 0x00020700;
    uint256 public constant PENNA_EPIC_RARE = 0x00020701;
    uint256 public constant PENNA_EPIC_MYTHICAL = 0x00020702;
    uint256 public constant PENNA_LEGENDARY_COMMON = 0x00020800;
    uint256 public constant PENNA_LEGENDARY_RARE = 0x00020801;
    uint256 public constant PENNA_LEGENDARY_MYTHICAL = 0x00020802;

    uint256 public constant ORO_CLASSIC_COMMON = 0x00030600;
    uint256 public constant ORO_CLASSIC_RARE = 0x00030601;
    uint256 public constant ORO_CLASSIC_MYTHICAL = 0x00030602;
    uint256 public constant ORO_EPIC_COMMON = 0x00030700;
    uint256 public constant ORO_EPIC_RARE = 0x00030701;
    uint256 public constant ORO_EPIC_MYTHICAL = 0x00030702;
    uint256 public constant ORO_LEGENDARY_COMMON = 0x00030800;
    uint256 public constant ORO_LEGENDARY_RARE = 0x00030801;
    uint256 public constant ORO_LEGENDARY_MYTHICAL = 0x00030802;

    uint256 public constant FUNGIBLE_TOKEN_KIND = 0x00000500;
    uint256 public constant HEALTH_TOKEN_ID = (FUNGIBLE_TOKEN_KIND << 16) + 0x00000000;
    uint256 public constant MANA_TOKEN_ID = (FUNGIBLE_TOKEN_KIND << 16) + 0x00000001;
    uint256 public constant SPEED_TOKEN_ID = (FUNGIBLE_TOKEN_KIND << 16) + 0x00000002;
    uint256 public constant COLLISION_DAMAGE_TOKEN_ID = (FUNGIBLE_TOKEN_KIND << 16) + 0x00000003;
    uint256 public constant OPAL_TOKEN_ID = (FUNGIBLE_TOKEN_KIND << 16) + 0x00000004;

    mapping(uint256 => uint256) nftKindSupply;
    struct Perks {
        uint256 level;
        uint256 runs;
        uint256 wins;
        uint256 ability;
        uint256 health;
        uint256 mana;
        uint256 speed;
        uint256 collisionDamage;
        uint256 runsPerDayLimit;
        uint256 runsTotalLimit;
    }

    mapping(uint256 => Perks) tokenPerks;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");

    function initialize(string memory uri) public initializer {
        __ERC1155_init(uri);
        __AccessControl_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(SETTER_ROLE, _msgSender());
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function getNFTKindSupply(uint256 kind) public view returns (uint256) {
        return nftKindSupply[kind];
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "METARUNCOLLECTION: need MINTER_ROLE");
        if (!isKind(id, FUNGIBLE_TOKEN_KIND)) {
            require(amount == 1, "Cannot mint more than one item");
            require(!exists(id), "Cannot mint more than one item");
            nftKindSupply[getKind(id)]++;
        }

        _mint(to, id, amount, "");
    }

    function mintBatch(
        address to,
        uint256 kind,
        uint256 count
    ) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "NEED_MINTER_ROLE");
        require(kind != FUNGIBLE_TOKEN_KIND, "UNSUITABLE_KIND");
        require(count > 0, "COUNT_UNDERFLOW");
        uint256[] memory tokenIds = new uint256[](count);
        uint256 countOfReadyToMintIds = 0;
        uint256 currentTokenId = kind << 16;
        while (countOfReadyToMintIds < count) {
            require(isKind(currentTokenId, kind), "KIND_OVERFLOW");
            if (!exists(currentTokenId)) {
                tokenIds[countOfReadyToMintIds] = currentTokenId;
                countOfReadyToMintIds++;
            }
            currentTokenId++;
        }
        uint256[] memory amounts = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            amounts[i] = 1;
        }

        nftKindSupply[kind] += count;
        _mintBatch(to, tokenIds, amounts, "");
    }

    function isGameToken(uint256 id) public pure returns (bool) {
        return
            getType(id) == IGNIS_CLASSIC_COMMON >> 16 ||
            getType(id) == PENNA_CLASSIC_COMMON >> 16 ||
            getType(id) == ORO_CLASSIC_COMMON >> 16 ||
            isKind(id, BRONZE_TICKET_KIND) ||
            isKind(id, SILVER_TICKET_KIND) ||
            isKind(id, GOLD_TICKET_KIND) ||
            isKind(id, BRONZE_GIVEAWAY_KIND) ||
            isKind(id, SILVER_GIVEAWAY_KIND) ||
            isKind(id, GOLD_GIVEAWAY_KIND);
    }

    function getKind(uint256 id) public pure returns (uint256) {
        return (KIND_MASK & id) >> 16;
    }

    function getType(uint256 id) public pure returns (uint256) {
        return (id >> 16) >> 16;
    }

    function isKind(uint256 id, uint256 kind) public pure returns (bool) {
        return getKind(id) == kind;
    }

    function setURI(string memory newUri) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "need DEFAULT_ADMIN_ROLE");
        _setURI(newUri);
    }

    function getPerks(uint256 id) external view returns (Perks memory) {
        require(isGameToken(id) || isKind(id, PET_TOKEN_KIND), "Perks are available only for characters, pets and tickets");
        return tokenPerks[id];
    }

    function setPerks(uint256 id, Perks memory perks) external {
        require(isGameToken(id) || isKind(id, PET_TOKEN_KIND), "Perks are available only for characters, pets and tickets");
        require(hasRole(SETTER_ROLE, _msgSender()), "need SETTER_ROLE");
        tokenPerks[id] = perks;
    }
}