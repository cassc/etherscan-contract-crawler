// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./editions/IFurballEdition.sol";
import "./engines/ILootEngine.sol";
import "./engines/EngineA.sol";
import "./utils/FurLib.sol";
import "./utils/FurDefs.sol";
import "./utils/FurProxy.sol";
import "./utils/Moderated.sol";
import "./utils/Governance.sol";
import "./Fur.sol";
import "./Furgreement.sol";
// import "hardhat/console.sol";

/// @title Furballs
/// @author LFG Gaming LLC
/// @notice Mints Furballs on the Ethereum blockchain
/// @dev https://furballs.com/contract
contract Furballs is ERC721Enumerable, Moderated {
  Fur public fur;

  IFurballEdition[] public editions;

  ILootEngine public engine;

  Governance public governance;

  Furgreement public furgreement;

  // tokenId => furball data
  mapping(uint256 => FurLib.Furball) public furballs;

  // tokenId => all rewards assigned to that Furball
  mapping(uint256 => FurLib.Rewards) public collect;

  // The amount of time over which FUR/EXP is accrued (usually 3600=>1hour); used with test servers
  uint256 public intervalDuration;

  // When play/collect runs, returns rewards
  event Collection(uint256 tokenId, uint256 responseId);

  // Inventory change event
  event Inventory(uint256 tokenId, uint128 lootId, uint16 dropped);

  constructor(uint256 interval) ERC721("Furballs", "FBL") {
    intervalDuration = interval;
  }

  // -----------------------------------------------------------------------------------------------
  // Public transactions
  // -----------------------------------------------------------------------------------------------

  /// @notice Mints a new furball from the current edition (if there are any remaining)
  /// @dev Limits and fees are set by IFurballEdition
  function mint(address[] memory to, uint8 editionIndex, address actor) external {
    (address sender, uint8 permissions) = _approvedSender(actor);
    require(to.length == 1 || permissions >= FurLib.PERMISSION_MODERATOR, "MULT");

    for (uint8 i=0; i<to.length; i++) {
      fur.purchaseMint(sender, permissions, to[i], editions[editionIndex]);
      _spawn(to[i], editionIndex, 0);
    }
  }

  /// @notice Feeds the furball a snack
  /// @dev Delegates logic to fur
  function feed(FurLib.Feeding[] memory feedings, address actor) external {
    (address sender, uint8 permissions) = _approvedSender(actor);
    uint256 len = feedings.length;

    for (uint256 i=0; i<len; i++) {
      fur.purchaseSnack(sender, permissions, feedings[i].tokenId, feedings[i].snackId, feedings[i].count);
    }
  }

  /// @notice Begins exploration mode with the given furballs
  /// @dev Multiple furballs accepted at once to reduce gas fees
  /// @param tokenIds The furballs which should start exploring
  /// @param zone The explore zone (otherwize, zero for battle mode)
  function playMany(uint256[] memory tokenIds, uint32 zone, address actor) external {
    (address sender, uint8 permissions) = _approvedSender(actor);

    for (uint256 i=0; i<tokenIds.length; i++) {
      // Run reward collection
      _collect(tokenIds[i], sender, permissions);

      // Set new zone (if allowed; enterZone may throw)
      furballs[tokenIds[i]].zone = uint32(engine.enterZone(tokenIds[i], zone, tokenIds));
    }
  }

  /// @notice Re-dropping loot allows players to pay $FUR to re-roll an inventory slot
  /// @param tokenId The furball in question
  /// @param lootId The lootId in its inventory to re-roll
  function upgrade(
    uint256 tokenId, uint128 lootId, uint8 chances, address actor
  ) external {
    // Attempt upgrade (random chance).
    (address sender, uint8 permissions) = _approvedSender(actor);
    uint128 up = fur.purchaseUpgrade(_baseModifiers(tokenId), sender, permissions, tokenId, lootId, chances);
    if (up != 0) {
      _drop(tokenId, lootId, 1);
      _pickup(tokenId, up);
    }
  }

  /// @notice The LootEngine can directly send loot to a furball!
  /// @dev This allows for gameplay expansion, i.e., new game modes
  /// @param tokenId The furball to gain the loot
  /// @param lootId The loot ID being sent
  function pickup(uint256 tokenId, uint128 lootId) external gameAdmin {
    _pickup(tokenId, lootId);
  }

  /// @notice The LootEngine can cause a furball to drop loot!
  /// @dev This allows for gameplay expansion, i.e., new game modes
  /// @param tokenId The furball
  /// @param lootId The item to drop
  /// @param count the number of that item to drop
  function drop(uint256 tokenId, uint128 lootId, uint8 count) external gameAdmin {
    _drop(tokenId, lootId, count);
  }

  // -----------------------------------------------------------------------------------------------
  // Internal
  // -----------------------------------------------------------------------------------------------

  function _slotNum(uint256 tokenId, uint128 lootId) internal view returns(uint256) {
    for (uint8 i=0; i<furballs[tokenId].inventory.length; i++) {
      if (furballs[tokenId].inventory[i] / 256 == lootId) {
        return i + 1;
      }
    }
    return 0;
  }

  /// @notice Remove an inventory item from a furball
  function _drop(uint256 tokenId, uint128 lootId, uint8 count) internal {
    uint256 slot = _slotNum(tokenId, lootId);
    require(slot > 0 && slot <= uint32(furballs[tokenId].inventory.length), "SLOT");

    slot -= 1;
    uint8 stackSize = uint8(furballs[tokenId].inventory[slot] % 0x100);

    if (count == 0 || count >= stackSize) {
      // Drop entire stack
      uint16 len = uint16(furballs[tokenId].inventory.length);
      if (len > 1) {
        furballs[tokenId].inventory[slot] = furballs[tokenId].inventory[len - 1];
      }
      furballs[tokenId].inventory.pop();
      count = stackSize;
    } else {
      stackSize -= count;
      furballs[tokenId].inventory[slot] = uint256(lootId) * 0x100 + stackSize;
    }

    furballs[tokenId].weight -= count * engine.weightOf(lootId);
    emit Inventory(tokenId, lootId, count);
  }

  /// @notice Internal implementation of adding a single known loot item to a Furball
  function _pickup(uint256 tokenId, uint128 lootId) internal {
    require(lootId > 0, "LOOT");
    uint256 slotNum = _slotNum(tokenId, lootId);
    uint8 stackSize = 1;
    if (slotNum == 0) {
      furballs[tokenId].inventory.push(uint256(lootId) * 0x100 + stackSize);
    } else {
      stackSize += uint8(furballs[tokenId].inventory[slotNum - 1] % 0x100);
      require(stackSize < 0x100, "STACK");
      furballs[tokenId].inventory[slotNum - 1] = uint256(lootId) * 0x100 + stackSize;
    }

    furballs[tokenId].weight += engine.weightOf(lootId);
    emit Inventory(tokenId, lootId, 0);
  }

  /// @notice Calculates full reward modifier stack for a furball in a zone.
  function _rewardModifiers(
    FurLib.Furball memory fb, uint256 tokenId, address ownerContext, uint256 snackData
  ) internal view returns(FurLib.RewardModifiers memory reward) {
    uint16 energy = uint16(FurLib.extractBytes(snackData, FurLib.SNACK_BYTE_ENERGY, 2));
    uint16 happiness = uint16(FurLib.extractBytes(snackData, FurLib.SNACK_BYTE_HAPPINESS, 2));

    bool context = ownerContext != address(0);
    uint32 editionIndex = uint32(tokenId % 0x100);

    reward = FurLib.RewardModifiers(
      uint16(100 + fb.rarity),
      uint16(100 + fb.rarity - (editionIndex < 4 ? (editionIndex * 20) : 80)),
      uint16(100),
      happiness,
      energy,
      context ? fb.zone : 0
    );

    // Engine will consider inventory and team size in zone (17k)
    return engine.modifyReward(
      fb,
      editions[editionIndex].modifyReward(reward, tokenId),
      governance.getAccount(ownerContext),
      context
    );
  }

  /// @notice Common version of _rewardModifiers which excludes contextual data
  function _baseModifiers(uint256 tokenId) internal view returns(FurLib.RewardModifiers memory) {
    return _rewardModifiers(furballs[tokenId], tokenId, address(0), 0);
  }

  /// @notice Ends the current explore/battle and dispenses rewards
  /// @param tokenId The furball
  function _collect(uint256 tokenId, address sender, uint8 permissions) internal {
    FurLib.Furball memory furball = furballs[tokenId];
    address owner = ownerOf(tokenId);

    // The engine is allowed to force furballs into exploration mode
    // This allows it to end a battle early, which will be necessary in PvP
    require(owner == sender || permissions >= FurLib.PERMISSION_ADMIN, "OWN");

    // Scale duration to the time the edition has been live
    if (furball.last == 0) {
      uint64 launchedAt = uint64(editions[tokenId % 0x100].liveAt());
      require(launchedAt > 0 && launchedAt < uint64(block.timestamp), "PRE");
      furball.last = furball.birth > launchedAt ? furball.birth : launchedAt;
    }

    // Calculate modifiers to be used with this collection
    FurLib.RewardModifiers memory mods =
      _rewardModifiers(furball, tokenId, owner, fur.cleanSnacks(tokenId));

    // Reset the collection for this furball
    uint32 duration = uint32(uint64(block.timestamp) - furball.last);
    collect[tokenId].fur = 0;
    collect[tokenId].experience = 0;
    collect[tokenId].levels = 0;

    if (mods.zone >= 0x10000) {
      // Battle zones earn FUR and assign to the owner
      uint32 f = uint32(_calculateReward(duration, FurLib.FUR_PER_INTERVAL, mods.furPercent));
      if (f > 0) {
        fur.earn(owner, f);
        collect[tokenId].fur = f;
      }
    } else {
      // Explore zones earn EXP...
      uint32 exp = uint32(_calculateReward(duration, FurLib.EXP_PER_INTERVAL, mods.expPercent));
      (uint32 totalExp, uint16 levels) = engine.onExperience(furballs[tokenId], owner, exp);

      collect[tokenId].experience = exp;
      collect[tokenId].levels = levels;

      furballs[tokenId].level += levels;
      furballs[tokenId].experience = totalExp;
    }

    // Generate loot and assign to furball
    uint32 interval = uint32(intervalDuration);
    uint128 lootId = engine.dropLoot(duration / interval, mods);
    collect[tokenId].loot = lootId;
    if (lootId > 0) {
      _pickup(tokenId, lootId);
    }

    // Timestamp the last interaction for next cycle.
    furballs[tokenId].last = uint64(block.timestamp);

    // Emit the reward ID for frontend
    uint32 moves = furball.moves + 1;
    furballs[tokenId].moves = moves;
    emit Collection(tokenId, moves);
  }

  /// @notice Mints a new furball
  /// @dev Recursive function; generates randomization seed for the edition
  /// @param to The recipient of the furball
  /// @param nonce A recursive counter to prevent infinite loops
  function _spawn(address to, uint8 editionIndex, uint8 nonce) internal {
    require(nonce < 10, "SUPPLY");
    require(editionIndex < editions.length, "ED");

    IFurballEdition edition = editions[editionIndex];

    // Generate a random furball tokenId; if it fails to be unique, recurse!
    (uint256 tokenId, uint16 rarity) = edition.spawn();
    tokenId += editionIndex;
    if (_exists(tokenId)) return _spawn(to, editionIndex, nonce + 1);

    // Ensure that this wallet has not exceeded its per-edition mint-cap
    uint32 owned = edition.minted(to);
    require(owned < edition.maxMintable(to), "LIMIT");

    // Check the current edition's constraints (caller should have checked costs)
    uint16 cnt = edition.count();
    require(cnt < edition.maxCount(), "MAX");

    // Initialize the memory struct that represents the furball
    furballs[tokenId].number = uint32(totalSupply() + 1);
    furballs[tokenId].count = cnt;
    furballs[tokenId].rarity = rarity;
    furballs[tokenId].birth = uint64(block.timestamp);

    // Finally, mint the token and increment internal counters
    _mint(to, tokenId);

    edition.addCount(to, 1);
  }

  /// @notice Happens each time a furball changes wallets
  /// @dev Keeps track of the furball timestamp
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override {
    super._beforeTokenTransfer(from, to, tokenId);

    // Update internal data states
    furballs[tokenId].trade = uint64(block.timestamp);

    // Delegate other logic to the engine
    engine.onTrade(furballs[tokenId], from, to);
  }

  // -----------------------------------------------------------------------------------------------
  // Game Engine & Moderation
  // -----------------------------------------------------------------------------------------------

  function stats(uint256 tokenId, bool contextual) public view returns(FurLib.FurballStats memory) {
    // Base stats are calculated without team size so this doesn't effect public metadata
    FurLib.Furball memory furball = furballs[tokenId];
    FurLib.RewardModifiers memory mods =
      _rewardModifiers(
        furball,
        tokenId,
        contextual ? ownerOf(tokenId) : address(0),
        contextual ? fur.snackEffects(tokenId) : 0
      );

    return FurLib.FurballStats(
      uint16(_calculateReward(intervalDuration, FurLib.EXP_PER_INTERVAL, mods.expPercent)),
      uint16(_calculateReward(intervalDuration, FurLib.FUR_PER_INTERVAL, mods.furPercent)),
      mods,
      furball,
      fur.snacks(tokenId)
    );
  }

  /// @notice This utility function is useful because it force-casts arguments to uint256
  function _calculateReward(
    uint256 duration, uint256 perInterval, uint256 percentBoost
  ) internal view returns(uint256) {
    uint256 interval = intervalDuration;
    return (duration * percentBoost * perInterval) / (100 * interval);
  }

  // -----------------------------------------------------------------------------------------------
  // Public Views/Accessors (for outside world)
  // -----------------------------------------------------------------------------------------------

  /// @notice Provides the OpenSea storefront
  /// @dev see https://docs.opensea.io/docs/contract-level-metadata
  function contractURI() public view returns (string memory) {
    return governance.metaURI();
  }

  /// @notice Provides the on-chain Furball asset
  /// @dev see https://docs.opensea.io/docs/metadata-standards
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId));
    return string(abi.encodePacked("data:application/json;base64,", FurLib.encode(abi.encodePacked(
      editions[tokenId % 0x100].tokenMetadata(
        engine.attributesMetadata(tokenId),
        tokenId,
        furballs[tokenId].number
      )
    ))));
  }

  // -----------------------------------------------------------------------------------------------
  // OpenSea Proxy
  // -----------------------------------------------------------------------------------------------

  /// @notice Whitelisting the proxy registies for secondary market transactions
  /// @dev See OpenSea ERC721Tradable
  function isApprovedForAll(address owner, address operator)
      override
      public
      view
      returns (bool)
  {
    return engine.canProxyTrades(owner, operator) || super.isApprovedForAll(owner, operator);
  }

  /// @notice This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
  /// @dev See OpenSea ContentMixin
  function _msgSender()
    internal
    override
    view
    returns (address sender)
  {
    if (msg.sender == address(this)) {
      bytes memory array = msg.data;
      uint256 index = msg.data.length;
      assembly {
        // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
        sender := and(
          mload(add(array, index)),
          0xffffffffffffffffffffffffffffffffffffffff
        )
      }
    } else {
      sender = msg.sender;
    }
    return sender;
  }

  // -----------------------------------------------------------------------------------------------
  // Configuration / Admin
  // -----------------------------------------------------------------------------------------------

  function setFur(address furAddress) external onlyAdmin {
    fur = Fur(furAddress);
  }

  function setFurgreement(address furgAddress) external onlyAdmin {
    furgreement = Furgreement(furgAddress);
  }

  function setGovernance(address addr) public onlyAdmin {
    governance = Governance(payable(addr));
  }

  function setEngine(address addr) public onlyAdmin {
    engine = ILootEngine(addr);
  }

  function addEdition(address addr, uint8 idx) public onlyAdmin {
    if (idx >= editions.length) {
      editions.push(IFurballEdition(addr));
    } else {
      editions[idx] = IFurballEdition(addr);
    }
  }

  function _isReady() internal view returns(bool) {
    return address(engine) != address(0) && editions.length > 0
      && address(fur) != address(0) && address(governance) != address(0);
  }

  /// @notice Handles auth of msg.sender against cheating and/or banning.
  /// @dev Pass nonzero sender to act as a proxy against the furgreement
  function _approvedSender(address sender) internal view returns (address, uint8) {
    // No sender (for gameplay) is approved until the necessary parts are online
    require(_isReady(), "!RDY");

    if (sender != address(0) && sender != msg.sender) {
      // Only the furgreement may request a proxied sender.
      require(msg.sender == address(furgreement), "PROXY");
    } else {
      // Zero input triggers sender calculation from msg args
      sender = _msgSender();
    }

    // All senders are validated thru engine logic.
    uint8 permissions = uint8(engine.approveSender(sender));

    // Zero-permissions indicate unauthorized.
    require(permissions > 0, "PLR");

    return (sender, permissions);
  }

  modifier gameAdmin() {
    (address sender, uint8 permissions) = _approvedSender(address(0));
    require(permissions >= FurLib.PERMISSION_ADMIN, "GAME");
    _;
  }
}