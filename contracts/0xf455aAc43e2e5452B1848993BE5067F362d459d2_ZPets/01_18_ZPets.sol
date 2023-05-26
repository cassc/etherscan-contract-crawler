//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

import "hardhat/console.sol";

abstract contract Zunks {
  function ownerOf(uint256 tokenId) public view virtual returns (address);
}

contract ZPets is Ownable, ERC721Enumerable, ERC721Burnable, ReentrancyGuard {
  using Strings for uint256;
  Zunks private zunks;

  enum Slot {
    eyes,
    hat,
    leftEar,
    neck,
    rightEar,
    smoke
  }

  mapping(uint256 => string) public serialIdToPet;
  mapping(string => bool) public existingPets;
  mapping(uint256 => uint256) public serialIdToTimeRedeemed;

  mapping(uint256 => uint256[]) public probabilities;

  string NO_OPTIONS = "no options";
  uint256 NO_REROLL_OPTIONS = 99999;
  string UNICORN = "0206999999999999";
  string ALIEN_ROCK = "0005999999999999";
  string NORMAL_ROCK = "0205999999999999";
  string ZOMBIE_ROCK = "0605999999999999";
  uint256 ONE_DAY = 86400;

  // placeholder values
  uint256[6] petSlotProbabilities = [8000, 6000, 5000, 5000, 5000, 5000];

  // cat, cow, dog, giraffe, pig, rock, unicorn
  uint256[] typeProbabilities = [3006, 1564, 3006, 800, 1564, 50, 10];
  uint256[][] skinProbabilities = [
    [16, 54, 2445, 2445, 2445, 2445, 150],
    [16, 0, 9834, 0, 0, 0, 150],
    [16, 54, 2445, 2445, 2445, 2445, 150],
    [37, 0, 9526, 0, 0, 0, 437],
    [16, 0, 9834, 0, 0, 0, 150],
    [600, 0, 7400, 0, 0, 0, 2000]
  ];

  struct Attributes {
    uint256 eyes;
    uint256 hat;
    uint256 leftEar;
    uint256 neck;
    uint256 rightEar;
    uint256 smoke;
  }

  struct AttributesAsString {
    string eyes;
    string hat;
    string leftEar;
    string neck;
    string rightEar;
    string smoke;
  }

  struct SerialIdAndTokenRepresentation {
    uint256 serialId;
    string tokenRepresentation;
  }

  struct ZPetExists {
    uint256 serialId;
    bool exists;
  }

  struct ZPetData {
    uint256 serialId;
    bool canReroll;
  }

  constructor(address zunksAddress) ERC721("ZPets", "ZPET") {
    zunks = Zunks(zunksAddress);
    probabilities[uint256(Slot.eyes)] = [
      455,
      853,
      842,
      610,
      612,
      608,
      467,
      734,
      605,
      853,
      695,
      605,
      840,
      518,
      432,
      272
    ];
    probabilities[uint256(Slot.hat)] = [
      400,
      59,
      299,
      263,
      275,
      343,
      116,
      190,
      324,
      320,
      405,
      251,
      345,
      299,
      548,
      448,
      382,
      467,
      457,
      183,
      139,
      409,
      192,
      110,
      193,
      274,
      222,
      348,
      405,
      385,
      190,
      112,
      155,
      199,
      293
    ];
    probabilities[uint256(Slot.leftEar)] = [2500, 2500, 2500, 2500];
    probabilities[uint256(Slot.neck)] = [2600, 2600, 4800];
    probabilities[uint256(Slot.rightEar)] = [2500, 2500, 2500, 2500];
    probabilities[uint256(Slot.smoke)] = [1191, 4908, 893, 1619, 1389];
  }

  bool public hasDevSingleMinted = false;
  bool public isMintEnabled = false;
  bool public isRerollEnabled = false;
  bool public isRerollAllEnabled = false;

  uint256 private MAX_SUPPLY = 10000;

  event ZPet(
    address indexed user,
    uint256 serialId,
    string tokenRepresentation,
    bool isReroll
  );

  function mint(uint256[] calldata _serialIds) external payable nonReentrant {
    require(isMintEnabled, "Minting is not enabled.");
    uint256 _numMinted = totalSupply();
    require(
      _numMinted + _serialIds.length <= MAX_SUPPLY,
      "There aren't this many pets left."
    );

    _mint(_serialIds);
  }

  function _mint(uint256[] memory _serialIds) internal {
    for (uint256 i = 0; i < _serialIds.length; i++) {
      uint256 serialId = _serialIds[i];
      require(
        zunks.ownerOf(serialId) == msg.sender,
        "User does not own the corresponding zunk"
      );
      _safeMint(msg.sender, serialId);

      string memory generatedPet = generatePet(serialId);

      // we need to guarantee unique if not unicorn or rock
      if (!isNonUniquePet(generatedPet)) {
        if (existingPets[generatedPet] || unableToRerollPet(generatedPet)) {
          generatedPet = generatePet(serialId);
        }
        require(
          !(existingPets[generatedPet] || unableToRerollPet(generatedPet)) ||
            isNonUniquePet(generatedPet),
          "Unable to mint, please try again."
        );
      }

      serialIdToPet[serialId] = generatedPet;
      existingPets[generatedPet] = true;
      serialIdToTimeRedeemed[serialId] = block.timestamp;
      emit ZPet(msg.sender, serialId, generatedPet, false);
    }
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

    require(slotToRerollValid, "slotToReroll is not valid for pet");
  }

  function canRerollPet(uint256[] memory serialIds)
    public
    view
    returns (ZPetData[] memory)
  {
    ZPetData[] memory data = new ZPetData[](serialIds.length);
    uint256 curr = block.timestamp;
    for (uint256 i = 0; i < serialIds.length; i++) {
      uint256 serialId = serialIds[i];
      if (serialIdToTimeRedeemed[serialId] - curr <= ONE_DAY) {
        data[i] = ZPetData(serialId, true);
      } else {
        data[i] = ZPetData(serialId, false);
      }
    }
    return data;
  }

  // this rerolls all the slots of a pet besides skin/type
  function rerollPet(uint256 serialId) public {
    require(isRerollAllEnabled, "Reroll is not enabled");
    require(msg.sender == ownerOf(serialId), "Only owner can reroll.");
    require(
      block.timestamp - serialIdToTimeRedeemed[serialId] <= ONE_DAY,
      "Can not reroll after one day"
    );

    string memory pet = serialIdToPet[serialId];
    string memory petSkinAsString = substring(pet, 0, 2);
    string memory petTypeAsString = substring(pet, 2, 4);
    uint256 petSkin = convertToUint(petSkinAsString);
    uint256 petType = convertToUint(petTypeAsString);

    Attributes memory attributes = generateAttributes(serialId);
    string memory rerolledPet = createPetStringRepresentation(
      petSkin,
      petType,
      attributes
    );

    if (existingPets[rerolledPet]) {
      uint256[] memory validSlots = getValidSlotsForReroll(attributes);
      uint256 randomSlotIndex = getRandomNumber(petType, petSkin, serialId) %
        validSlots.length;
      rerolledPet = _rerollPet(
        serialId,
        petSkin,
        petType,
        attributes,
        validSlots[randomSlotIndex],
        rerolledPet,
        false
      );
    }
    require(
      !existingPets[rerolledPet],
      "Could not reroll into a valid pet, please try again."
    );
    serialIdToPet[serialId] = rerolledPet;
    existingPets[rerolledPet] = true;
    existingPets[pet] = false;
    emit ZPet(msg.sender, serialId, rerolledPet, true);
  }

  function rerollPetSlot(uint256 serialId, uint256 slotToReroll)
    public
    payable
  {
    require(isRerollEnabled, "Reroll is not enabled");
    require(msg.sender == ownerOf(serialId), "Only owner can reroll.");
    uint256 costForReroll = getCostForRerollAttribute();
    require(msg.value >= costForReroll, "Need to send more ETH for reroll.");
    if (msg.value > costForReroll) {
      payable(msg.sender).transfer(msg.value - costForReroll);
    }

    string memory pet = serialIdToPet[serialId];
    string memory petSkinAsString = substring(pet, 0, 2);
    string memory petTypeAsString = substring(pet, 2, 4);
    Attributes memory attributes = createAttributesFromPet(pet);

    validateSlotToRerollValid(slotToReroll, attributes);

    uint256 petSkin = convertToUint(petSkinAsString);
    uint256 petType = convertToUint(petTypeAsString);

    string memory rerolledPet = _rerollPet(
      serialId,
      petSkin,
      petType,
      attributes,
      slotToReroll,
      pet
    );

    require(
      !existingPets[rerolledPet],
      "Could not reroll into a valid pet, please try again."
    );

    serialIdToPet[serialId] = rerolledPet;
    existingPets[rerolledPet] = true;
    existingPets[pet] = false;
    emit ZPet(msg.sender, serialId, rerolledPet, true);
  }

  function createAttributesFromPet(string memory pet)
    internal
    pure
    returns (Attributes memory)
  {
    string memory attributes1 = substring(pet, 4, 6);
    string memory attributes2 = substring(pet, 6, 8);
    string memory attributes3 = substring(pet, 8, 10);
    string memory attributes4 = substring(pet, 10, 12);
    string memory attributes5 = substring(pet, 12, 14);
    string memory attributes6 = substring(pet, 14, 16);
    return
      Attributes(
        convertToUint(attributes1),
        convertToUint(attributes2),
        convertToUint(attributes3),
        convertToUint(attributes4),
        convertToUint(attributes5),
        convertToUint(attributes6)
      );
  }

  function _rerollPet(
    uint256 serialId,
    uint256 petSkin,
    uint256 petType,
    Attributes memory attributes,
    uint256 slotToReroll,
    string memory pet
  ) internal view returns (string memory) {
    return
      _rerollPet(
        serialId,
        petSkin,
        petType,
        attributes,
        slotToReroll,
        pet,
        true
      );
  }

  function _rerollPet(
    uint256 serialId,
    uint256 petSkin,
    uint256 petType,
    Attributes memory attributes,
    uint256 slotToReroll,
    string memory pet,
    bool throwIfUnableToReroll
  ) internal view returns (string memory) {
    uint256 rerolledAttribute;
    Attributes memory rerolledAttributes = Attributes(
      attributes.eyes,
      attributes.hat,
      attributes.leftEar,
      attributes.neck,
      attributes.rightEar,
      attributes.smoke
    );

    if (slotToReroll == uint256(Slot.eyes)) {
      rerolledAttribute = rerollPetSlot(
        serialId,
        Slot.eyes,
        attributes.eyes,
        pet,
        throwIfUnableToReroll
      );
      if (rerolledAttribute == NO_REROLL_OPTIONS) {
        return NO_OPTIONS;
      }
      rerolledAttributes.eyes = rerolledAttribute;
    } else if (slotToReroll == uint256(Slot.hat)) {
      rerolledAttribute = rerollPetSlot(
        serialId,
        Slot.hat,
        attributes.hat,
        pet,
        throwIfUnableToReroll
      );
      if (rerolledAttribute == NO_REROLL_OPTIONS) {
        return NO_OPTIONS;
      }
      rerolledAttributes.hat = rerolledAttribute;
    } else if (slotToReroll == uint256(Slot.leftEar)) {
      rerolledAttribute = rerollPetSlot(
        serialId,
        Slot.leftEar,
        attributes.leftEar,
        pet,
        throwIfUnableToReroll
      );
      if (rerolledAttribute == NO_REROLL_OPTIONS) {
        return NO_OPTIONS;
      }
      rerolledAttributes.leftEar = rerolledAttribute;
    } else if (slotToReroll == uint256(Slot.neck)) {
      rerolledAttribute = rerollPetSlot(
        serialId,
        Slot.neck,
        attributes.neck,
        pet,
        throwIfUnableToReroll
      );
      if (rerolledAttribute == NO_REROLL_OPTIONS) {
        return NO_OPTIONS;
      }
      rerolledAttributes.neck = rerolledAttribute;
    } else if (slotToReroll == uint256(Slot.rightEar)) {
      rerolledAttribute = rerollPetSlot(
        serialId,
        Slot.rightEar,
        attributes.rightEar,
        pet,
        throwIfUnableToReroll
      );
      if (rerolledAttribute == NO_REROLL_OPTIONS) {
        return NO_OPTIONS;
      }
      rerolledAttributes.rightEar = rerolledAttribute;
    } else {
      rerolledAttribute = rerollPetSlot(
        serialId,
        Slot.smoke,
        attributes.smoke,
        pet,
        throwIfUnableToReroll
      );
      if (rerolledAttribute == NO_REROLL_OPTIONS) {
        return NO_OPTIONS;
      }
      rerolledAttributes.smoke = rerolledAttribute;
    }

    return createPetStringRepresentation(petSkin, petType, rerolledAttributes);
  }

  function rerollPetSlot(
    uint256 serialId,
    Slot slot,
    uint256 attribute,
    string memory pet,
    bool throwIfUnableToReroll
  ) internal view returns (uint256) {
    uint256 slotAsUint = uint256(slot);
    uint256[] storage attributeProbabilities = probabilities[slotAsUint];
    uint256 probabilitiesLength = attributeProbabilities.length;

    string[] memory rerollCandidates = getRerollCandidates(
      slot,
      pet,
      probabilitiesLength
    );

    uint256[] memory adjustedProbabilities = getAdjustedProbabilities(
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
    Slot slot,
    uint256 attribute,
    uint256 probabilitiesLength,
    string[] memory rerollCandidates
  ) internal view returns (uint256[] memory) {
    bool[] memory validAttribute = new bool[](probabilitiesLength);
    uint256 slotAsUint = uint256(slot);
    uint256[] storage attributeProbabilities = probabilities[slotAsUint];

    uint256[] memory adjustedProbabilities = new uint256[](probabilitiesLength);
    uint256 invalidProbabilitiesToDistribute = 0;
    for (uint256 i = 0; i < probabilitiesLength; i++) {
      string memory rerollCandidate = rerollCandidates[i];
      // can't give any attribute already off limits, if it makes a pet, or their current attribute
      if (
        attributeProbabilities[i] == 0 ||
        existingPets[rerollCandidate] ||
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
    string memory pet,
    uint256 probabilitiesLength
  ) internal pure returns (string[] memory) {
    string memory firstHalf = substring(pet, 0, 4 + uint256(slot) * 2);
    string memory secondHalf = substring(pet, 6 + uint256(slot) * 2, 16);
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
    bool[] memory validSlots = new bool[](6);
    uint256 numValidSlots = 0;

    if (attributes.eyes != 99) {
      validSlots[uint256(Slot.eyes)] = true;
      numValidSlots++;
    }
    if (attributes.hat != 99) {
      validSlots[uint256(Slot.hat)] = true;
      numValidSlots++;
    }
    if (attributes.leftEar != 99) {
      validSlots[uint256(Slot.leftEar)] = true;
      numValidSlots++;
    }
    if (attributes.neck != 99) {
      validSlots[uint256(Slot.neck)] = true;
      numValidSlots++;
    }
    if (attributes.rightEar != 99) {
      validSlots[uint256(Slot.rightEar)] = true;
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

  function generatePet(uint256 serialId) internal view returns (string memory) {
    // these seed numbers are arbitrary, matches prospectiveSlot and mappingLength used elsewhere
    uint256 petType = pickRandomFromStorage(typeProbabilities, serialId, 1, 5);

    if (petType == 6) {
      return UNICORN;
    }

    uint256 petSkin = pickRandomFromStorage(
      skinProbabilities[petType],
      serialId,
      0,
      7
    );

    if (petType == 5) {
      if (petSkin == 0) {
        return ALIEN_ROCK;
      } else if (petSkin == 2) {
        return NORMAL_ROCK;
      } else if (petSkin == 6) {
        return ZOMBIE_ROCK;
      } else {
        require(
          petSkin == 0 || petSkin == 2 || petSkin == 6,
          "Invalid pet skin for rock"
        );
      }
    }

    Attributes memory attributes = generateAttributes(serialId);
    string memory generatedPet = createPetStringRepresentation(
      petSkin,
      petType,
      attributes
    );

    if (existingPets[generatedPet]) {
      uint256[] memory validSlots = getValidSlotsForReroll(attributes);
      uint256 randomSlotIndex = getRandomNumber(petType, petSkin, serialId) %
        validSlots.length;

      generatedPet = _rerollPet(
        serialId,
        petSkin,
        petType,
        attributes,
        validSlots[randomSlotIndex],
        generatedPet,
        false
      );
    }
    return generatedPet;
  }

  function convertSlotsToString(Attributes memory attributes)
    internal
    pure
    returns (AttributesAsString memory)
  {
    return
      AttributesAsString(
        convertToString(attributes.eyes),
        convertToString(attributes.hat),
        convertToString(attributes.leftEar),
        convertToString(attributes.neck),
        convertToString(attributes.rightEar),
        convertToString(attributes.smoke)
      );
  }

  function generateAttributes(uint256 serialId)
    internal
    view
    returns (Attributes memory)
  {
    return
      Attributes(
        maybeGetAttribute(Slot.eyes, serialId),
        maybeGetAttribute(Slot.hat, serialId),
        maybeGetAttribute(Slot.leftEar, serialId),
        maybeGetAttribute(Slot.neck, serialId),
        maybeGetAttribute(Slot.rightEar, serialId),
        maybeGetAttribute(Slot.smoke, serialId)
      );
  }

  function maybeGetAttribute(Slot slot, uint256 serialId)
    internal
    view
    returns (uint256)
  {
    uint256 slotAsUint = uint256(slot);
    uint256[] storage attributeProbabilities = probabilities[slotAsUint];
    uint256 length = attributeProbabilities.length;
    bool isSelected = isSlotSelected(slot, serialId, slotAsUint, length);

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

  // prospective slots are 0-4
  function isSlotSelected(
    Slot prospectiveSlot,
    uint256 seed1,
    uint256 seed2,
    uint256 seed3
  ) internal view returns (bool) {
    uint256 randomNumber = getRandomNumber(seed1, seed2, seed3);
    return petSlotProbabilities[uint256(prospectiveSlot)] >= randomNumber;
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

  function createPetStringRepresentation(
    uint256 petSkin,
    uint256 petType,
    Attributes memory attributes
  ) internal pure returns (string memory) {
    AttributesAsString memory slotsAsString = convertSlotsToString(attributes);
    return
      appendAttributes(
        convertToString(petSkin),
        convertToString(petType),
        slotsAsString
      );
  }

  function appendAttributes(
    string memory petSkin,
    string memory petType,
    AttributesAsString memory attributes
  ) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          petSkin,
          petType,
          attributes.eyes,
          attributes.hat,
          attributes.leftEar,
          attributes.neck,
          attributes.rightEar,
          attributes.smoke
        )
      );
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

  function isNonUniquePet(string memory generatedPet)
    internal
    view
    returns (bool)
  {
    return
      compareStrings(generatedPet, UNICORN) ||
      compareStrings(generatedPet, ALIEN_ROCK) ||
      compareStrings(generatedPet, NORMAL_ROCK) ||
      compareStrings(generatedPet, ZOMBIE_ROCK);
  }

  function unableToRerollPet(string memory pet) internal view returns (bool) {
    return compareStrings(pet, NO_OPTIONS);
  }

  function compareStrings(string memory s1, string memory s2)
    internal
    pure
    returns (bool)
  {
    return keccak256(bytes(s1)) == keccak256(bytes(s2));
  }

  function getOwnerPets(address _owner)
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
        string memory pet = serialIdToPet[serialId];
        result[i] = SerialIdAndTokenRepresentation(serialId, pet);
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
      tokenRepresentations[i] = serialIdToPet[serialIds[i]];
    }
    return tokenRepresentations;
  }

  function getCostForRerollAttribute() public pure returns (uint256) {
    return 0.02 ether;
  }

  function startSale() public onlyOwner {
    isMintEnabled = true;
    isRerollAllEnabled = true;
  }

  function disableMint() public onlyOwner {
    isMintEnabled = false;
  }

  function disableRerollAll() public onlyOwner {
    isRerollAllEnabled = false;
  }

  function enableReroll() public onlyOwner {
    isRerollEnabled = true;
  }

  function disableReroll() public onlyOwner {
    isRerollEnabled = false;
  }

  // will be used for fun stuff in the future, stay tuned!
  function editProbabilities(
    uint256 slot,
    uint256[] memory updatedProbabilities
  ) public onlyOwner {
    probabilities[slot] = updatedProbabilities;
  }

  // Devs own zunk #10000, mint pet #10000 so we can set up OS
  function devSingleMint(uint256[] memory serialIds) public onlyOwner {
    require(!hasDevSingleMinted, "Can only dev single mint once");
    require(serialIds.length == 1, "Can only mint one pet");
    _mint(serialIds);
    hasDevSingleMinted = true;
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