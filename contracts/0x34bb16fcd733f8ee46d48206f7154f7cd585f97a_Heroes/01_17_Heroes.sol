// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Traits.sol";
import "./Traits2.sol";

contract Heroes is ERC721Enumerable, Ownable, ReentrancyGuard {
  using ECDSA for bytes32;

  uint256 PRICE_PER_TOKEN = 0.08 ether;
  uint256 MAX_SUPPLY = 3333;
  address SIGNER;
  uint256 currentId;
  string BASE_URI;

  mapping(uint256 => uint256) public tokenIdToSeed;

  HeroTraits traitStorage;
  HeroTraits2 traitStorage2;

  constructor(
    string memory baseUri,
    string memory name,
    address traits,
    address traits2
  ) ERC721(name, "HERO") {
    BASE_URI = baseUri;
    traitStorage = HeroTraits(traits);
    traitStorage2 = HeroTraits2(traits2);
  }

  function withdraw(address sendTo) public onlyOwner {
    uint256 balance = address(this).balance;
    payable(sendTo).transfer(balance);
  }

  struct Traits {
    uint256 race;
    uint256 pants;
    uint256 weapon;
    uint256 shield;
    uint256 clothes;
    uint256 head;
    uint256 shoes;
    uint256 hair;
    uint256 bg;
    uint256 magic;
    uint256 strength;
    uint256 intelligence;
    uint256 stamina;
    uint256 dexterity;
    uint256 creativity;
  }

  function getSeed(uint256 tokenId) public view returns (uint256) {
    return tokenIdToSeed[tokenId];
  }

  // get trait modulo 10 and then have a percentage
  function _getRandomMod(uint256 rand, uint256 chance)
    internal
    pure
    returns (bool)
  {
    return ((rand % 1000) + 1) <= chance;
  }

  function genTraits(uint256 tokenId) public view returns (Traits memory) {
    uint256 seed = getSeed(tokenId);

    Traits memory traits = Traits({
      race: uint256(keccak256(abi.encode(seed, 1))),
      pants: uint256(keccak256(abi.encode(seed, 2))),
      weapon: uint256(keccak256(abi.encode(seed, 3))),
      shield: uint256(keccak256(abi.encode(seed, 4))),
      clothes: uint256(keccak256(abi.encode(seed, 5))),
      head: uint256(keccak256(abi.encode(seed, 6))),
      shoes: uint256(keccak256(abi.encode(seed, 7))),
      hair: uint256(keccak256(abi.encode(seed, 8))),
      bg: uint256(keccak256(abi.encode(seed, 9))),
      magic: uint256(keccak256(abi.encode(seed, 10))),
      strength: uint256(keccak256(abi.encode(seed, 11))),
      intelligence: uint256(keccak256(abi.encode(seed, 12))),
      stamina: uint256(keccak256(abi.encode(seed, 13))),
      dexterity: uint256(keccak256(abi.encode(seed, 14))),
      creativity: uint256(keccak256(abi.encode(seed, 15)))
    });

    uint256 head = _getRandomMod(traits.head, 500)
      ? traits.head % traitStorage.getHeadLength()
      : 0;

    bool isHood = head >= 1 && head <= 5;

    // default is human1
    uint256 race = 0;
    bool isHuman1 = _getRandomMod(traits.race, 500);
    bool isHuman2 = _getRandomMod(traits.race, 340);
    bool isHuman3 = _getRandomMod(traits.race, 180);
    bool isZombie = _getRandomMod(traits.race, 600);
    bool isSkeleton = _getRandomMod(traits.race, 700);
    bool isWizard = _getRandomMod(traits.race, 800);
    bool isGhost = _getRandomMod(traits.race, 900);
    bool isFrog = _getRandomMod(traits.race, 960);
    bool isPizza = _getRandomMod(traits.race, 970);

    if (isHuman3) {
      race = 2;
    } else if (isHuman2) {
      race = 1;
    } else if (isHuman1) {
      race = 0;
    } else if (isZombie) {
      race = 3;
    } else if (isSkeleton) {
      race = 4;
    } else if (isWizard) {
      race = 5;
    } else if (isGhost) {
      race = 6;
    } else if (isFrog) {
      race = 7;
    } else if (isPizza) {
      race = 8;
      // monkies
    } else if (_getRandomMod(traits.race, 972)) {
      race = 9;
    } else if (_getRandomMod(traits.race, 974)) {
      race = 10;
    } else if (_getRandomMod(traits.race, 976)) {
      race = 11;
    } else if (_getRandomMod(traits.race, 978)) {
      race = 12;
    } else if (_getRandomMod(traits.race, 980)) {
      race = 13;
    } else if (_getRandomMod(traits.race, 982)) {
      race = 14;
    } else if (_getRandomMod(traits.race, 984)) {
      race = 15;
    } else if (_getRandomMod(traits.race, 986)) {
      race = 16;
    } else if (_getRandomMod(traits.race, 988)) {
      race = 17;
    } else if (_getRandomMod(traits.race, 990)) {
      race = 18;
    } else if (_getRandomMod(traits.race, 993)) {
      race = 19;
    } else if (_getRandomMod(traits.race, 997)) {
      race = 20;
    } else if (_getRandomMod(traits.race, 1000)) {
      race = 21;
    }

    return
      Traits({
        race: race,
        weapon: _getRandomMod(traits.weapon, 800)
          ? traits.weapon % traitStorage.getWeaponsLength()
          : 0,
        clothes: traits.clothes % traitStorage.getClothesLength(),
        shield: _getRandomMod(traits.shield, 100)
          ? traits.shield % traitStorage.getShieldsLength()
          : 0,
        head: head,
        pants: traits.pants % traitStorage.getPantsLength(),
        bg: traits.bg % traitStorage.getBgLength(),
        hair: isHood ? 0 : _getRandomMod(traits.weapon, 950)
          ? traits.hair % traitStorage2.getHairLength()
          : 0,
        shoes: traits.shoes % traitStorage.getShoesLength(),
        magic: (traits.magic % 1000) + 1,
        strength: (traits.strength % 1000) + 1,
        intelligence: (traits.intelligence % 1000) + 1,
        stamina: (traits.stamina % 1000) + 1,
        dexterity: (traits.dexterity % 1000) + 1,
        creativity: (traits.creativity % 1000) + 1
      });
  }

  function genSvg(uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId), "Token ID does not exist");

    Traits memory traits = genTraits(tokenId);

    string[9] memory parts;

    // bg
    // shadow
    // base
    // shoes
    // pants
    // clothes
    // hair
    // hats
    // shield
    // weapons

    // bg, shadow
    parts[0] = string(
      abi.encodePacked(
        '<rect width="100%" height="100%" fill="',
        traitStorage.getBg()[traits.bg],
        '" />',
        '<image width="100%" height="100%" href="',
        _baseURI(),
        traitStorage.getShadow(),
        '" />'
      )
    );

    // race
    parts[1] = string(
      abi.encodePacked(
        '<g transform=""><image width="100%" height="100%" href="',
        _baseURI(),
        traitStorage.getRace()[traits.race][1],
        '" />'
      )
    );

    // shoes
    parts[2] = traits.shoes == 0
      ? ""
      : string(
        abi.encodePacked(
          '<image width="100%" height="100%" href="',
          _baseURI(),
          traitStorage.getShoes()[traits.shoes][1],
          '" />'
        )
      );

    // pants
    parts[3] = string(
      abi.encodePacked(
        '<image width="100%" height="100%" href="',
        _baseURI(),
        traitStorage.getPants()[traits.pants][1],
        '" />'
      )
    );

    // clothes
    parts[4] = traits.clothes == 0
      ? ""
      : string(
        abi.encodePacked(
          '<image width="100%" height="100%" href="',
          _baseURI(),
          traitStorage.getClothes()[traits.clothes][1],
          '" />'
        )
      );

    parts[5] = traits.hair == 0
      ? ""
      : string(
        abi.encodePacked(
          '<image width="100%" height="100%" href="',
          _baseURI(),
          traitStorage2.getHair()[traits.hair][1],
          '" />'
        )
      );

    // hats
    parts[6] = traits.head == 0
      ? ""
      : string(
        abi.encodePacked(
          '<image width="100%" height="100%" href="',
          _baseURI(),
          traitStorage.getHead()[traits.head][1],
          '" />'
        )
      );

    // shield
    parts[7] = traits.shield == 0
      ? ""
      : string(
        abi.encodePacked(
          '<image width="100%" height="100%" href="',
          _baseURI(),
          traitStorage.getShields()[traits.shield][1],
          '" />'
        )
      );

    // weapon
    parts[8] = traits.weapon == 0
      ? ""
      : string(
        abi.encodePacked(
          '<image width="100%" height="100%" href="',
          _baseURI(),
          traitStorage.getWeapons()[traits.weapon][1],
          '" />'
        )
      );

    string memory svg = string(
      abi.encodePacked(
        '<svg version="1.1" viewBox="0 0 800 800" width="800" height="800" xmlns="http://www.w3.org/2000/svg">',
        parts[0],
        parts[1],
        parts[2],
        parts[3],
        parts[4],
        parts[5],
        parts[6],
        parts[7],
        parts[8],
        "</g></svg>"
      )
    );

    return svg;
  }

  function getSeedPart(uint256 tokenId, uint256 num)
    public
    view
    returns (uint16)
  {
    return uint16(getSeed(tokenId) >> num);
  }

  function setBaseUri(string memory baseUri) public onlyOwner {
    BASE_URI = baseUri;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return BASE_URI;
  }

  string DESCRIPTION;

  function updateDescription(string memory d) public onlyOwner {
    DESCRIPTION = d;
  }

  function uintToStr(uint256 _i)
    internal
    pure
    returns (string memory _uintAsString)
  {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

  function updateSigner(address signer) public onlyOwner {
    SIGNER = signer;
  }

  function _genOptionalTraits(Traits memory traits)
    internal
    view
    returns (string memory)
  {
    // 0 weapon
    // 1 shield
    // 2 head
    // 3 hair
    // 4 clothes
    // 5 shoes
    string[6] memory parts;

    if (traits.weapon != 0) {
      parts[0] = string(
        abi.encodePacked(
          ',{"trait_type":"Weapon","value":"',
          traitStorage.getWeapons()[traits.weapon][0],
          '"}'
        )
      );
    }

    if (traits.shield != 0) {
      parts[1] = string(
        abi.encodePacked(
          ',{"trait_type":"Shield","value":"',
          traitStorage.getShields()[traits.shield][0],
          '"}'
        )
      );
    }

    if (traits.head != 0) {
      parts[2] = string(
        abi.encodePacked(
          ',{"trait_type":"Head","value":"',
          traitStorage.getHead()[traits.head][0],
          '"}'
        )
      );
    }

    if (traits.hair != 0) {
      parts[3] = string(
        abi.encodePacked(
          ',{"trait_type":"Hair","value":"',
          traitStorage2.getHair()[traits.hair][0],
          '"}'
        )
      );
    }

    if (traits.clothes != 0) {
      parts[4] = string(
        abi.encodePacked(
          ',{"trait_type":"Clothes","value":"',
          traitStorage.getClothes()[traits.clothes][0],
          '"}'
        )
      );
    }

    if (traits.shoes != 0) {
      parts[5] = string(
        abi.encodePacked(
          ',{"trait_type":"Shoes","value":"',
          traitStorage.getShoes()[traits.shoes][0],
          '"}'
        )
      );
    }

    return
      string(
        abi.encodePacked(
          parts[0],
          parts[1],
          parts[2],
          parts[3],
          parts[4],
          parts[5]
        )
      );
  }

  function _genTraitString(uint256 tokenId)
    internal
    view
    returns (string memory)
  {
    Traits memory traits = genTraits(tokenId);

    return
      string(
        abi.encodePacked(
          '"attributes": [',
          '{"trait_type":"Race","value":"',
          traitStorage.getRace()[traits.race][0],
          '"},',
          '{"trait_type":"Pants","value":"',
          traitStorage.getPants()[traits.pants][0],
          '"}',
          _genOptionalTraits(traits)
        )
      );
  }

  function _genStatsString(uint256 tokenId)
    internal
    view
    returns (string memory)
  {
    Traits memory traits = genTraits(tokenId);
    string[8] memory parts;
    parts[0] = ',{"trait_type":"Magic","value":';
    parts[1] = uintToStr(traits.magic);
    parts[2] = '},{"trait_type":"Strength","value":';
    parts[3] = uintToStr(traits.strength);

    parts[4] = '},{"trait_type":"Intelligence","value":';
    parts[5] = uintToStr(traits.intelligence);
    parts[6] = '},{"trait_type":"Stamina","value":';
    parts[7] = string(
      abi.encodePacked(
        uintToStr(traits.stamina),
        '},{"trait_type":"Dexterity","value":',
        uintToStr(traits.dexterity),
        '},{"trait_type":"Creativity","value":',
        uintToStr(traits.creativity),
        "}"
      )
    );

    return
      string(
        abi.encodePacked(
          parts[0],
          parts[1],
          parts[2],
          parts[3],
          parts[4],
          parts[5],
          parts[6],
          parts[7]
        )
      );
  }

  bool public CDN_ENABLED = false;
  string public CDN_PREFIX = "";

  // Smart contract creates inline SVG, however due to browser security
  // protocols SVGs may not show up in NFT marketplaces. CDN is a back up
  // Smart contract is source of truth for all traits and stats.
  function enableCdn(bool value, string memory prefix) public onlyOwner {
    CDN_ENABLED = value;
    CDN_PREFIX = prefix;
  }

  function getJsonString(uint256 tokenId) public view returns (string memory) {
    return
      string(
        abi.encodePacked(
          '{"name": "Hero #',
          uintToStr(tokenId),
          '", "description": "',
          DESCRIPTION,
          '",',
          '"image": "data:image/svg+xml;base64,',
          Base64.encode(bytes(genSvg(tokenId))),
          '",',
          _genTraitString(tokenId),
          _genStatsString(tokenId),
          "]}"
        )
      );
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(tokenId), "Token ID does not exist");

    if (CDN_ENABLED) {
      return string(abi.encodePacked(CDN_PREFIX, uintToStr(tokenId)));
    }

    if (tokenId >= 10000) {
      return string(abi.encodePacked(_baseURI(), customs[tokenId].uriHash));
    }

    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(bytes(getJsonString(tokenId)))
        )
      );
  }

  function _mint(uint256 amount) internal {
    for (uint256 i = 0; i < amount; i++) {
      uint256 tokenId = ++currentId;
      _safeMint(msg.sender, tokenId);
      tokenIdToSeed[tokenId] = uint256(
        keccak256(
          abi.encodePacked(tokenId, blockhash(block.number - 1), msg.sender)
        )
      );
    }
  }

  function mint(uint256 amount) public payable nonReentrant {
    require(amount <= 10, "Can only mint up to 10");
    require(currentId + amount <= MAX_SUPPLY, "Not allowed");
    require(currentId < MAX_SUPPLY, "All minted");
    require(amount * PRICE_PER_TOKEN == msg.value, "Invalid value");
    _mint(amount);
  }

  uint256 merlinMinted = 0;

  function merlinMint(uint256 amount) public payable onlyOwner {
    require(merlinMinted + amount <= 100, "Merlin can only summon 100 heroes");
    require(currentId < MAX_SUPPLY, "All minted");
    merlinMinted += amount;
    _mint(amount);
  }

  uint256 customMintId = 10000;
  struct Custom {
    bool exists;
    string uriHash;
  }
  mapping(uint256 => Custom) customs;

  function mintCustom(string memory tokenUriHash, address to) public onlyOwner {
    customs[customMintId] = Custom({ exists: true, uriHash: tokenUriHash });
    _safeMint(to, customMintId);
    customMintId += 1;
  }
}

library Base64 {
  bytes internal constant TABLE =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  /// @notice Encodes some bytes to the base64 representation
  function encode(bytes memory data) internal pure returns (string memory) {
    uint256 len = data.length;
    if (len == 0) return "";

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((len + 2) / 3);

    // Add some extra buffer at the end
    bytes memory result = new bytes(encodedLen + 32);

    bytes memory table = TABLE;

    assembly {
      let tablePtr := add(table, 1)
      let resultPtr := add(result, 32)

      for {
        let i := 0
      } lt(i, len) {

      } {
        i := add(i, 3)
        let input := and(mload(add(data, i)), 0xffffff)

        let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
        out := shl(8, out)
        out := add(
          out,
          and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
        )
        out := shl(8, out)
        out := add(
          out,
          and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
        )
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
        out := shl(224, out)

        mstore(resultPtr, out)

        resultPtr := add(resultPtr, 4)
      }

      switch mod(len, 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }

      mstore(result, encodedLen)
    }

    return string(result);
  }
}