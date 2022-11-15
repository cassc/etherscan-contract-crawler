// SPDX-License-Identifier: MIT
// Creator: twitter.com/0xNox_ETH

//               .;::::::::::::::::::::::::::::::;.
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;
//               ;KNNNWMMWMMMMMMWWNNNNNNNNNWMMMMMN:
//                .',oXMMMMMMMNk:''''''''';OMMMMMN:
//                 ,xNMMMMMMNk;            l00000k,
//               .lNMMMMMMNk;               .....
//                'dXMMWNO;                .......
//                  'd0k;.                .dXXXXX0;
//               .,;;:lc;;;;;;;;;;;;;;;;;;c0MMMMMN:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWX:
//               .,;,;;;;;;;;;;;;;;;;;;;;;;;,;;,;,.
//               'dkxkkxxkkkkkkkkkkkkkkkkkkxxxkxkd'
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               'xkkkOOkkkkkkkkkkkkkkkkkkkkkkkkkx'
//                          .,,,,,,,,,,,,,,,,,,,,,.
//                        .lKNWWWWWWWWWWWWWWWWWWWX;
//                      .lKWMMMMMMMMMMMMMMMMMMMMMX;
//                    .lKWMMMMMMMMMMMMMMMMMMMMMMMN:
//                  .lKWMMMMMWKo:::::::::::::::::;.
//                .lKWMMMMMWKl.
//               .lNMMMMMWKl.
//                 ;kNMWKl.
//                   ;dl.
//
//               We vow to Protect
//               Against the powers of Darkness
//               To rain down Justice
//               Against all who seek to cause Harm
//               To heed the call of those in Need
//               To offer up our Arms
//               In body and name we give our Code
//
//               FOR THE BLOCKCHAIN ⚔️

pragma solidity ^0.8.17;

