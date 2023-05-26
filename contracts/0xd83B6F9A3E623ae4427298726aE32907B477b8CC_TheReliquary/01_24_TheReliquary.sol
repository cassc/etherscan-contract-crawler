// SPDX-License-Identifier: Unlicense
/// @title: the reliquary
/// @author: remnynt.eth

/*
   _   _                     _ _                                
  | |_| |__   ___   _ __ ___| (_) __ _ _   _  __ _ _ __ _   _   
  | __| '_ \ / _ \ | '__/ _ \ | |/ _` | | | |/ _` | '__| | | |  
  | |_| | | |  __/ | | |  __/ | | (_| | |_| | (_| | |  | |_| |  
   \__|_| |_|\___| |_|  \___|_|_|\__, |\__,_|\__,_|_|   \__, |  
                                    |_|                 |___/   
*/
/*
  Seeker,

    Rumors abound ... proof of the divine? The "original" mystery?
    The way I see it, there was no spark; time has no beginning.

    We can try to find that early place, before everything; indeed, perhaps it's our duty.
  But that quest to find the first little thing that happened is an asymptote to the unknowable.
  As if something could flicker out of nothing, the first vibration in a void is just as likely
  the last of what came before, dancing on a mirror's edge.

    And yet, undaunted, we pull on those strings, yearning to unravel the mystery of our origin.
  Which thus far, brings us to the elements eight. Whether you worship those gods, practice the
  schools of magic, or pay no heed at all, the one shared truth is that these elements are the
  fundamental building blocks of our world. Learned arcanists believe each its own substrate of
  aether, a medium upon which pure elemental energy flows, and from the summation of those
  microscopic movements arise the physical laws as we know them. It's that knowledge that's gotten
  us this far.

    Of course, most scoff at the theorycraft, finding it easier to cling to the zealotry of this
  element's church or that. Nevertheless, all eyes are on this singular discovery: the reliquary.
  Ancient and nameless, lost in the shifting sands of the Bal'gurub, its existence will bring
  every explorer worth their salt for horizons around. If you can get inside, and claim one of
  its relics, study it; there's no doubt we'll be one step closer to uncovering the truth.

    Now, be warned, adventurer. We know not what dangers lie within, nor how to gain entry.
  Steel yourself, take what supplies you can carry, and elements, or gods, be with you.

    Ahn Pendrose
    Guild's Knight of the Seekers
 */

pragma solidity ^0.8.4;

import "@0xsequence/sstore2/contracts/SSTORE2.sol";
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './ERC721ATM.sol';
import './TRMeta.sol';

