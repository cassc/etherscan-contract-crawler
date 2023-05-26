//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

import "hardhat/console.sol";

contract CryptoZunks is
  Ownable,
  ERC721Enumerable,
  ERC721Burnable,
  ReentrancyGuard
{
  using Strings for uint256;

  enum Slot {
    accessories,
    beard,
    ear,
    eyes,
    hat,
    lips,
    neck,
    smoke
  }

  mapping(string => bool) public unavailableZunks;
  mapping(uint256 => string) public serialIdToZunk;
  mapping(string => bool) public existingZunks;

  mapping(uint256 => uint256[]) public femaleProbabilities;
  mapping(uint256 => uint256[]) public maleProbabilities;

  string NO_OPTIONS = "no options";
  uint256 NO_REROLL_OPTIONS = 99999;

  uint256[8] femaleSlotProbabilities = [
    2608,
    0,
    3959,
    8614,
    10000,
    6625,
    1950,
    2080
  ];
  uint256[8] maleSlotProbabilities = [
    2608,
    7187,
    3959,
    6923,
    10000,
    2437,
    1825,
    3225
  ];
  uint256[] genderProbabilities = [5000, 5000];
  uint256[] skinProbabilities = [14, 36, 2454, 2454, 2454, 2456, 132];

  struct Attributes {
    uint256 accessories;
    uint256 beard;
    uint256 ear;
    uint256 eyes;
    uint256 hat;
    uint256 lips;
    uint256 neck;
    uint256 smoke;
  }

  struct AttributesAsString {
    string accessories;
    string beard;
    string ear;
    string eyes;
    string hat;
    string lips;
    string neck;
    string smoke;
  }

  struct SerialIdAndTokenRepresentation {
    uint256 serialId;
    string tokenRepresentation;
  }

  constructor() ERC721("CryptoZunks", "ZUNK") {
    femaleProbabilities[uint256(Slot.accessories)] = [1913, 5812, 1155, 1119];
    femaleProbabilities[uint256(Slot.beard)] = [
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0
    ];
    femaleProbabilities[uint256(Slot.ear)] = [10000];
    femaleProbabilities[uint256(Slot.eyes)] = [
      402,
      752,
      974,
      706,
      540,
      537,
      412,
      648,
      496,
      752,
      804,
      959,
      741,
      496,
      467,
      315
    ];
    femaleProbabilities[uint256(Slot.hat)] = [
      237,
      0,
      378,
      332,
      347,
      0,
      146,
      237,
      409,
      404,
      0,
      227,
      436,
      378,
      0,
      0,
      414,
      227,
      434,
      424,
      434,
      175,
      0,
      242,
      139,
      244,
      229,
      0,
      378,
      0,
      388,
      370,
      381,
      228,
      229,
      141,
      228,
      0,
      370,
      441,
      350
    ];
    femaleProbabilities[uint256(Slot.lips)] = [
      1567,
      1768,
      1664,
      1768,
      1664,
      1567
    ];
    femaleProbabilities[uint256(Slot.neck)] = [2778, 3756, 3467];
    femaleProbabilities[uint256(Slot.smoke)] = [5571, 1014, 1838, 1577];

    maleProbabilities[uint256(Slot.accessories)] = [1913, 5812, 1155, 1119];
    maleProbabilities[uint256(Slot.beard)] = [
      417,
      805,
      779,
      742,
      842,
      751,
      816,
      822,
      864,
      834,
      825,
      1502
    ];
    maleProbabilities[uint256(Slot.ear)] = [10000];
    maleProbabilities[uint256(Slot.eyes)] = [
      527,
      987,
      566,
      926,
      708,
      704,
      540,
      850,
      0,
      987,
      527,
      0,
      972,
      566,
      612,
      527
    ];
    maleProbabilities[uint256(Slot.hat)] = [
      505,
      75,
      0,
      0,
      369,
      433,
      155,
      242,
      434,
      0,
      512,
      317,
      463,
      0,
      692,
      442,
      440,
      483,
      463,
      451,
      231,
      0,
      517,
      0,
      0,
      0,
      346,
      281,
      231,
      512,
      0,
      0,
      0,
      486,
      0,
      0,
      196,
      251,
      0,
      470,
      0
    ];
    maleProbabilities[uint256(Slot.lips)] = [0, 1351, 2261, 2261, 0, 4125];
    maleProbabilities[uint256(Slot.neck)] = [2600, 2600, 4800];
    maleProbabilities[uint256(Slot.smoke)] = [5571, 1014, 1838, 1577];
  }

  bool public hasDevSingleMinted = false;
  bool public isMintAndRerollEnabled = false;
  uint256 private MAX_SUPPLY = 10000;
  uint256 private currentIndex = 10000;

  uint256 public freeMintsFromPoolRedeemed = 0;
  uint256 public freeMintsAllocatedByDevsCap = 300;
  mapping(address => uint256) freeMintsAllocatedByDevs;
  mapping(address => bool) public hasRedeemedFreeMintFromPool;

  event Zunk(
    address indexed user,
    uint256 serialId,
    string tokenRepresentation,
    bool isReroll
  );

  function _numMintedSoFar() internal view returns (uint256) {
    return currentIndex - 10000;
  }

  function freeMintOne() public payable nonReentrant {
    require(userHasFreeMint(msg.sender), "You have no free mints available (pool has ran out).");
    if (freeMintsAllocatedByDevs[msg.sender] > 0) {
      freeMintsAllocatedByDevs[msg.sender]--;
    } else {
      freeMintsFromPoolRedeemed++;
      hasRedeemedFreeMintFromPool[msg.sender] = true;
    }
    _mintNoCostChecks(1);
  }

  function mintOne() public payable nonReentrant {
    _mint(1);
  }

  function mintTwo() public payable nonReentrant {
    _mint(2);
  }

  function mintThree() public payable nonReentrant {
    _mint(3);
  }

  function mintFour() public payable nonReentrant {
    _mint(4);
  }

  function mintFive() public payable nonReentrant {
    _mint(5);
  }

  function mintSix() public payable nonReentrant {
    _mint(6);
  }

  function mintSeven() public payable nonReentrant {
    _mint(7);
  }

  function mintEight() public payable nonReentrant {
    _mint(8);
  }

  function mintNine() public payable nonReentrant {
    _mint(9);
  }

  function mintTen() public payable nonReentrant {
    _mint(10);
  }

  // internal minting function
  function _mint(uint256 _numToMint) internal {
    uint256 _numMinted = _numMintedSoFar();
    require(
      _numMinted + _numToMint <= MAX_SUPPLY,
      "There aren't this many zunks left."
    );
    uint256 costForMint = getCostForMints(_numToMint);
    require(msg.value >= costForMint, "Need to send more ETH.");
    if (msg.value > costForMint) {
      payable(msg.sender).transfer(msg.value - costForMint);
    }
    _mintNoCostChecks(_numToMint);
  }

  function _mintNoCostChecks(uint256 _numToMint) internal {
    require(isMintAndRerollEnabled, "Minting is not enabled.");
    _mintNoChecks(_numToMint);
  }

  function _mintNoChecks(uint256 _numToMint) internal {
    uint256 newSerialId = currentIndex;
    for (uint256 i = 0; i < _numToMint; i++) {
      _safeMint(msg.sender, newSerialId);

      string memory generatedZunk = generateZunk(newSerialId);
      if (isInvalidZunk(generatedZunk) || unableToRerollZunk(generatedZunk)) {
        generatedZunk = generateZunk(newSerialId);
      }
      require(
        !(isInvalidZunk(generatedZunk) || unableToRerollZunk(generatedZunk)),
        "Unable to mint, please try again."
      );
      serialIdToZunk[newSerialId] = generatedZunk;
      existingZunks[generatedZunk] = true;
      emit Zunk(msg.sender, newSerialId, generatedZunk, false);
      newSerialId++;
    }
    currentIndex = newSerialId;
  }

  function validateSlotToRerollValid(
    uint256 slotToReroll,
    Attributes memory attributes
  ) internal pure {
    uint256[] memory validSlots = getValidSlotsForReroll(attributes);
    bool slotToRerollValid = false;

    for (uint256 i = 0; i < validSlots.length; i++) {
      if (slotToReroll == validSlots[i]) {
        slotToRerollValid = true;
        break;
      }
    }

    require(slotToRerollValid, "slotToReroll is not valid for zunk");
  }

  function rerollZunk(uint256 serialId, uint256 slotToReroll) public payable {
    require(isMintAndRerollEnabled, "Reroll is not enabled");
    require(msg.sender == ownerOf(serialId), "Only owner can reroll.");
    require(slotToReroll != uint256(Slot.ear), "Cant reroll earring");
    uint256 costForReroll = getCostForRerollAttribute();
    require(msg.value >= costForReroll, "Need to send more ETH for reroll.");
    if (msg.value > costForReroll) {
      payable(msg.sender).transfer(msg.value - costForReroll);
    }

    string memory zunk = serialIdToZunk[serialId];
    string memory zunkSkinAsString = substring(zunk, 0, 2);
    string memory zunkGenderAsString = substring(zunk, 2, 4);
    Attributes memory attributes = createAttributesFromZunk(zunk);

    validateSlotToRerollValid(slotToReroll, attributes);

    uint256 zunkGender = convertToUint(zunkGenderAsString);
    uint256 zunkSkin = convertToUint(zunkSkinAsString);
    bool isFemale = isZunkFemale(zunkGender);

    string memory rerolledZunk = _rerollZunk(
      isFemale,
      serialId,
      zunkSkin,
      zunkGender,
      attributes,
      slotToReroll,
      zunk
    );

    require(
      !isInvalidZunk(rerolledZunk),
      "Could not reroll into a valid zunk, please try again."
    );

    serialIdToZunk[serialId] = rerolledZunk;
    existingZunks[rerolledZunk] = true;
    existingZunks[zunk] = false;
    emit Zunk(msg.sender, serialId, rerolledZunk, true);
  }

  function createAttributesFromZunk(string memory zunk)
    internal
    pure
    returns (Attributes memory)
  {
    string memory attributes1 = substring(zunk, 4, 6);
    string memory attributes2 = substring(zunk, 6, 8);
    string memory attributes3 = substring(zunk, 8, 10);
    string memory attributes4 = substring(zunk, 10, 12);
    string memory attributes5 = substring(zunk, 12, 14);
    string memory attributes6 = substring(zunk, 14, 16);
    string memory attributes7 = substring(zunk, 16, 18);
    string memory attributes8 = substring(zunk, 18, 20);
    return
      Attributes(
        convertToUint(attributes1),
        convertToUint(attributes2),
        convertToUint(attributes3),
        convertToUint(attributes4),
        convertToUint(attributes5),
        convertToUint(attributes6),
        convertToUint(attributes7),
        convertToUint(attributes8)
      );
  }

  function _rerollZunk(
    bool isFemale,
    uint256 serialId,
    uint256 zunkSkin,
    uint256 zunkGender,
    Attributes memory attributes,
    uint256 slotToReroll,
    string memory zunk
  ) internal view returns (string memory) {
    return
      _rerollZunk(
        isFemale,
        serialId,
        zunkSkin,
        zunkGender,
        attributes,
        slotToReroll,
        zunk,
        true
      );
  }

  function _rerollZunk(
    bool isFemale,
    uint256 serialId,
    uint256 zunkSkin,
    uint256 zunkGender,
    Attributes memory attributes,
    uint256 slotToReroll,
    string memory zunk,
    bool throwIfUnableToReroll
  ) internal view returns (string memory) {
    uint256 rerolledAttribute;
    Attributes memory rerolledAttributes = Attributes(
      attributes.accessories,
      attributes.beard,
      attributes.ear,
      attributes.eyes,
      attributes.hat,
      attributes.lips,
      attributes.neck,
      attributes.smoke
    );

    if (slotToReroll == uint256(Slot.accessories)) {
      rerolledAttribute = rerollZunkSlot(
        isFemale,
        serialId,
        Slot.accessories,
        attributes.accessories,
        zunk,
        throwIfUnableToReroll
      );
      if (rerolledAttribute == NO_REROLL_OPTIONS) {
        return NO_OPTIONS;
      }
      rerolledAttributes.accessories = rerolledAttribute;
    } else if (slotToReroll == uint256(Slot.beard)) {
      rerolledAttribute = rerollZunkSlot(
        isFemale,
        serialId,
        Slot.beard,
        attributes.beard,
        zunk,
        throwIfUnableToReroll
      );
      if (rerolledAttribute == NO_REROLL_OPTIONS) {
        return NO_OPTIONS;
      }
      rerolledAttributes.beard = rerolledAttribute;
    } else if (slotToReroll == uint256(Slot.ear)) {
      rerolledAttribute = rerollZunkSlot(
        isFemale,
        serialId,
        Slot.ear,
        attributes.ear,
        zunk,
        throwIfUnableToReroll
      );
      if (rerolledAttribute == NO_REROLL_OPTIONS) {
        return NO_OPTIONS;
      }
      rerolledAttributes.ear = rerolledAttribute;
    } else if (slotToReroll == uint256(Slot.eyes)) {
      rerolledAttribute = rerollZunkSlot(
        isFemale,
        serialId,
        Slot.eyes,
        attributes.eyes,
        zunk,
        throwIfUnableToReroll
      );
      if (rerolledAttribute == NO_REROLL_OPTIONS) {
        return NO_OPTIONS;
      }
      rerolledAttributes.eyes = rerolledAttribute;
    } else if (slotToReroll == uint256(Slot.hat)) {
      rerolledAttribute = rerollZunkSlot(
        isFemale,
        serialId,
        Slot.hat,
        attributes.hat,
        zunk,
        throwIfUnableToReroll
      );
      if (rerolledAttribute == NO_REROLL_OPTIONS) {
        return NO_OPTIONS;
      }
      rerolledAttributes.hat = rerolledAttribute;
    } else if (slotToReroll == uint256(Slot.lips)) {
      rerolledAttribute = rerollZunkSlot(
        isFemale,
        serialId,
        Slot.lips,
        attributes.lips,
        zunk,
        throwIfUnableToReroll
      );
      if (rerolledAttribute == NO_REROLL_OPTIONS) {
        return NO_OPTIONS;
      }
      rerolledAttributes.lips = rerolledAttribute;
    } else if (slotToReroll == uint256(Slot.neck)) {
      rerolledAttribute = rerollZunkSlot(
        isFemale,
        serialId,
        Slot.neck,
        attributes.neck,
        zunk,
        throwIfUnableToReroll
      );
      if (rerolledAttribute == NO_REROLL_OPTIONS) {
        return NO_OPTIONS;
      }
      rerolledAttributes.neck = rerolledAttribute;
    } else {
      rerolledAttribute = rerollZunkSlot(
        isFemale,
        serialId,
        Slot.smoke,
        attributes.smoke,
        zunk,
        throwIfUnableToReroll
      );
      if (rerolledAttribute == NO_REROLL_OPTIONS) {
        return NO_OPTIONS;
      }
      rerolledAttributes.smoke = rerolledAttribute;
    }

    return
      createZunkStringRepresentation(zunkSkin, zunkGender, rerolledAttributes);
  }

  function rerollZunkSlot(
    bool isFemale,
    uint256 serialId,
    Slot slot,
    uint256 attribute,
    string memory zunk,
    bool throwIfUnableToReroll
  ) internal view returns (uint256) {
    uint256 slotAsUint = uint256(slot);
    uint256[] storage attributeProbabilities = getAttributeProbabilities(
      isFemale,
      slotAsUint
    );
    uint256 probabilitiesLength = attributeProbabilities.length;

    string[] memory rerollCandidates = getRerollCandidates(
      slot,
      zunk,
      probabilitiesLength
    );

    uint256[] memory adjustedProbabilities = getAdjustedProbabilities(
      isFemale,
      slot,
      attribute,
      probabilitiesLength,
      rerollCandidates
    );

    bool atLeastOneValidAttribute = false;
    for (uint256 i = 0; i < probabilitiesLength; i++) {
      if (adjustedProbabilities[i] > 0) {
        atLeastOneValidAttribute = true;
        break;
      }
    }

    if (!atLeastOneValidAttribute) {
      if (throwIfUnableToReroll) {
        require(atLeastOneValidAttribute, "Unable to mint. Please try again.");
      } else {
        return NO_REROLL_OPTIONS;
      }
    }

    return
      pickRandomFromMemory(
        adjustedProbabilities,
        serialId,
        uint256(slot),
        attribute
      );
  }

  function getAdjustedProbabilities(
    bool isFemale,
    Slot slot,
    uint256 attribute,
    uint256 probabilitiesLength,
    string[] memory rerollCandidates
  ) internal view returns (uint256[] memory) {
    bool[] memory validAttribute = new bool[](probabilitiesLength);
    uint256 slotAsUint = uint256(slot);
    uint256[] storage attributeProbabilities = getAttributeProbabilities(
      isFemale,
      slotAsUint
    );

    uint256[] memory adjustedProbabilities = new uint256[](probabilitiesLength);
    uint256 invalidProbabilitiesToDistribute = 0;
    for (uint256 i = 0; i < probabilitiesLength; i++) {
      string memory rerollCandidate = rerollCandidates[i];
      // can't give any attribute already off limits, if it makes a zunk/punk, or their current attribute
      if (
        attributeProbabilities[i] == 0 ||
        isInvalidZunk(rerollCandidate) ||
        i == attribute
      ) {
        invalidProbabilitiesToDistribute += attributeProbabilities[i];
      } else {
        validAttribute[i] = true;
      }
    }

    for (uint256 i = 0; i < probabilitiesLength; i++) {
      if (validAttribute[i]) {
        // the math here is to calculate how much of the invalidProbabilitiesToDistribute to
        // give to each validProbability. If we are removing 2000 from the pool and giving
        // 1000 its share, the additional probability for 1000 is 1000/8000 * 2000
        adjustedProbabilities[i] =
          ((attributeProbabilities[i] * invalidProbabilitiesToDistribute) /
            (10000 - invalidProbabilitiesToDistribute)) +
          attributeProbabilities[i];
      } else {
        adjustedProbabilities[i] = 0;
      }
    }
    return adjustedProbabilities;
  }

  function getRerollCandidates(
    Slot slot,
    string memory zunk,
    uint256 probabilitiesLength
  ) internal pure returns (string[] memory) {
    string memory firstHalf = substring(zunk, 0, 4 + uint256(slot) * 2);
    string memory secondHalf = substring(zunk, 6 + uint256(slot) * 2, 20);
    string[] memory candidates = new string[](probabilitiesLength);

    for (uint256 i = 0; i < probabilitiesLength; i++) {
      candidates[i] = string(
        abi.encodePacked(firstHalf, convertToString(i), secondHalf)
      );
    }

    return candidates;
  }

  function getValidSlotsForReroll(Attributes memory attributes)
    internal
    pure
    returns (uint256[] memory)
  {
    bool[] memory validSlots = new bool[](8);
    uint256 numValidSlots = 0;

    if (attributes.accessories != 99) {
      validSlots[uint256(Slot.accessories)] = true;
      numValidSlots++;
    }
    if (attributes.beard != 99) {
      validSlots[uint256(Slot.beard)] = true;
      numValidSlots++;
    }
    if (attributes.eyes != 99) {
      validSlots[uint256(Slot.eyes)] = true;
      numValidSlots++;
    }
    if (attributes.hat != 99) {
      validSlots[uint256(Slot.hat)] = true;
      numValidSlots++;
    }
    if (attributes.lips != 99) {
      validSlots[uint256(Slot.lips)] = true;
      numValidSlots++;
    }
    if (attributes.neck != 99) {
      validSlots[uint256(Slot.neck)] = true;
      numValidSlots++;
    }
    if (attributes.smoke != 99) {
      validSlots[uint256(Slot.smoke)] = true;
      numValidSlots++;
    }

    uint256[] memory valid = new uint256[](numValidSlots);
    uint256 counter = 0;
    for (uint256 i = 0; i < validSlots.length; i++) {
      if (validSlots[i]) {
        valid[counter] = i;
        counter++;
      }
    }
    return valid;
  }

  function generateZunk(uint256 serialId)
    internal
    view
    returns (string memory)
  {
    // these seed numbers are arbitrary, matches prospectiveSlot and mappingLength used elsewhere
    uint256 zunkSkin = pickRandomFromStorage(skinProbabilities, serialId, 0, 7);
    uint256 zunkGender = pickRandomFromStorage(
      genderProbabilities,
      serialId,
      1,
      2
    );

    bool isFemale = isZunkFemale(zunkGender);

    Attributes memory attributes = getAttributes(isFemale, serialId);
    string memory generatedZunk = createZunkStringRepresentation(
      zunkSkin,
      zunkGender,
      attributes
    );

    if (isInvalidZunk(generatedZunk) || unableToRerollZunk(generatedZunk)) {
      uint256[] memory validSlots = getValidSlotsForReroll(attributes);
      uint256 randomSlotIndex = getRandomNumber(
        zunkGender,
        zunkSkin,
        serialId
      ) % validSlots.length;

      generatedZunk = _rerollZunk(
        isFemale,
        serialId,
        zunkSkin,
        zunkGender,
        attributes,
        validSlots[randomSlotIndex],
        generatedZunk,
        false
      );
    }
    return generatedZunk;
  }

  function convertSlotsToString(Attributes memory attributes)
    internal
    pure
    returns (AttributesAsString memory)
  {
    return
      AttributesAsString(
        convertToString(attributes.accessories),
        convertToString(attributes.beard),
        convertToString(attributes.ear),
        convertToString(attributes.eyes),
        convertToString(attributes.hat),
        convertToString(attributes.lips),
        convertToString(attributes.neck),
        convertToString(attributes.smoke)
      );
  }

  function getAttributes(bool isFemale, uint256 serialId)
    internal
    view
    returns (Attributes memory)
  {
    return
      Attributes(
        maybeGetAttribute(isFemale, Slot.accessories, serialId),
        maybeGetAttribute(isFemale, Slot.beard, serialId),
        maybeGetAttribute(isFemale, Slot.ear, serialId),
        maybeGetAttribute(isFemale, Slot.eyes, serialId),
        maybeGetAttribute(isFemale, Slot.hat, serialId),
        maybeGetAttribute(isFemale, Slot.lips, serialId),
        maybeGetAttribute(isFemale, Slot.neck, serialId),
        maybeGetAttribute(isFemale, Slot.smoke, serialId)
      );
  }

  function maybeGetAttribute(
    bool isFemale,
    Slot slot,
    uint256 serialId
  ) internal view returns (uint256) {
    uint256 slotAsUint = uint256(slot);
    uint256[] storage attributeProbabilities = getAttributeProbabilities(
      isFemale,
      slotAsUint
    );
    uint256 length = attributeProbabilities.length;
    bool isSelected = isSlotSelected(
      slot,
      isFemale,
      serialId,
      slotAsUint,
      length
    );

    if (!isSelected) {
      return 99;
    } else {
      uint256 attribute = pickRandomFromStorage(
        attributeProbabilities,
        serialId,
        slotAsUint,
        length
      );
      return attribute;
    }
  }

  // prospective slots are 0-7
  function isSlotSelected(
    Slot prospectiveSlot,
    bool isFemale,
    uint256 seed1,
    uint256 seed2,
    uint256 seed3
  ) internal view returns (bool) {
    uint256 randomNumber = getRandomNumber(seed1, seed2, seed3);
    if (isFemale) {
      return femaleSlotProbabilities[uint256(prospectiveSlot)] >= randomNumber;
    } else {
      return maleSlotProbabilities[uint256(prospectiveSlot)] >= randomNumber;
    }
  }

  function pickRandomFromStorage(
    uint256[] storage attributeProbabilities,
    uint256 seed1,
    uint256 seed2,
    uint256 seed3
  ) internal view returns (uint256) {
    // mix up ordering of seed to generate diff random number from the random number in isSlotSelected
    uint256 randomNumber = getRandomNumber(seed3, seed2, seed1);
    uint256 sum = 0;
    for (uint256 i = 0; i < attributeProbabilities.length; i++) {
      sum += attributeProbabilities[i];
      if (sum >= randomNumber) {
        return i;
      }
    }
    // return the last one
    return attributeProbabilities.length - 1;
  }

  function pickRandomFromMemory(
    uint256[] memory attributeProbabilities,
    uint256 seed1,
    uint256 seed2,
    uint256 seed3
  ) internal view returns (uint256) {
    // mix up ordering of seed to generate diff random number from the random number in isSlotSelected
    uint256 randomNumber = getRandomNumber(seed3, seed2, seed1);
    uint256 sum = 0;
    for (uint256 i = 0; i < attributeProbabilities.length; i++) {
      sum += attributeProbabilities[i];
      if (sum >= randomNumber) {
        return i;
      }
    }
    // return the last one
    return attributeProbabilities.length - 1;
  }

  function getRandomNumber(
    uint256 seed1,
    uint256 seed2,
    uint256 seed3
  ) internal view returns (uint256) {
    uint256 randomNum = uint256(
      keccak256(
        abi.encode(
          msg.sender,
          tx.gasprice,
          block.number,
          block.timestamp,
          blockhash(block.number - 1),
          seed1,
          seed2,
          seed3
        )
      )
    );

    // never return 0, edge cases where first probability of accessory
    // could be 0 while rerolling
    return (randomNum % 10000) + 1;
  }

  function createZunkStringRepresentation(
    uint256 zunkSkin,
    uint256 zunkGender,
    Attributes memory attribues
  ) internal pure returns (string memory) {
    AttributesAsString memory slotsAsString = convertSlotsToString(attribues);
    return
      appendAttributes(
        convertToString(zunkSkin),
        convertToString(zunkGender),
        slotsAsString
      );
  }

  function appendAttributes(
    string memory zunkSkin,
    string memory zunkGender,
    AttributesAsString memory attributes
  ) internal pure returns (string memory) {
    bytes memory firstHalf = abi.encodePacked(
      zunkSkin,
      zunkGender,
      attributes.accessories,
      attributes.beard,
      attributes.ear
    );
    bytes memory secondHalf = abi.encodePacked(
      attributes.eyes,
      attributes.hat,
      attributes.lips,
      attributes.neck,
      attributes.smoke
    );
    return string(abi.encodePacked(firstHalf, secondHalf));
  }

  function isInvalidZunk(string memory zunk) internal view returns (bool) {
    return unavailableZunks[zunk] || existingZunks[zunk];
  }

  function getAttributeProbabilities(bool isFemale, uint256 slotAsUint)
    internal
    view
    returns (uint256[] storage)
  {
    uint256[] storage attributeProbabilities = femaleProbabilities[slotAsUint];
    if (!isFemale) {
      attributeProbabilities = maleProbabilities[slotAsUint];
    }
    return attributeProbabilities;
  }

  function convertToString(uint256 num) internal pure returns (string memory) {
    if (num == 0) {
      return "00";
    } else if (num == 1) {
      return "01";
    } else if (num == 2) {
      return "02";
    } else if (num == 3) {
      return "03";
    } else if (num == 4) {
      return "04";
    } else if (num == 5) {
      return "05";
    } else if (num == 6) {
      return "06";
    } else if (num == 7) {
      return "07";
    } else if (num == 8) {
      return "08";
    } else if (num == 9) {
      return "09";
    }

    return Strings.toString(num);
  }

  function substring(
    string memory str,
    uint256 startIndex,
    uint256 endIndex
  ) internal pure returns (string memory) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIndex - startIndex);
    for (uint256 i = startIndex; i < endIndex; i++) {
      result[i - startIndex] = strBytes[i];
    }
    return string(result);
  }

  // s will always be len 2
  function convertToUint(string memory s) internal pure returns (uint256) {
    string memory tensDigit = substring(s, 0, 1);
    string memory onesDigit = substring(s, 1, 2);
    return stringToUint(tensDigit) * 10 + stringToUint(onesDigit);
  }

  function stringToUint(string memory s) internal pure returns (uint256) {
    //bytes32 sHash = keccak256(abi.encodePacked(s));
    if (compareStrings(s, "0")) {
      return 0;
    } else if (compareStrings(s, "1")) {
      return 1;
    } else if (compareStrings(s, "2")) {
      return 2;
    } else if (compareStrings(s, "3")) {
      return 3;
    } else if (compareStrings(s, "4")) {
      return 4;
    } else if (compareStrings(s, "5")) {
      return 5;
    } else if (compareStrings(s, "6")) {
      return 6;
    } else if (compareStrings(s, "7")) {
      return 7;
    } else if (compareStrings(s, "8")) {
      return 8;
    } else {
      return 9;
    }
  }

  function unableToRerollZunk(string memory zunk) internal view returns (bool) {
    return compareStrings(zunk, NO_OPTIONS);
  }

  function compareStrings(string memory s1, string memory s2)
    internal
    pure
    returns (bool)
  {
    return keccak256(bytes(s1)) == keccak256(bytes(s2));
  }

  function isZunkFemale(uint256 zunkGender) internal pure returns (bool) {
    return zunkGender == 0;
  }

  function getOwnerZunks(address _owner)
    external
    view
    returns (SerialIdAndTokenRepresentation[] memory)
  {
    uint256 numSerialIds = balanceOf(_owner);
    if (numSerialIds == 0) {
      return new SerialIdAndTokenRepresentation[](0);
    } else {
      SerialIdAndTokenRepresentation[]
        memory result = new SerialIdAndTokenRepresentation[](numSerialIds);
      for (uint256 i = 0; i < numSerialIds; i++) {
        uint256 serialId = tokenOfOwnerByIndex(_owner, i);
        string memory zunk = serialIdToZunk[serialId];
        result[i] = SerialIdAndTokenRepresentation(serialId, zunk);
      }
      return result;
    }
  }

  function getSerialIdTokenRepresentations(uint256[] memory serialIds)
    external
    view
    returns (string[] memory)
  {
    string[] memory tokenRepresentations = new string[](serialIds.length);
    for (uint256 i = 0; i < serialIds.length; i++) {
      tokenRepresentations[i] = serialIdToZunk[serialIds[i]];
    }
    return tokenRepresentations;
  }

  // This does not factor free mints into account
  function getCostForMints(uint256 _numToMint) public pure returns (uint256) {
    uint256 _cost;
    uint256 _index;
    for (_index; _index < _numToMint; _index++) {
      _cost += 0.05 ether;
    }
    return _cost;
  }

  function getCostForRerollAttribute() public pure returns (uint256) {
    return 0.02 ether;
  }

  function hasFreeMintsInPoolRemaining() internal view returns (bool) {
    return 200 - freeMintsFromPoolRedeemed > 0;
  }

  function userHasFreeMint(address userAddress) public view returns (bool) {
    if (freeMintsAllocatedByDevs[userAddress] > 0) {
      return true;
    }
    if (
      !hasRedeemedFreeMintFromPool[userAddress] && hasFreeMintsInPoolRemaining()
    ) {
      // Free mints from pool are only accessible for those who have never free minted from the pool before.
      return true;
    }
    return false;
  }

  function enableMintAndReroll() public onlyOwner {
    isMintAndRerollEnabled = true;
  }

  function disableMintAndReroll() public onlyOwner {
    isMintAndRerollEnabled = false;
  }

  function devSingleMint() public onlyOwner {
    require(!hasDevSingleMinted, "Can only dev single mint once");
    _mintNoChecks(1);
    hasDevSingleMinted = true;
  }

  function seedPunks(string[] memory punks) public onlyOwner {
    for (uint256 i = 0; i < punks.length; i++) {
      unavailableZunks[punks[i]] = true;
    }
  }

  function addFreeMintsAllocatedByDevs(
    address[] memory addresses,
    uint256[] memory numOfFreeMints
  ) public onlyOwner {
    require(
      addresses.length == numOfFreeMints.length,
      "tokenOwners does not match numOfFreeRolls length"
    );
    uint256 freeMintsFromThisSeed = 0;
    for (uint256 i = 0; i < addresses.length; i++) {
      freeMintsAllocatedByDevs[addresses[i]] =
        freeMintsAllocatedByDevs[addresses[i]] +
        numOfFreeMints[i];
      freeMintsFromThisSeed += numOfFreeMints[i];
    }
    require(
      freeMintsFromThisSeed < freeMintsAllocatedByDevsCap,
      "too many freemints allocated by devs"
    );
  }

  // // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function tokenURI(uint256 _serialId)
    public
    view
    override
    returns (string memory)
  {
    string memory base = _baseURI();
    string memory _tokenURI = Strings.toString(_serialId);

    // If there is no base URI, return the token URI.
    if (bytes(base).length == 0) {
      return _tokenURI;
    }

    return string(abi.encodePacked(base, _tokenURI));
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdrawMoney() public payable onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 serialId
  ) internal virtual override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, serialId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}