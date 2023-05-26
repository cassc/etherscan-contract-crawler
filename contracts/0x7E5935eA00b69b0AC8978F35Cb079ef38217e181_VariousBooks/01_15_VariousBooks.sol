// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract VariousBooks is ERC721Enumerable, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;

  uint256 public constant mintPrice = 25000000000000000;
  bool public saleIsActive = false;
  Counters.Counter private _tokenIdCounter;

  string[] private nouns = [ 
    "Abyss", "Addiction", "Affairs", "Ages", "Animals", "Answer", "Approach", "Arrangement", 
    "Art", "Ashes", "Beauties", "Beginnings", "Birch", "Blossom", "Body", "Books", 
    "Book", "Botany", "Bounty", "Buffalo", "Centuries", "Cities", "City", "Civilization", 
    "Clouds", "Coast", "Continuum", "Corn", "Courage", "Cowboy", "Crows", "Crystals", 
    "Cults", "Darkness", "Days", "Delegation", "Desert", "Destiny", "Development", "Distance", 
    "Division", "Doves", "Dreamer", "Dreams", "Dunes", "Eagle", "Earth", "Elegance", 
    "End", "Environments", "Excavations", "Eye", "Fall", "Fantasies", "Fire", "Fish", 
    "Flame", "Folklore", "Fools", "Force", "Fraud", "Frost", "Future", "Games", 
    "Gemstones", "Goddess", "Grain", "History", "Illusion", "Interaction", "Introduction", 
    "Jury", "Knowledge", "Labours", "Land", "Law", "Legends", "Life", "Light", "Maps", 
    "Masterpieces", "Meadow", "Meditations", "Memoirs", "Memory", "Mist", "Moon", "Mountains", 
    "Mushrooms", "Mysteries", "Mystery", "Network", "Night", "Oasis", "Oceans", 
    "Owls", "Painting", "Palace", "Parrots", "Past", "Patterns", "Peach", "Persona", 
    "Perspective", "Petals", "Planet", "Plants", "Plays", "Poison", "Poetics", "Prehistory", 
    "Problems", "Procedures", "Prophecy", "Purpose", "Quarrel", "Rain", "Reality", "Report", 
    "Republic", "Rescue", "Revolution", "Rice", "River", "Rivers", "Ruins", "Rules", 
    "Seashells", "Seasons", "Serpent", "Shadow", "Sheep", "Ships", "Shores", "Sky", 
    "Smoke", "Snow", "Space", "Spaces", "Sparrow", "Spectrum", "Spirit", "Spirits", 
    "Spring", "Stars", "State", "States", "Steppes", "Stories", "Storm", "Strategies", 
    "Streams", "Structures", "Summer", "Sun", "Surroundings", "Systems", "Tactics", "Tears", 
    "Techniques", "Thorn", "Thought", "Thoughts", "Throne", "Time", "Toad", "Treasures", 
    "Trees", "Tundra", "Valleys", "Vision", "Voices", "Volcanoes", "Wanderer", "Water", 
    "Ways", "Whisper", "Wildflowers", "Wind", "Wings", "Winter", "World", "Worlds", "Years"
  ];

  string[] private adjectives = [
    "Academic", "Ancient", "Basic", "Big", "Burning", "Bright", "Broken", "Bronze", 
    "Cold", "Complete", "Concise", "Consolidated", "Contemporary", "Continuous", "Cursed", "Cyber", 
    "Eastern", "Elemental", "Emerald", "Experimental", "Fallen", "First", "Forgotten", "Frozen", 
    "Fundamental", "Golden", "Greater", "Hardcore", "Hidden", "High", "Historic", "Holistic", 
    "Haunted", "Illustrated", "Informational", "Instant", "Little", "Living", "Lonely", "Lost", 
    "Lunar", "Magnetic", "Misty", "Modern", "New", "Northern", "Phantom", "Polar", 
    "Psychological", "Pure", "Quantum", "Romantic", "Rough", "Sacred", "Secret", "Silent", 
    "Simple", "Solar", "Southern", "Strange", "Supernatural", "Theoretical", "Third", "Total", 
    "Traditional", "Trailing", "Trembling", "Unknown", "Vacant", "Wandering", "Western", "Wild"
  ];

  string[] private prepositions = [
    "or",
    "from",
    "through",
    "with",
    "without",
    "beneath",
    "beyond",
    "before",
    "against",
    "amongst"
  ];

  string[] private formats = [
    "Softcover",
    "Oversized",
    "Mass-Market",
    "Hardcover",
    "Booklet"
  ];

  string[] private conditions = [
    "Fair",
    "Poor",
    "Perfect",
    "Fine",
    "Very Good",
    "Good"
  ];

  string[] private colors = [
    "#B08699",
    "#EBD999",
    "#FA2B00",
    "#0D75FF",
    "#66AB56",
    "#FFAB00",
    "#FFFFFF"
  ];

  uint256[] private formatWeights = [ 25, 38, 65, 85, 100 ];
  uint256[] private conditionWeights = [ 22, 36, 48, 63, 80, 100 ];
  uint256[] private colorWeights = [ 1, 2, 3, 4, 5, 6, 9 ];

  function random(uint256 tokenId, string memory seed) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(seed, Strings.toString(tokenId))));
  }

  function getFormat(uint256 tokenId) public view returns (string memory) {
    return select(tokenId, "FORMAT", formats, formatWeights);
  }

  function getCondition(uint256 tokenId) public view returns (string memory) {
    return select(tokenId, "CONDITION", conditions, conditionWeights);
  }

  function getCoverColor(uint256 tokenId) public view returns (string memory) {
    return select(tokenId, "COLOR", colors, colorWeights);
  }

  function getSpineColor(uint256 tokenId) public view returns (string memory) {
    if ((random(tokenId, "SPINERARITY") % 15) < 3) {
      return select(tokenId, "SPINECOLOR", colors, colorWeights);
    } else {
      return select(tokenId, "COLOR", colors, colorWeights);
    }
  }

  function getPublisher(uint256 tokenId) public pure returns (uint256) {
    uint256 rand = random(tokenId, "PUBLISHER") % 100;
    return 15 > rand ? 1 : (51 > rand ? 2 : 3);
  }

  function getPages(uint256 tokenId) public pure returns (uint256) {
    return random(tokenId, "PAGES") % 501;
  }

  function getTitle(uint256 tokenId) public view returns (string memory) {
    uint256 rand = random(tokenId, "TITLE");
    uint256 format = rand % 4;
    string memory a1 = adjectives[(rand / 3) % adjectives.length];
    string memory n1 = nouns[(rand / 5) % nouns.length];
    string memory t1 = (rand / 7) % 2 != 0 ? 'The ' : '';
    string memory a2 = adjectives[(rand / 9) % adjectives.length];
    string memory n2 = nouns[(rand / 11) % nouns.length];
    string memory t2 = (rand / 13) % 2 != 0 ? 'the ' : '';
    string memory p = prepositions[(rand / 15) % prepositions.length];
    string memory j = (rand / 17) % 2 != 0 ? 'and' : 'of';

    if (format < 2) {
      return string(abi.encodePacked(
        (format == 1 ? t1 : ''), a1, ' ', n1
      ));
    } else {
      a1 = (rand / 26) % 2 != 0 ? string(abi.encodePacked(a1, ' ')) : '';
      a2 = (rand / 6) % 2 != 0 ? string(abi.encodePacked(a2, ' ')) : '';
      return string(abi.encodePacked(
        t1, a1, n1, ' ', (format == 2 ? p : j), ' ', t2, a2, n2
      ));
    }
  }

  function getTitleOutput(uint256 tokenId) internal view returns (string memory) {
    string memory output;
    bytes memory b = bytes(getTitle(tokenId));
    
    uint256 y = 78;
    uint256 i = 0;
    uint256 e = 0;    
    uint256 ll = 13;
    
    while (true) {
      e = i + ll;
      if (e >= b.length) {
        e = b.length;
      } else {
        while (b[e] != ' ' && e > i) { e--; }
      }

      bytes memory line = new bytes(e-i);
      for (uint k = i; k < e; k++) {
        line[k-i] = _upper(b[k]);
      }

      output = string(abi.encodePacked(output,'<text x="275" y="',Strings.toString(y),'">',line,'</text>'));
      if (y > 300) break;
      
      y += 38;
      if (e >= b.length) break;
      i = e + 1;
    }

    return output;
  }

  function getPublisherOutput(uint256 tokenId) internal pure returns (string memory) {
    uint256 publisher = getPublisher(tokenId);
    return publisher == 1 
      ? '<polygon points="50,430 60,450 40,450" />'
      : (publisher == 2 
      ? '<rect width="20" height="20" x="40" y="430" />' 
      : '<circle r="10" cx="50" cy="440" />');
  }

  function select(uint256 tokenId, string memory key, string[] memory sourceArray, uint256[] memory sourceWeights) internal pure returns (string memory) {
    uint256 val = random(tokenId, key) % sourceWeights[sourceWeights.length - 1];
    for(uint256 i = 0; i < sourceWeights.length; i++) {
      if (sourceWeights[i] > val) {
        return sourceArray[i];
      }
    } 
  }

  function tokenURI(uint256 tokenId) override public view returns (string memory) {
    string memory output = string(abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 500"><rect width="500" height="500" />',
      '<rect width="450" height="450" x="25" y="25" rx="25" fill="', getCoverColor(tokenId), '" stroke="#000" />',
      '<rect width="50" height="450" x="25" y="25" fill="', getSpineColor(tokenId), '" stroke="#000" />',
      '<g font-family="serif" font-size="38px" text-anchor="middle">', getTitleOutput(tokenId),
      '<text x="275" y="450">', Strings.toString(tokenId), '</text></g>',
      '<text transform="rotate(90) translate(50 -45)" font-family="serif" font-size="16px">', getFormat(tokenId), ', ', Strings.toString(getPages(tokenId)), ', ', getCondition(tokenId), '</text>',
      getPublisherOutput(tokenId),
      '</svg>'
    ));

    string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Book #', Strings.toString(tokenId), '", "description": "Various Books is a collection of speculative books generated and stored on chain.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
    output = string(abi.encodePacked('data:application/json;base64,', json));

    return output;
  }

  function claim() public payable {
    require(saleIsActive, "Sale is not active");
    uint256 nextId = _tokenIdCounter.current();
    require(mintPrice <= msg.value, "Ether value sent is not correct");
    require(nextId <= 4500, "Token limit reached");
    _safeMint(_msgSender(), nextId);
    _tokenIdCounter.increment();
  }

  function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
    require(tokenId > 4500 && tokenId <= 4600, "Token ID invalid");
    _safeMint(owner(), tokenId);
  }

  function flipSaleState() public onlyOwner {
    saleIsActive = !saleIsActive;
  }

  function withdraw(address to, uint256 amount) public nonReentrant onlyOwner {
    require(amount <= address(this).balance, "Amount too high");
    payable(to).transfer(amount);
  }

  function _upper(bytes1 _b1) private pure returns (bytes1) {
    if (_b1 >= 0x61 && _b1 <= 0x7A) {
      return bytes1(uint8(_b1) - 32);
    }
    return _b1;
  }

  constructor() ERC721("VariousBooks", "VAB") Ownable() {
    _tokenIdCounter.increment();
  }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
  bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
        out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
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