/// @notice There are reports, first sourced from a nomadic shepherd, that indicate an enigmatic
///         structure has been partially revealed by the sands' ebb and flow. It's located a few
///         horizons beyond the southern edge of the Emptiness, that most unforgiving and desolate
///         corner of the desert. He was foolish enough to chase a runaway from his flock that far,
///         let alone to tell the tale. Unsurprisingly, he's since "gone missing." Droves of
///         treasure hunters have already begun to descend upon the nearest village. They're
///         calling it, "the reliquary."
contract TheReliquary is
  ERC721ATM('the reliquary', 'RELICS'),
  ERC721Holder,
  ReentrancyGuard
{
  using Strings for uint256;

  struct Reliquary {
    uint8 curiosDiscovered;
    uint8 secretsDiscovered;
    bool isDiscovered;
    string runicSeal;
    string hiddenLeyLines;
  }

  struct Relic {
    uint8 level;
    uint32 mana;
    bool isDivinityQuestLoot;
    bool isSecretDiscovered;
    address authorizedCreator;
    address glyph;
    string transmutation;
    uint24[] colors;
    bytes32 runeHash;
  }

  struct Adventurer {
    uint256 currentChamber;
    uint256 aether;
  }

  Reliquary private reliquary;

  /// @notice A collection of curious items sealed for millennia within the reliquary.
  ///         By whom and for what purpose are yet to be determined.
  mapping(uint256 => Relic) public relics;

  /// @notice A record of the brave souls who've attempted entry into the reliquary.
  ///         Those able to channel aether from vibes have been noted.
  mapping(address => Adventurer) public adventurers;

  /// @notice Vibes? Oh yes, our shorthand for vibrational energy; a crafty artificer
  ///         managed to capture it, pure elemental aether, into these vessels we call "vibes."
  ///         There may yet be some available; their aether identifier is:
  ///         0x6c7C97CaFf156473F6C9836522AE6e1d6448Abe7
  mapping(uint256 => bool) public vibesAetherChanneled;

  event RelicUpdate(uint256 tokenId);

  error ReliquaryNotDiscovered();
  error DivinityQuestProgressionMismatch();
  error NotEntrustedOrInYourPossession();
  error NotApprovedCreatorOrOwner();
  error GrailsAreUnalterable();
  error NoAdvancedSpellcastingContracts();
  error InvalidTokenId();
  error InvalidElement();
  error UnableToCarrySoManyAtOnce();
  error OutOfRelics();
  error MissingInscription();
  error ReliquaryAlreadySealed();
  error IncorrectWhispers();
  error IncorrectElementalWeakness();
  error IncorrectInnerDemonElement();
  error OutOfCurios();
  error NotEnoughAether();
  error NoSecretsLeftToReveal();
  error RelicAlreadyWellStudied();
  error NotEnoughMana();
  error NoAetherRemainingUseMintInstead();
  error OnlyBurnsVibes();
  error InvalidCustomization();
  error RelicAlreadyAtMaxLevel();

  constructor() {
    // The aetheric toll is reduced for the bravest of adventurers.
    reliquary.curiosDiscovered = 1;
    reliquary.secretsDiscovered = 1;
  }

  receive() external payable {}
  fallback() external payable {}

  modifier prohibitTimeTravel() {
    // Will happen, happening, happened. Millennia can pass in an instant, as long as
    // each little thing happens in the right order and everything in its right place.
    if (!reliquary.isDiscovered) revert ReliquaryNotDiscovered();
    _;
  }

  modifier prohibitTeleportation(uint256 requiredChamber) {
    // You know not where you stand. Follow the steps of the Divinity Quest, and you shall
    // find that which you seek; that is unless those other treasure hunters got there first.
    uint256 currentChamber = adventurers[_msgSender()].currentChamber;
    if (currentChamber != requiredChamber) revert DivinityQuestProgressionMismatch();
    _;
  }

  modifier preventDeadEnds() {
    // The coffers of Divinity's End have nought left but motes of dust.
    // You may yet find other relics if you explore the less precarious parts of the reliquary.
    if (reliquary.curiosDiscovered > TRKeys.CURIO_SUPPLY) revert OutOfCurios();
    _;
  }

  modifier prohibitThievery(uint256 tokenId) {
    // You are not the rightful owner, but don't be discouraged. Everything has a price ...
    if (!isApprovedOrOwnerOf(tokenId)) revert NotEntrustedOrInYourPossession();
    _;
  }

  modifier prohibitVandalism(uint256 tokenId) {
    // You are not the rightful owner or authorized creator. Do ask permission, first!
    if (!isApprovedOrOwnerOf(tokenId)
      && _msgSender() != relics[tokenId].authorizedCreator
      && _msgSender() != TRKeys.VIBES_GENESIS
      && _msgSender() != TRKeys.VIBES_OPEN)
    {
      revert NotApprovedCreatorOrOwner();
    }
    _;
  }

  modifier prohibitDesecration(uint256 tokenId) {
    // A relentlessly curious collector once hired a master smith to deconstruct a grail. The pair
    // were lucky to survive; they were found perforated by metal shrapnel and knocked unconscious
    // by the otherworldly reverberations that erupted from the first strike of his hammer.
    if (getGrailId(tokenId) != TRKeys.GRAIL_ID_NONE) revert GrailsAreUnalterable();
    _;
  }

  modifier prohibitAdvancedSpellcasting() {
    // Advanced spellcasting is prohibited. There's no doubt with this level of expertise,
    // you'd fell a dragon with your last enchanted arrow in the midst of a blizzard atop the
    // tallest mountain, but do save your energy for such an occasion!
    if (tx.origin != _msgSender()) revert NoAdvancedSpellcastingContracts();
    _;
  }

  modifier prohibitBlasphemy(uint256 tokenId) {
    // No such relic exists! One cannot simply speak a thing into existence through sheer force
    // of will. I suppose you'd also like to print paper money from a steam-powered press?
    if (tokenId < 1 || tokenId > super.totalSupply()) revert InvalidTokenId();
    _;
  }

  modifier requireValidElement(string memory element) {
    // Do respect the eight elements; call them by their proper names.
    // When writing, be sure to capitalize the first letter to distinguish the element from
    // a more common manifestation, for example, the ocean's salty water is of the Water element.
    if (TRUtils.compare(element, TRKeys.ELEM_NATURE)
      || TRUtils.compare(element, TRKeys.ELEM_LIGHT)
      || TRUtils.compare(element, TRKeys.ELEM_WATER)
      || TRUtils.compare(element, TRKeys.ELEM_EARTH)
      || TRUtils.compare(element, TRKeys.ELEM_WIND)
      || TRUtils.compare(element, TRKeys.ELEM_ARCANE)
      || TRUtils.compare(element, TRKeys.ELEM_SHADOW)
      || TRUtils.compare(element, TRKeys.ELEM_FIRE))
    {
      // A valid element, indeed!
    } else {
      // No such element exists!
      revert InvalidElement();
    }
    _;
  }

  modifier enforceInventoryLimits(uint256 mintCount) {
    // Don't expect to escape the reliquary with more than you can carry.
    if (mintCount > TRKeys.INVENTORY_CAPACITY) revert UnableToCarrySoManyAtOnce();
    _;
  }

  modifier enforceAbsoluteScarcity(uint256 mintCount) {
    // This old place is empty now. If you must lay hands on a relic yourself, you may be able to
    // convince a fellow adventurer to part with theirs...
    uint256 currentRelics = totalSupply() + 1 - reliquary.curiosDiscovered;
    if (currentRelics + mintCount > TRKeys.RELIC_SUPPLY) revert OutOfRelics();
    _;
  }

  /// @notice Divinity Quest - Step 0: When is now?
  /// @dev The past stretches out behind us, like the horizon, always out of reach.
  ///      Done or undone, it matters not. Continue onward with what you've got.
  ///      A lone sage walks his fated path. The scripts, his guide. The gods, his wrath.
  /// @param inscription With this sacred runeword, the Ancient Reliquary is sealed.
  function inscribeRunicSeal(string memory inscription)
    public
    onlyOwner
  {
    // That is not a runic seal; the sage falters, but mustn't lose hope.
    if (bytes(inscription).length == 0) revert MissingInscription();

    // The Ancient Reliquary was sealed long ago.
    if (bytes(reliquary.runicSeal).length != 0) revert ReliquaryAlreadySealed();

    // The sage met with destiny.
    // The truth, safe within, would soon outlast those who sought to destroy it.
    reliquary.runicSeal = inscription;

    // And so, it came to pass. Centuries, millennia, the world ever changing...
    // Until finally today, having laid dormant, concealed, for so long, it is found once again.
    reliquary.isDiscovered = true;
  }

  /// @notice Divinity Quest - Step 1: Enter the Ancient Reliquary
  /// @dev The entrance was sealed with a powerful runeword long ago.
  ///      The spell used here has the markings of a forgotten order.
  ///      All that remains is a name: "The Guardians of Origin."
  /// @param whispering There must be a way inside. What if we could find the inscription,
  ///                   or at least remnants of it? Scan the surrounding aether...
  function whisperRunicSeal(string memory whispering)
    public
    preventDeadEnds
    prohibitTimeTravel
    prohibitTeleportation(TRKeys.RELIQUARY_CHAMBER_OUTSIDE)
  {
    // Your whispering is lost in the rasps of the desert wind.
    if (!TRUtils.compare(whispering, reliquary.runicSeal)) revert IncorrectWhispers();

    // Your syllables ignite in blue flames against the solid rock slab that blocks the entrance.
    // As it rumbles open before you, the glow of elden magic reveals a stone passage.
    // You step inside, determined to discover the truth. The Guardian's Hall awaits.
    adventurers[_msgSender()].currentChamber = TRKeys.RELIQUARY_CHAMBER_GUARDIANS_HALL;
  }

  /// @notice Divinity Quest - Step 2: Access the Inner Sanctum
  /// @dev The Guardian's Hall extends in both directions, like a ring wrapped 'round the reliquary.
  ///      An army of Elemental Guardians marches endlessly within the massive circular corridor.
  ///      Beyond them, lies the Inner Sanctum, and the only way through is by force.
  /// @param attackElement Breaking this line won't be easy; we need to land a spell at just the
  ///                      right moment, coinciding with the elemental weakness of the guardian
  ///                      before us. I'd estimate a 1 in 8 chance of success. Good luck!
  function challengeElementalGuardians(string memory attackElement)
    public
    preventDeadEnds
    prohibitTeleportation(TRKeys.RELIQUARY_CHAMBER_GUARDIANS_HALL)
  {
    // You seize the moment, attacking the elemental directly in front of you.
    string memory previousHash = uint256(blockhash(block.number - 1)).toHexString();
    string memory guardianElement = detectElementals(previousHash);
    string memory weaknessElement = detectElementalWeakness(guardianElement);

    // It's not very effective! Rattled, but unscathed, you resolve to try again.
    if (!TRUtils.compare(weaknessElement, attackElement)) revert IncorrectElementalWeakness();

    // It's super effective! The elemental groans as it implodes spectacularly!
    // The opening is just enough. You sprint across the hall, and down a well-worn stair.
    // At the bottom, the Inner Sanctum beckons in ominous silence.
    adventurers[_msgSender()].currentChamber = TRKeys.RELIQUARY_CHAMBER_INNER_SANCTUM;
  }

  /// @notice Divinity Quest - Step 3: Defeat your Inner Demon
  /// @dev Every man has within him a darkness, the raw echoes of primordial chaos.
  ///      Soulbound, these demons can never be truly purged, but perhaps, with tremendous
  ///      self-awareness and strength of will, they can be controlled. The Inner Sanctum
  ///      is a space designed for that very purpose. A shrine for meditation sits calmly
  ///      in the chamber's center, across from the gilded gates that lead to Divinity's End.
  /// @param innerDemonElement Kneel before the shrine. Your first goal is to identify the type
  ///                          of demon buried within the depths of your heart.
  /// @param attackElement Once identified, you must also discover, and make use of, its weakness.
  function challengeInnerDemon(string memory innerDemonElement, string memory attackElement)
    public
    preventDeadEnds
    prohibitTeleportation(TRKeys.RELIQUARY_CHAMBER_INNER_SANCTUM)
  {
    // Bowing your head and closing your eyes, you fill your lungs with the stale air.
    string memory walletElement = detectDemons(_msgSender());

    // You fail to understand that which holds you back. You must keep searching.
    if (!TRUtils.compare(walletElement, innerDemonElement)) revert IncorrectInnerDemonElement();

    // A cursed demon emerges, tethered from somewhere deep within your soul.
    string memory weaknessElement = detectElementalWeakness(walletElement);

    // Tendrils of magic coalesce between its claws, as your attempt to counter has no effect.
    // It launches a powerful bolt, striking you directly in the chest.
    // A searing pain grips your heart, and suddenly, nothing. Darkness.
    // Hours pass, or days? You awaken, alone, but alive. Was it ... just a dream?
    if (!TRUtils.compare(weaknessElement, attackElement)) revert IncorrectElementalWeakness();

    // The demon releases a condensed spell blast! With a swift wave of your hand,
    // streaking magic from your fingertips, you crush the enemy's bolt in the palm of your hand.
    // The shockwave from the elemental annihilation, rips the air from the room, and the demon,
    // from its corporeal manifestation. A gleaming aura ahead reveals the path to Divinity's End.
    adventurers[_msgSender()].currentChamber = TRKeys.RELIQUARY_CHAMBER_DIVINITYS_END;
  }

  /// @notice Divinity Quest - Step 4: Claim a Divine Curio
  /// @dev As you enter the most sacred place within the reliquary, your feet grow heavy, your
  ///      senses captivated by its grandeur. Like the interior of a palace most grand, all is
  ///      engulfed in shimmering warm light, emanating from enchanted magical cores, ensconced
  ///      within orbs of pure gold filigree, a celebration of ancient craftsmanship in worship
  ///      of the divine. At last, you've arrived. A tithe of aether, mana channeled from your
  ///      very being, is required. A threshold of at least 0.08 will suffice.
  function mintDivineCurio()
    public
    payable
    nonReentrant
    preventDeadEnds
    prohibitAdvancedSpellcasting
    prohibitTeleportation(TRKeys.RELIQUARY_CHAMBER_DIVINITYS_END)
  {
    // A worthy tithe of aether is required to claim a divine curio.
    if (msg.value < TRKeys.CURIO_TITHE) revert NotEnoughAether();

    // Your tithe accepted, a roughly hewn pedestal begins to rise against the far wall.
    // Divine light fills the room, illuminating golden adornments resting beneath lifetimes
    // of dust. It's almost too bright to see; a curious relic lay before you atop the pedestal.
    // As you take it into your hands, magic courses across its surface, responding to your touch.
    // An ancient device of sorts? A thought sparks, as if not your own: learn, create, feel ...
    adventurers[_msgSender()].currentChamber = TRKeys.RELIQUARY_CHAMBER_CHAMPIONS_VAULT;
    _mintDivineCurio();
  }

  /// @notice Spell of Divination: Secrets
  /// @dev Use this spell whilst studying a relic in your possession. With any luck, you may
  ///      discover its secrets. At the very least, it's a great way to store up mana for use
  ///      on your future travels.
  /// @param tokenId The relic you seek to study; of course, it must also be in your possession.
  function seekDivineKnowledge(uint256 tokenId)
    public
    prohibitThievery(tokenId)
  {
    // The Queen's Grails, and the ley lines connecting them, have all been discovered.
    if (reliquary.secretsDiscovered > TRKeys.SECRETS_OF_THE_GRAIL) revert NoSecretsLeftToReveal();

    // This relic has already been thoroughly studied.
    if (relics[tokenId].isSecretDiscovered) revert RelicAlreadyWellStudied();

    // Your fervent studies bear fruit, another secret uncovered. Filled with excitement,
    // you feel primal mana coursing from within; your relic glows as if charged with new power.
    relics[tokenId].isSecretDiscovered = true;
    relics[tokenId].mana += TRKeys.MANA_FROM_DIVINATION;
    reliquary.secretsDiscovered++;

    if (reliquary.secretsDiscovered > TRKeys.SECRETS_OF_THE_GRAIL) {
      // A revelation! You've discovered hidden ley lines that run beneath the reliquary.
      // They seem to connect to certain relics ... but what does it mean?
      reliquary.hiddenLeyLines = getRuneHash(tokenId);
    }
  }

  /// @notice Spell of Divination: Elementals
  /// @dev Use this spell to detect a nearby elemental and to identify its intrinsic element.
  /// @param previousHash A unique identifier representing your four-dimensional location in the
  ///                     space-time continuum. With it being nigh impossible to calculate a hash
  ///                     of your current position, it's best to rely on one previous.
  function detectElementals(string memory previousHash)
    public
    view
    returns (string memory)
  {
    TRKeys.RuneCore memory core;
    core.tokenId = TRKeys.ELEMENTAL_GUARDIAN_DNA;
    core.runeHash = previousHash;
    core.metadataAddress = getMetadataAddress(core.tokenId);
    return ITRMeta(core.metadataAddress).getElement(core);
  }

  /// @notice Spell of Divination: Demons
  /// @dev Use this spell on any uncorrupted creature to identify potential demons lurking within.
  /// @param id The unique identifier of the creature to analyze. Most bipedal humanoids keep a
  ///           copy in their wallet.
  function detectDemons(address id)
    public
    view
    returns (string memory)
  {
    TRKeys.RuneCore memory core;
    core.tokenId = TRKeys.ELEMENTAL_GUARDIAN_DNA;
    core.runeHash = uint256(uint160(id)).toHexString();
    core.metadataAddress = getMetadataAddress(core.tokenId);
    return ITRMeta(core.metadataAddress).getElement(core);
  }

  /// @notice Spell of Divination: Weaknesses
  /// @dev Use this spell whilst focusing your mind on any element. Upon casting, that element's
  ///      weakness will become known to you.
  /// @param element The element about which you seek knowledge.
  function detectElementalWeakness(string memory element)
    public
    pure
    returns (string memory)
  {
    if (TRUtils.compare(element, TRKeys.ELEM_NATURE)) {
      return TRKeys.ELEM_FIRE;
    } else if (TRUtils.compare(element, TRKeys.ELEM_FIRE)) {
      return TRKeys.ELEM_WATER;
    } else if (TRUtils.compare(element, TRKeys.ELEM_WATER)) {
      return TRKeys.ELEM_WIND;
    } else if (TRUtils.compare(element, TRKeys.ELEM_WIND)) {
      return TRKeys.ELEM_EARTH;
    } else if (TRUtils.compare(element, TRKeys.ELEM_EARTH)) {
      return TRKeys.ELEM_NATURE;
    } else if (TRUtils.compare(element, TRKeys.ELEM_ARCANE)) {
      return TRKeys.ELEM_SHADOW;
    } else if (TRUtils.compare(element, TRKeys.ELEM_SHADOW)) {
      return TRKeys.ELEM_LIGHT;
    } else {
      return TRKeys.ELEM_ARCANE;
    }
  }

  /// @notice Spell of Transmutation: Elements (USE WITH CAUTION)
  /// @dev This powerful spell can permanently transmute the element of a relic to any other,
  ///      but be warned! It consumes a vibe in the process; the vibe will be irreversibly
  ///      lost to the aether, where it can never be owned or used again.
  /// @param tokenId The relic which you seek to transmute.
  /// @param element The new element to which your relic will belong.
  /// @param burnVibeId The catalyst to be burned: a [genesis] or [open] vibe.
  ///                   This vibe will be burned, you will no longer own it, nor can anyone else.
  function transmuteElement(uint256 tokenId, string memory element, uint256 burnVibeId)
    public
  {
    _lockVibeForever(burnVibeId, tokenId);
    _transmuteElement(tokenId, element);
    emit RelicUpdate(tokenId);
  }

  function _transmuteElement(uint256 tokenId, string memory element)
    private
    prohibitVandalism(tokenId)
    prohibitDesecration(tokenId)
    requireValidElement(element)
  {
    relics[tokenId].transmutation = element;
  }

  /// @notice Spell of Creation: Glyphs (USE WITH CAUTION)
  /// @dev This powerful spell can permanently inscribe a glyph of your own design upon your relic,
  ///      but be warned! It consumes a vibe in the process; the vibe will be irreversibly
  ///      lost to the aether, where it can never be owned or used again.
  /// @param tokenId The relic which you seek to alter.
  /// @param glyph The data that defines the shape and characteristics of your design.
  ///              It's an array, length 64, of integers. Each integer represents a row
  ///              of points that make up your glyph. The 64 least-significant digits represent
  ///              each column within that row, 0 being no change, and 9 being max change.
  /// @param burnVibeId The catalyst to be burned: a [genesis] or [open] vibe.
  ///                   This vibe will be burned, you will no longer own it, nor can anyone else.
  function createGlyph(uint256 tokenId, uint256[] memory glyph, uint256 burnVibeId)
    public
  {
    _lockVibeForever(burnVibeId, tokenId);
    _createGlyph(tokenId, glyph, _msgSender());
    emit RelicUpdate(tokenId);
  }

  function _createGlyph(uint256 tokenId, uint256[] memory glyph, address credit)
    private
    prohibitVandalism(tokenId)
    prohibitDesecration(tokenId)
  {
    relics[tokenId].glyph = SSTORE2.write(abi.encode(credit, glyph));
  }

  /// @notice Spell of Imagination: Colors (USE WITH CAUTION)
  /// @dev This powerful spell can permanently infuse your relic with colors of your choosing,
  ///      but be warned! It consumes a vibe in the process; the vibe will be irreversibly
  ///      lost to the aether, where it can never be owned or used again.
  /// @param tokenId The relic which you seek to reimagine.
  /// @param colors The data that defines the color palette to use.
  ///               It's an array, length 6, of integers. Each integer represents a color,
  ///               between 0 (black) and 16777215 (white). Any colors added beyond the
  ///               color count of your relic will be ignored. Colors should be listed in
  ///               order of strength; the first is the primary color, at index 0.
  /// @param burnVibeId The catalyst to be burned: a [genesis] or [open] vibe.
  ///                   This vibe will be burned, you will no longer own it, nor can anyone else.
  function imagineColors(uint256 tokenId, uint24[] memory colors, uint256 burnVibeId)
    public
  {
    _lockVibeForever(burnVibeId, tokenId);
    _imagineColors(tokenId, colors);
    emit RelicUpdate(tokenId);
  }

  function _imagineColors(uint256 tokenId, uint24[] memory colors)
    private
    prohibitVandalism(tokenId)
    prohibitDesecration(tokenId)
  {
    relics[tokenId].colors = colors;
  }

  /// @notice Spell of Creation: Camaraderie
  /// @dev Use this spell to grant certain privileges to a trusted friend. The authorized friend
  ///      will be considered a creator who can use transmuteElement, createGlyph, and
  ///      imagineColors. At the time of spellcasting, the catalysts to be used must be held by the
  ///      creator.
  /// @param tokenId The relic which can be modified by the creator.
  /// @param creator The address belonging to the creator to be granted privileges. Pass address(0)
  ///                to revoke any so granted privileges.
  function authorizeCreator(uint256 tokenId, address creator)
    public
    prohibitThievery(tokenId)
  {
    relics[tokenId].authorizedCreator = creator;
  }

  /// @notice Spell of Enhancement: Relic Level
  /// @dev Use this spell to break limiters installed in the runic circuits of your relic. Doing
  ///      so will increase its mana regeneration, but may also change its visual appearance. Any
  ///      underlying corruption may be exposed. It's not a certainty, but it is possible that
  ///      our knowledge of these relics' inner-workings may advance over time, unlocking higher
  ///      potential levels.
  /// @param tokenId The relic which you seek to upgrade. It must contain enough mana to sustain
  ///                the upgrade; that mana will be consumed in the process.
  function upgradeRelic(uint256 tokenId)
    public
    prohibitThievery(tokenId)
  {
    address metadataAddress = getMetadataAddress(tokenId);
    uint8 maxLevel = ITRMeta(metadataAddress).getMaxRelicLevel();
    uint8 level = getLevel(tokenId);

    // This relic is at its pinnacle. Mayhap, one day, we will discover what it means to take it
    // one step further. Until then, congratulations on this triumph over ancient technology.
    if (level >= maxLevel) revert RelicAlreadyAtMaxLevel();

    consumeMana(tokenId, TRKeys.MANA_COST_TO_UPGRADE);
    relics[tokenId].level = ++relics[tokenId].level;
    emit RelicUpdate(tokenId);
  }

  /// @notice Spell of Divination: Relic Level
  /// @dev Use this spell to measure the upgrade level of a given relic.
  /// @param tokenId The relic to be sized up.
  function getLevel(uint256 tokenId)
    public
    view
    returns (uint8)
  {
    return relics[tokenId].level + 1;
  }

  /// @notice Spell of Divination: Mana
  /// @dev Use this spell to measure the supply of mana stored within a given relic.
  ///      Be warned, adventurer! Transferring possession of relics as delicate as these will
  ///      reduce any stored mana by half.
  /// @param tokenId The relic to be measured.
  function getMana(uint256 tokenId)
    public
    view
    returns (uint32)
  {
    uint256 startTimestamp = _ownerships[tokenId].startTimestamp;
    if (startTimestamp == 0) {
      return relics[tokenId].mana;
    }

    uint8 level = getLevel(tokenId);
    uint32 manaPerYear = level < 2 ? TRKeys.MANA_PER_YEAR : TRKeys.MANA_PER_YEAR_LV2;
    uint256 elapsed = block.timestamp - startTimestamp;
    uint32 accumulatedMana = uint32((elapsed * manaPerYear) / TRKeys.SECONDS_PER_YEAR);
    return relics[tokenId].mana + accumulatedMana;
  }

  /// @notice Consume Resource: Mana (USE WITH CAUTION)
  /// @dev Our world is one of infinite possibilities. Using this spell alone is not advised,
  ///      but were it to be channeled into another spell, or magical contract, in the creation of,
  ///      or as a requirement for, some fantastic purpose, that would indeed be worthwhile.
  ///      By what means or from whom such purposes arise is uncertain, but the imaginations of
  ///      those practiced in magic are as boundless as the sea of stars afloat in the night sky.
  /// @param tokenId The relic which will have an amount of its mana consumed.
  /// @param manaCost The amount of mana required and consumed by the accompanying spellcast.
  function consumeMana(uint256 tokenId, uint32 manaCost)
    public
    prohibitThievery(tokenId)
  {
    uint32 mana = getMana(tokenId);

    // The cost requirements of mana are absolute; such is the nature of measuring pure energy.
    if (mana < manaCost) revert NotEnoughMana();

    relics[tokenId].mana = mana - manaCost;
    _ownerships[tokenId].startTimestamp = uint64(block.timestamp);
  }

  /// @notice Spell of Divination: Relic Traits - Element
  /// @dev Identifies the element trait of a given relic.
  ///      The universe, as we know it, is the result of elemental vibrations
  ///      within the aether, on a microscopic scale.
  /// @param tokenId The relic to be tested.
  function getElement(uint256 tokenId)
    public
    view
    returns (string memory)
  {
    TRKeys.RuneCore memory core = getRuneCore(tokenId);
    return ITRMeta(core.metadataAddress).getElement(core);
  }

  /// @notice Spell of Divination: Relic Traits - Color Count
  /// @dev Identifies the colors trait of a given relic.
  ///      On the surface, this is the number of colors within a relic's palette. Going deeper,
  ///      each color is a sort of elemental nucleus within the relic's structure, exerting
  ///      vibrational gravity throughout.
  /// @param tokenId The relic to be studied.
  function getColorCount(uint256 tokenId)
    public
    view
    returns (uint256)
  {
    TRKeys.RuneCore memory core = getRuneCore(tokenId);
    return ITRMeta(core.metadataAddress).getColorCount(core);
  }

  /// @notice Spell of Divination: Colors
  /// @dev Fetch the hex code for a specific color of a given relic, between 000000 and ffffff.
  ///      It's very rare to see two relics with the exact same palette, if ever at all.
  ///      This is due to subtle variations in the vibrational forces of aether.
  /// @param tokenId The relic to be queried.
  /// @param index The index of the color sought, inclusive between 0 and colors - 1.
  function getColorByIndex(uint256 tokenId, uint256 index)
    public
    view
    returns (string memory)
  {
    TRKeys.RuneCore memory core = getRuneCore(tokenId);
    return ITRMeta(core.metadataAddress).getColorByIndex(core, index);
  }

  /// @notice Spell of Divination: Grails
  /// @dev The legend of the Queen's Grails? A tale as old as time ...
  ///      The Queen was once a goddess, the first elemental of Light, and hailed by scholars as
  ///      the original muse. She crafted the most magnificent set of grails, divine artifacts
  ///      that were impossibly beautiful, unbreakable, and immutable. To behold them was to be
  ///      enlightened - to see the universe as a beautiful sparkling globe, frozen in all times
  ///      at once, speckled with brilliance and grandeur, all connected, all now, time itself
  ///      but an illusion. The other gods, fearful of mortals obtaining such a perspective,
  ///      wrapped her grails in powerful magic, shrouding them in obscurity. They were
  ///      unrecognizable, but the Queen was cunning; she wanted her creations to inspire.
  ///      She hid the grails amongst a gift of relics, which the other gods proudly bestowed
  ///      upon the kingdom of man. It was only afterwards that the God of Shadow discovered
  ///      her trick. What happened next is a story for another time, but suffice to say, this
  ///      was the spark that ignited the Celestial Wars, spanning the heavens and the earth.
  /// @param tokenId The relic to be inspected. If 0 is returned, then that relic is not a grail;
  ///                divine magic is powerful, and until we can dispel it, we truly don't know.
  function getGrailId(uint256 tokenId)
    public
    view
    returns (uint256)
  {
    TRKeys.RuneCore memory core = getRuneCore(tokenId);
    return ITRMeta(core.metadataAddress).getGrailId(core);
  }

  /// @notice Spell of Mathematics: Definition
  /// @dev Obtain the designs to recreate any relic from pure math and logic;
  ///      conjure a stunning visualization, afloat in the air before you.
  ///      You can have it all here, in red, blue, green.
  /// @param tokenId The relic to be conjured.
  function tokenScript(uint256 tokenId)
    public
    view
    returns (string memory)
  {
    TRKeys.RuneCore memory core = getRuneCore(tokenId);
    return ITRMeta(core.metadataAddress).tokenScript(core);
  }

  /// @notice Spell of Mathematics: Universal Runic Identifier
  /// @dev Blast enough Arcane magic through runic circuits, and you've got what arcanists call,
  ///      "data." This spell helps identify all of the key traits belonging to a particular relic.
  /// @param tokenId The relic to be identified.
  function tokenURI(uint256 tokenId)
    override
    public
    view
    returns (string memory)
  {
    TRKeys.RuneCore memory core = getRuneCore(tokenId);
    return ITRMeta(core.metadataAddress).tokenURI(core);
  }

  /// @notice Spell of Divination: Rune Core
  /// @dev Use this spell to isolate and analyze the runic nucleus of a relic. Understanding the
  ///      properties of a Rune Core is like knowing the seed of a flower, its entire life
  ///      blossoms before you in an instant.
  /// @param tokenId The relic to be analyzed.
  function getRuneCore(uint256 tokenId)
    public
    view
    prohibitBlasphemy(tokenId)
    returns (TRKeys.RuneCore memory)
  {
    // DEV: A RuneCore contains all the data stored on-chain for a given relic.
    TRKeys.RuneCore memory core;
    core.tokenId = tokenId;
    core.level = getLevel(tokenId);
    core.mana = getMana(tokenId);
    core.runeCode = getRuneCode(tokenId);
    core.runeHash = getRuneHash(tokenId);
    core.metadataAddress = getMetadataAddress(tokenId);
    core.isDivinityQuestLoot = relics[tokenId].isDivinityQuestLoot;
    core.isSecretDiscovered = relics[tokenId].isSecretDiscovered;
    core.secretsDiscovered = reliquary.secretsDiscovered;
    core.hiddenLeyLines = reliquary.hiddenLeyLines;
    core.transmutation = relics[tokenId].transmutation;
    core.colors = relics[tokenId].colors;

    // DEV: SSTORE2 significantly reduces the gas costs of glyph creation.
    if (relics[tokenId].glyph != address(0)) {
      (address credit, uint256[] memory glyph) = abi.decode(
        SSTORE2.read(relics[tokenId].glyph),
        (address, uint256[])
      );

      core.credit = credit;
      core.glyph = glyph;
    }
    return core;
  }

  /// @notice Spell of Aether: Rune Code
  /// @dev Relics are infused with the elements, and as such, we can view the shape of the
  ///      underlying aether by reading the physical effects on runic circuits. Each vibration
  ///      can be encoded into data, and when a relic is forged, the vibrations of the aether
  ///      forever leave their mark. The Rune Code is that unique aetheric stamp, a window
  ///      into the past; its time and its news, all captured for the Queen to use. The chance
  ///      of two relics sharing a Rune Code is just shy of impossible.
  /// @param tokenId The relic to be deciphered.
  function getRuneCode(uint256 tokenId)
    public
    view
    returns (uint256)
  {
    // DEV: Follow the ERC721A pattern, but for random blockhashes (one per mint batch).
    uint256 hashIndex;
    bytes32 entropy = relics[tokenId].runeHash;
    while (entropy == bytes32(0)) {
      ++hashIndex;
      entropy = relics[++tokenId].runeHash;
    }

    // DEV: Split each blockhash into even pieces, indexed by mint order in a batch.
    uint256 start = hashIndex * TRKeys.BYTES_PER_RELICHASH;
    uint256 end = TRKeys.BYTES_PER_BLOCKHASH;
    uint256 shift = (end - TRKeys.BYTES_PER_RELICHASH) - start;
    bytes32 finalHash = bytes32((entropy >> shift * 8) & TRKeys.RELICHASH_MASK);
    uint256 runeCode = uint256(finalHash);

    // DEV: Minimize potential hash collisions, while preventing overflow or underflow.
    if (runeCode >= TRKeys.HALF_POSSIBILITY_SPACE) {
      runeCode -= tokenId;
    } else {
      runeCode += tokenId;
    }
    return runeCode;
  }

  /// @notice Spell of Aether: Rune Hash
  /// @dev A Rune Hash is a human readable reinterpretation of a Rune Code. These are most often
  ///      used as a sort of aetheric name to tell relics apart.
  /// @param tokenId The relic to be named.
  function getRuneHash(uint256 tokenId)
    public
    view
    returns (string memory)
  {
    return getRuneCode(tokenId).toHexString(TRKeys.BYTES_PER_RELICHASH);
  }

  /// @notice Spell of Aether: Vibrations
  /// @dev These are the aetheric vibrations wrapped up and forever imprinted upon a relic as
  ///      it's forged.
  /// @param tokenId The relic being forged.
  function getAethericVibrations(uint256 tokenId)
    private
    view
    returns (bytes32)
  {
    // DEV: Minimize collisions by moving our index in the opposite direction of hashes.
    uint256 decrement = 1 + 255 % (block.number - 1);
    uint256 increment = tokenId % decrement;
    uint256 blockIndex = block.number - decrement + increment;
    return blockhash(blockIndex);
  }

  /// @notice Claim Relic(s)
  /// @dev Root, ransack, and raid for random relics from within the reliquary!
  ///      Mind you, this is a holy place, and a tithe is due if you'd like to escape in one piece.
  ///      A minimum of 0.15 aether per relic is required. If you've got vibes currently in your
  ///      possession, try "mintWithVibesDiscount" first for a lesser tithe.
  /// @param mintCount The number of relics to claim. Limit 10 per transaction.
  function mint(uint256 mintCount)
    public
    payable
    nonReentrant
    prohibitTimeTravel
    prohibitAdvancedSpellcasting
    enforceInventoryLimits(mintCount)
    enforceAbsoluteScarcity(mintCount)
  {
    // Relics are divine in nature; a worthy tithe is strongly recommended.
    if (msg.value < TRKeys.RELIC_TITHE * mintCount) revert NotEnoughAether();

    _mintRelics(mintCount);
  }

  /// @notice Claim Relic(s) with Aether from Vibes
  /// @dev By channeling the innate aether within vibes, one can significantly reduce the
  ///      tithe. A minimum of 0.15 aether per relic is required, but each [genesis] vibe holds
  ///      0.12, while each [open] vibe holds 0.05, greatly reducing the overall cost. Vibes are
  ///      not burned or affected in the process, though once channeled, the same vibes cannot be
  ///      used for discounts again. Any excess aether will be stored and counted towards
  ///      any additional relics you claim. Please calculate your tithe with care, use
  ///      "calculateVibesDiscount" or visit https://vibes.art/ for an automated experience.
  /// @param mintCount The number of relics to claim. Limit 10 per transaction.
  function mintWithVibesDiscount(uint256 mintCount)
    public
    payable
    nonReentrant
    prohibitTimeTravel
    prohibitAdvancedSpellcasting
    enforceInventoryLimits(mintCount)
    enforceAbsoluteScarcity(mintCount)
  {
    uint256 discountGenesis = _channelVibesAether(TRKeys.VIBES_GENESIS, TRKeys.RELIC_DISCOUNT_GENESIS);
    uint256 discountOpen = _channelVibesAether(TRKeys.VIBES_OPEN, TRKeys.RELIC_DISCOUNT_OPEN);
    uint256 discountTotal = adventurers[_msgSender()].aether + discountGenesis + discountOpen;

    // Your aether shall not be wasted; use the "mint" method, instead.
    if (discountTotal == 0) revert NoAetherRemainingUseMintInstead();

    uint256 tithe = TRKeys.RELIC_TITHE * mintCount;
    if (tithe >= discountTotal) {
      tithe -= discountTotal;
      discountTotal = 0;
    } else {
      discountTotal -= tithe;
      tithe = 0;
    }

    // Even with the elemental power of vibes, a worthy tithe is still required.
    if (msg.value < tithe) revert NotEnoughAether();

    adventurers[_msgSender()].aether = discountTotal;
    _mintRelics(mintCount);
  }

  /// @notice Channel Aether from Vibes into an Adventurer's Tithe
  /// @dev This claims discounts for all vibes currently in your possession. Adding new vibes
  ///      that haven't been used will accrue additional discounts. Excess discounts are saved
  ///      and applied towards future relics. Discounts do not apply to the Divinity Quest.
  /// @param discountAddress The vibes contract to check for ownership.
  /// @param discountAmount The discount value per vibe to be claimed.
  function _channelVibesAether(address discountAddress, uint256 discountAmount)
    private
    returns (uint256)
  {
    Vibes discountContract = Vibes(discountAddress);
    uint256 tokenCount = discountContract.balanceOf(_msgSender());
    uint256 discountClaimed;
    for (uint256 i; i < tokenCount; i++) {
      uint256 tokenId = discountContract.tokenOfOwnerByIndex(_msgSender(), i);
      if (!vibesAetherChanneled[tokenId]) {
        vibesAetherChanneled[tokenId] = true;
        discountClaimed += discountAmount;
      }
    }
    return discountClaimed;
  }

  /// @notice Calculate the Discount from Vibes in this Wallet
  /// @dev A read-only measurement of aether stored in vibes.
  ///      Divide the result by 1000000000000000000 (18 zeroes) to convert to ETH.
  function calculateVibesDiscount()
    public
    view
    returns (uint256)
  {
    uint256 discountGenesis = _measureVibesAether(TRKeys.VIBES_GENESIS, TRKeys.RELIC_DISCOUNT_GENESIS);
    uint256 discountOpen = _measureVibesAether(TRKeys.VIBES_OPEN, TRKeys.RELIC_DISCOUNT_OPEN);
    return adventurers[_msgSender()].aether + discountGenesis + discountOpen;
  }

  /// @notice Measure Available Aether from Vibes
  /// @dev A read-only measurement of available aether.
  /// @param discountAddress The vibes contract to check for ownership.
  /// @param discountAmount The discount value per vibe.
  function _measureVibesAether(address discountAddress, uint256 discountAmount)
    private
    view
    returns (uint256)
  {
    Vibes discountContract = Vibes(discountAddress);
    uint256 tokenCount = discountContract.balanceOf(_msgSender());
    uint256 discountAvailable;
    for (uint256 i; i < tokenCount; i++) {
      uint256 tokenId = discountContract.tokenOfOwnerByIndex(_msgSender(), i);
      if (!vibesAetherChanneled[tokenId]) {
        discountAvailable += discountAmount;
      }
    }
    return discountAvailable;
  }

  /// @notice Claim Divine Curio
  /// @dev This action is only accessible to adventurers who have completed the Divinity Quest.
  function _mintDivineCurio()
    private
  {
    _safeMint(_msgSender(), 1);
    uint256 lastTokenId = totalSupply();
    relics[lastTokenId].runeHash = getAethericVibrations(lastTokenId);
    relics[lastTokenId].mana += TRKeys.MANA_FROM_REVELATION;
    relics[lastTokenId].isDivinityQuestLoot = true;
    reliquary.curiosDiscovered++;
  }

  /// @notice Claim Relic(s)
  /// @dev This action is for internal use only; see "mint" and "mintWithVibesDiscount."
  function _mintRelics(uint256 mintCount)
    private
  {
    _safeMint(_msgSender(), mintCount);
    uint256 lastTokenId = totalSupply();
    relics[lastTokenId].runeHash = getAethericVibrations(lastTokenId);
  }

  /// @notice Burn a Vibe
  /// @dev Lock a vibe within this contract forever,
  ///      effectively burning it while preserving the art.
  ///      Vibes are used in this way to modify and customize relics.
  function _lockVibeForever(uint256 vibeId, uint256 tokenId)
    private
  {
    Vibes vibesContract;
    if (vibeId < TRKeys.FIRST_OPEN_VIBES_ID) {
      vibesContract = Vibes(TRKeys.VIBES_GENESIS);
    } else {
      vibesContract = Vibes(TRKeys.VIBES_OPEN);
    }
    vibesContract.transferFrom(_msgSender(), address(this), vibeId);
    relics[tokenId].mana += TRKeys.MANA_FROM_VIBRATION;
  }

  /// @notice Mana Loss
  /// @dev The ancient runic circuits of relics are extremely fragile! When a relic is transferred,
  ///      any stored mana is reduced by half in the process. Please move, buy, and sell relics
  ///      with care. There are no warranties for divine artifacts lost to the seas of time.
  function _disturbMana(uint256 tokenId)
    private
  {
    uint32 mana = getMana(tokenId);
    if (mana > 0) {
      relics[tokenId].mana = mana / 2;
    }
  }

  /// @notice See _disturbMana
  function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
    internal
    override
  {
    super._beforeTokenTransfers(from, to, startTokenId, quantity);
    // DEV: Save gas and skip mint transactions, because mana always starts at 0.
    if (from != address(0)) {
      // DEV: Quantity is always 1 except in a mint transaction, so we can safely ignore
      //      iterating over other relics that may have been minted in an ERC721A batch.
      _disturbMana(startTokenId);
    }
  }

  /// @notice Full Customization
  /// @dev Use "safeTransferFrom" in [genesis] or [open] vibes contracts to send a single vibe to
  ///      this contract's address, for a single transaction to fully customize a relic.
  ///      This is the most vibe-efficient and gas-efficient way for a full customization, but
  ///      it generates less mana than performing each spell separately and burning more vibes.
  /// @param operator The wallet initiating the transaction, to be given creative credit. This will
  ///                 be passed automatically by the vibes contracts.
  /// @param data Encoded bytes in the format (uint256, string, uint256[], uint24[]), in order:
  ///             uint256 targetTokenId - the tokenId of the relic to be customized,
  ///             string element - transmute to this new element, empty string for no effect,
  ///             uint256[] glyph - a new glyph to etch onto the relic, empty array for no effect,
  ///             uint24[] colors - a reimagined color palette, empty array for no effect.
  ///             See the individual customization methods for further documentation.
  function onERC721Received(address operator, address, uint256, bytes memory data)
    public
    override
    prohibitTimeTravel
    returns (bytes4)
  {
    if (_msgSender() != TRKeys.VIBES_GENESIS && _msgSender() != TRKeys.VIBES_OPEN) {
      revert OnlyBurnsVibes();
    }

    uint256 targetTokenId;
    string memory element;
    uint256[] memory glyph;
    uint24[] memory colors;
    bool success = false;

    (targetTokenId, element, glyph, colors) = abi.decode(
      data, (uint256, string, uint256[], uint24[]));

    if (bytes(element).length > 0) {
      _transmuteElement(targetTokenId, element);
      success = true;
    }

    if (glyph.length > 0) {
      _createGlyph(targetTokenId, glyph, operator);
      success = true;
    }

    if (colors.length > 0) {
      _imagineColors(targetTokenId, colors);
      success = true;
    }

    if (!success) revert InvalidCustomization();

    relics[targetTokenId].mana += TRKeys.MANA_FROM_VIBRATION;
    emit RelicUpdate(targetTokenId);
    return this.onERC721Received.selector;
  }

  /// @notice Withdraw aether to contract owner.
  function withdrawAether()
    public
    onlyOwner
  {
    (bool success,) = owner().call{ value: address(this).balance }('');
    require(success);
  }
}

/// @notice This abstract contract matches both the [genesis] and [open] vibes contracts.
///         Mint vibes and learn more about the project at https://vibes.art/
abstract contract Vibes {
  function balanceOf(address owner) external view virtual returns (uint256 balance);
  function ownerOf(uint256 tokenId) external view virtual returns (address);
  function getApproved(uint256 tokenId) public view virtual returns (address);
  function isApprovedForAll(address owner, address operator) public view virtual returns (bool);
  function transferFrom(address from, address to, uint256 tokenId) public virtual;
  function tokenOfOwnerByIndex(address owner, uint256 index) external view virtual returns (uint256 tokenId);
}

/*
  Dear Reader,

    Thank you for participating in this experience and for allowing me to use the circuits of your
  imagination. This project is presented without promises or obligations. Where we go from here
  is anyone's guess. I would be honored to receive your presence and thoughts.

    - remnynt
    DjhEVKnKW6
*/