import "./extensions/IERC721ABurnable.sol";
import "./extensions/ERC721AQueryable.sol";
import "./ICloneforceAirdropManager.sol";
import "./DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Guardian is
    Ownable,
    ReentrancyGuard,
    ERC721AQueryable,
    IERC721ABurnable,
    DefaultOperatorFilterer
{
    event PermanentURI(string _value, uint256 indexed _id);

    bool public relicMigrationPaused;
    bool public contractPaused;

    string private _baseTokenURI;
    bool public baseURILocked;

    address private _nexusContract;
    address private _burnAuthorizedContract;
    address private _admin;

    // Shard related storage

    address private _shardContract;

    // 0: None (No DNA), 1: Human, 2: Robot
    // 3: Demon, 4: Angel, 5: Reptile
    // 6: Undead, 7: Alien, 8: Kami, ...
    mapping(uint256 => uint256) public tokenIdToDna;

    struct EquippedBoundlessShard {
        uint256 tokenId;
        uint256 count;
    }
    mapping(uint256 => EquippedBoundlessShard[]) public equippedBoundlessShardsMap;
    mapping(uint256 => uint256[]) public lastBoundlessShardAddTimes;
    uint256 public maxBoundlessShardEquipPerPeriod = 3;
    uint256 public boundlessShardEquipLimitPeriodDays = 7;

    // Armor piece related storage

    struct EquippedArmorPiece {
        address tokenAddress;
        uint256 tokenId;
        uint256 bodyPart;
    }
    mapping(address => bool) public armorPieceContracts;
    mapping(uint256 => EquippedArmorPiece[]) public equippedArmorPiecesMap;

    mapping(uint256 => bool) public isUnequippableBodyPartMap;
    mapping(uint256 => uint256) public lastArmorPieceUnequipTimeMap;

    constructor(
        string memory baseTokenURI,
        address admin,
        address nexusContract
    ) ERC721A("CF Guardian", "GUARDIAN") {
        _baseTokenURI = baseTokenURI;
        _admin = admin;
        _nexusContract = nexusContract;

        relicMigrationPaused = true;

        _safeMint(msg.sender, 1);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller is another contract");
        _;
    }

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner() || msg.sender == _admin, "Not owner or admin");
        _;
    }

    // Burns `count` number of Relics and mints new Guardians
    function migrateRelic(uint256 count) external nonReentrant callerIsUser {
        require(!relicMigrationPaused && !contractPaused, "Migration is paused");
        require(count > 0, "Count must be greater than 0");

        INexusContract nexus = INexusContract(_nexusContract);
        uint256 relicBalance = nexus.balanceOf(msg.sender, 0);
        require(relicBalance >= count, "You don't have enough Relics");

        // burn Relics
        nexus.burn(msg.sender, 0, count);

        // mint Guardians
        _safeMint(msg.sender, count);
    }

    // Only the owner of the token and its approved operators, and the authorized contract
    // can call this function.
    function burn(uint256 tokenId) public virtual override {
        // Avoid unnecessary approvals for the authorized contract
        bool approvalCheck = msg.sender != _burnAuthorizedContract;
        _burn(tokenId, approvalCheck);
    }

    function pauseRelicMigration(bool paused) external onlyOwnerOrAdmin {
        relicMigrationPaused = paused;
    }

    function pauseContract(bool paused) external onlyOwnerOrAdmin {
        contractPaused = paused;
    }

    function equipDnaShard(uint256 tokenId, uint256 shardId) external nonReentrant callerIsUser {
        require(msg.sender == ownerOf(tokenId), "Only owner can equip");
        require(tokenIdToDna[tokenId] == 0, "Token already has a DNA");

        ICloneforceShard shard = ICloneforceShard(_shardContract);
        require(shard.balanceOf(msg.sender, shardId) > 0, "Not enough shards");

        // it must be a DNA shard
        require(shard.getShardType(shardId) == 0, "Not a DNA shard");

        uint256 dnaType = shard.getDnaType(shardId);

        // burn the shard
        shard.burn(msg.sender, shardId, 1);

        // equip the shard
        tokenIdToDna[tokenId] = dnaType;
    }

    function equipBoundlessShard(
        uint256 tokenId,
        uint256 shardId,
        uint256 count
    ) external nonReentrant callerIsUser {
        require(msg.sender == ownerOf(tokenId), "Only owner can equip");
        require(count > 0 && count <= maxBoundlessShardEquipPerPeriod, "Invalid equip count");

        ICloneforceShard shard = ICloneforceShard(_shardContract);
        require(shard.balanceOf(msg.sender, shardId) >= count, "Not enough shards");

        // it must be a Boundless shard
        require(shard.getShardType(shardId) == 1, "Not a Boundless shard");

        unchecked {
            // can only equip a specific number of shards in a while
            uint maxPossibleEquipCount = maxBoundlessShardEquipPerPeriod;
            uint periodDays = boundlessShardEquipLimitPeriodDays * 1 days;
            uint256[] storage lastAddTimes = lastBoundlessShardAddTimes[tokenId];
            for (uint i = 0; i < lastAddTimes.length; i++) {
                if (block.timestamp - lastAddTimes[i] < periodDays) {
                    maxPossibleEquipCount--;
                }
            }

            if (maxPossibleEquipCount < 1) {
                revert("Can't equip more shards in this period");
            }

            if (maxPossibleEquipCount < count) {
                count = maxPossibleEquipCount;
            }

            // burn the shard(s)
            shard.burn(msg.sender, shardId, count);

            // if shard is already equipped, add to count
            EquippedBoundlessShard[] storage equippedShards = equippedBoundlessShardsMap[tokenId];
            bool found = false;
            for (uint256 i = 0; i < equippedShards.length; i++) {
                if (equippedShards[i].tokenId == shardId) {
                    equippedShards[i].count += count;
                    found = true;
                    break;
                }
            }

            // not equipped, add to array
            if (!found) {
                equippedShards.push(EquippedBoundlessShard(shardId, count));
            }

            // log the add times
            for (uint iter = 0; iter < count; iter++) {
                if (lastAddTimes.length < maxBoundlessShardEquipPerPeriod) {
                    lastAddTimes.push(block.timestamp);
                } else {
                    uint256 minTimeIdx = 0;
                    for (uint256 i = 1; i < maxBoundlessShardEquipPerPeriod; i++) {
                        if (lastAddTimes[i] < lastAddTimes[minTimeIdx]) {
                            minTimeIdx = i;
                        }
                    }
                    lastAddTimes[minTimeIdx] = block.timestamp;
                }
            }
        }
    }

    function equipArmorPiece(
        uint256 tokenId,
        address armorPieceContract,
        uint256 armorPieceId
    ) external nonReentrant callerIsUser {
        bool isOwnerOrAdmin = msg.sender == owner() || msg.sender == _admin;
        address tokenOwner = ownerOf(tokenId);
        require(msg.sender == tokenOwner || isOwnerOrAdmin, "Only owner can equip");
        require(armorPieceContracts[armorPieceContract], "Not an armor piece contract");

        ICloneforceArmorPiece armorPiece = ICloneforceArmorPiece(armorPieceContract);
        require(
            armorPiece.ownerOf(armorPieceId) == msg.sender || isOwnerOrAdmin,
            "You don't own the armor piece"
        );

        uint256 bodyPart = armorPiece.getBodyPart(armorPieceId);

        // burn the armor piece
        armorPiece.burn(armorPieceId);

        // check if there's an existing armor piece of the same body part
        EquippedArmorPiece[] storage equippedArmorPieces = equippedArmorPiecesMap[tokenId];
        for (uint256 i = 0; i < equippedArmorPieces.length; i++) {
            if (equippedArmorPieces[i].bodyPart == bodyPart) {
                // if it's an unequippable armor piece, un-equip it
                if (isUnequippableBodyPartMap[bodyPart]) {
                    // re-mint the armor piece
                    ICloneforceArmorPiece remintedArmorPiece = ICloneforceArmorPiece(
                        equippedArmorPieces[i].tokenAddress
                    );
                    remintedArmorPiece.mint(tokenOwner, equippedArmorPieces[i].tokenId);

                    // set the unequip time
                    lastArmorPieceUnequipTimeMap[tokenId] = block.timestamp;
                }
                // replace the existing armor piece
                equippedArmorPieces[i].tokenAddress = armorPieceContract;
                equippedArmorPieces[i].tokenId = armorPieceId;
                return;
            }
        }

        // there's no armor piece on this body part, equip it
        equippedArmorPieces.push(
            EquippedArmorPiece({
                tokenAddress: armorPieceContract,
                tokenId: armorPieceId,
                bodyPart: bodyPart
            })
        );
    }

    function unequipArmorPiece(uint256 tokenId, uint256 bodyPart)
        external
        nonReentrant
        callerIsUser
    {
        bool isOwnerOrAdmin = msg.sender == owner() || msg.sender == _admin;
        address tokenOwner = ownerOf(tokenId);
        require(msg.sender == tokenOwner || isOwnerOrAdmin, "Only owner can unequip");
        // check if unequipping is allowed for the body part
        require(isUnequippableBodyPartMap[bodyPart], "Unequipping not allowed for this body part");

        unchecked {
            EquippedArmorPiece[] storage equippedArmorPieces = equippedArmorPiecesMap[tokenId];
            for (uint256 i = 0; i < equippedArmorPieces.length; i++) {
                if (equippedArmorPieces[i].bodyPart == bodyPart) {
                    // re-mint the armor piece
                    ICloneforceArmorPiece armorPiece = ICloneforceArmorPiece(
                        equippedArmorPieces[i].tokenAddress
                    );
                    armorPiece.mint(tokenOwner, equippedArmorPieces[i].tokenId);

                    // remove the armor piece
                    equippedArmorPieces[i] = equippedArmorPieces[equippedArmorPieces.length - 1];
                    equippedArmorPieces.pop();

                    // set the unequip time
                    lastArmorPieceUnequipTimeMap[tokenId] = block.timestamp;
                    return;
                }
            }
        }
    }

    // Returns the DNA type of the Guardian.
    function getDna(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return tokenIdToDna[tokenId];
    }

    // Returns the equipped boundless shards of the Guardian.
    function getEquippedBoundlessShards(uint256 tokenId)
        external
        view
        returns (uint256[] memory equippedTokenIds, uint256[] memory equippedCounts)
    {
        require(_exists(tokenId), "Token does not exist");
        EquippedBoundlessShard[] memory equippedShards = equippedBoundlessShardsMap[tokenId];
        uint256[] memory tokenIds = new uint256[](equippedShards.length);
        uint256[] memory counts = new uint256[](equippedShards.length);
        for (uint256 i = 0; i < equippedShards.length; i++) {
            tokenIds[i] = equippedShards[i].tokenId;
            counts[i] = equippedShards[i].count;
        }
        return (tokenIds, counts);
    }

    // Returns the equipped armor pieces of the Guardian.
    function getEquippedArmorPieces(uint256 tokenId)
        external
        view
        returns (
            address[] memory equippedTokenAddresses,
            uint256[] memory equippedTokenIds,
            uint256[] memory equippedBodyParts
        )
    {
        require(_exists(tokenId), "Token does not exist");
        EquippedArmorPiece[] memory equippedArmorPieces = equippedArmorPiecesMap[tokenId];
        address[] memory tokenAddresses = new address[](equippedArmorPieces.length);
        uint256[] memory tokenIds = new uint256[](equippedArmorPieces.length);
        uint256[] memory bodyParts = new uint256[](equippedArmorPieces.length);
        for (uint256 i = 0; i < equippedArmorPieces.length; i++) {
            tokenAddresses[i] = equippedArmorPieces[i].tokenAddress;
            tokenIds[i] = equippedArmorPieces[i].tokenId;
            bodyParts[i] = equippedArmorPieces[i].bodyPart;
        }
        return (tokenAddresses, tokenIds, bodyParts);
    }

    function _beforeTokenTransfers(
        address, /* from */
        address, /* to */
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        require(!contractPaused, "Contract is paused");
        // enumerate token ids `from` to `to` and check the last armor piece unequip time, it must be more than an hour
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = startTokenId + i;
            require(
                block.timestamp - lastArmorPieceUnequipTimeMap[tokenId] > 1 hours,
                "Can only transfer after 1h of unequipping armor piece"
            );
        }
    }

    // Locks base token URI forever and emits PermanentURI for marketplaces (e.g. OpenSea)
    function lockBaseURI() external onlyOwnerOrAdmin {
        baseURILocked = true;
        for (uint256 i = 0; i < _nextTokenId(); i++) {
            if (_exists(i)) {
                emit PermanentURI(tokenURI(i), i);
            }
        }
    }

    function ownerMint(address to, uint256 quantity) external onlyOwnerOrAdmin {
        _safeMint(to, quantity);
    }

    function setDna(uint256 tokenId, uint256 dnaType) external onlyOwnerOrAdmin {
        tokenIdToDna[tokenId] = dnaType;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwnerOrAdmin {
        require(!baseURILocked, "Base URI is locked");
        _baseTokenURI = newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function setAdmin(address admin) external onlyOwner {
        _admin = admin;
    }

    function setNexusContract(address addr) external onlyOwnerOrAdmin {
        _nexusContract = addr;
    }

    function setBurnAuthorizedContract(address addr) external onlyOwnerOrAdmin {
        _burnAuthorizedContract = addr;
    }

    function setShardContract(address addr) external onlyOwnerOrAdmin {
        _shardContract = addr;
    }

    function setArmorPieceContract(address addr, bool isEquippable) external onlyOwnerOrAdmin {
        armorPieceContracts[addr] = isEquippable;
    }

    function setBoundlessShardEquipLimit(uint256 count, uint256 periodDays)
        external
        onlyOwnerOrAdmin
    {
        maxBoundlessShardEquipPerPeriod = count;
        boundlessShardEquipLimitPeriodDays = periodDays;
    }

    function setUnequippableBodyPart(uint256 bodyPart, bool isUnequippable)
        external
        onlyOwnerOrAdmin
    {
        isUnequippableBodyPartMap[bodyPart] = isUnequippable;
    }

    // OpenSea metadata initialization
    function contractURI() public pure returns (string memory) {
        return "https://cloneforce.xyz/api/guardian/marketplace-metadata";
    }

    // OpenSea operator filtering
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function withdrawMoney(address to) external onlyOwnerOrAdmin {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}

interface ICloneforceShard {
    function getShardType(uint256 tokenId) external view returns (uint256); // 0 = dna shard, 1 = boundless shard

    function getDnaType(uint256 tokenId) external view returns (uint256); // returns 0 if not a dna shard, otherwise the DNA type

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external;

    function balanceOf(address account, uint256 id) external view returns (uint256);
}

interface ICloneforceArmorPiece {
    function getBodyPart(uint256 tokenId) external view returns (uint256);

    function burn(uint256 tokenId) external;

    function mint(address to, uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface INexusContract {
    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external;

    function balanceOf(address account, uint256 id) external view returns (uint256);
}