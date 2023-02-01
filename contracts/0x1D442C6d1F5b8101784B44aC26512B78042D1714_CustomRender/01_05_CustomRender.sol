// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import './Base64.sol';

import 'hardhat/console.sol';

contract Html {
  function data() public pure returns (string memory) {}
}

contract CustomRender is Ownable {
  string public baseUri;
  string public randomKey;
  bool public showHtml = false;

  Html model1;
  Html model2;
  Html model3;
  Html library4;
  Html shaders5;
  Html builder6;

  function setConnections(
    address _html1Address,
    address _html2Address,
    address _html3Address,
    address _html4Address,
    address _html5Address,
    address _html6Address
  ) public onlyOwner {
    model1 = Html(_html1Address);
    model2 = Html(_html2Address);
    model3 = Html(_html3Address);
    library4 = Html(_html4Address);
    shaders5 = Html(_html5Address);
    builder6 = Html(_html6Address);
  }

  ///////////////// reveal /////////////////

  function setBaseURI(string memory _baseURI) public onlyOwner {
    baseUri = _baseURI;
  }

  function setRandom(string memory _randomKey) public onlyOwner {
    randomKey = _randomKey;
  }

  function setShowHtml(bool _html) public onlyOwner {
    showHtml = _html;
  }

  ///////////////// art /////////////////

  function htmlData(string memory seed) public view returns (string memory) {
    string memory htmlPrefix = string(
      abi.encodePacked(
        '<!doctype html><html><head><meta charset="UTF-8"/><meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"/><meta name="viewport" content="width=device-width,minimal-ui,viewport-fit=cover,initial-scale=1,maximum-scale=1,minimum-scale=1,user-scalable=no"/><title>Tickle Beach</title><style>:root{overflow: hidden; height: 100%}body{margin: 0}</style></head><body><script defer="defer">window.seed="',
        seed,
        '";</script>'
      )
    );

    string memory html = string(
      abi.encodePacked(
        htmlPrefix,
        model1.data(),
        model2.data(),
        model3.data(),
        library4.data(),
        shaders5.data(),
        builder6.data(),
        '</body></html>'
      )
    );
    return html;
  }

  function htmlForToken(uint256 tokenId) public view returns (string memory) {
    string memory html = htmlData(
      toString(
        uint256(keccak256(abi.encodePacked(toString(tokenId), randomKey)))
      )
    );
    return html;
  }

  string[9] private bodyNames = [
    'Urci', // 0: 1Bear
    'Bellow', // 1: 2Bull
    'String Cheese', // 2: 3Cow
    'Umka', // 3: 4Polar Bear
    'Tessy', // 4: 5Dinosaur
    'Roary', // 5: 6Lion
    'Sabre', // 6: 7Tiger
    'Snort', // 7: 9Bunny
    'Koda' // 8: 10Dog
  ];

  string[6] private floorNames = [
    'Beach Sand',
    'The Pier',
    'The Palm',
    'Duck Pond',
    'Waterfall',
    'Camping'
  ];

  string[7] private glassesNames = [
    'Clipons',
    'Lines',
    'Lifeguard',
    'Rounds',
    'Hearts',
    'Shiny',
    'Squares'
  ];

  string[10] private groundNames = [
    'Cooler',
    '808',
    'Chair',
    'Beachball',
    'Skates',
    'Skateboard',
    'Surfs Up',
    'Workout',
    'Treasure',
    'Fishing Rod'
  ];

  string[6] private handNames = [
    'Chips',
    'Towel',
    'Snacks',
    'Games',
    'Tube',
    'Wake Board'
  ];

  string[7] private headNames = [
    'Ball Cap',
    'Headband',
    'Visor',
    'Fish',
    'Fro',
    'Flow',
    'Punk'
  ];

  string[4] private neckNames = ['Puka', 'Beads', 'Hemp Necklace', 'Skull'];

  string[5] private shirtNames = [
    'Surfs Up',
    'Stripes',
    'Totem',
    'Lifeguard',
    'Button Up'
  ];

  string[4] private shoesNames = ['Sneaks', 'Sandles', 'Fins', 'Flips'];

  string[13] private themeNames = [
    'Pink',
    'Maroon',
    'Blue',
    'Green',
    'Red & Black',
    'Beige',
    'Golden',
    'Purple',
    'Orange',
    'White, Black',
    'Yellow & Black',
    'Light Pink & Blue',
    'Brown & Blue'
  ];

  string[4] private skyNames = ['Noon', 'Stormy', 'Dawn', 'Sunset'];

  function sel(uint256 tokenId)
    public
    view
    returns (
      uint256[18] memory,
      uint8,
      uint8[13] memory
    )
  {
    string memory _hasMini = hash(tokenId);
    string memory fullHash = string(
      abi.encodePacked(_hasMini, _hasMini, _hasMini, _hasMini, _hasMini)
    );

    uint256[60] memory numbers;
    uint256 hashLength = strlen(fullHash);
    // console.log('hashLength', hashLength);
    uint256 numberIndex = 0;
    for (uint256 i = 0; i < hashLength; i += 7) {
      uint256 end = numberIndex * 7 + 7;
      if (end > hashLength) {
        end = hashLength;
      }

      numbers[numberIndex] = convertString(
        substring(fullHash, numberIndex * 7, end)
      );
      // console.log('numbers[numberIndex]', numberIndex, numbers[numberIndex]);
      numberIndex = numberIndex + 1;
    }

    // string[][] memory choices = [
    //   bodyNames,
    //   floorNames,
    //   glassesNames,
    //   groundNames,
    //   handNames,
    //   headNames,
    //   neckNames,
    //   shirtNames,
    //   shoesNames
    // ];

    // string[9] private bodyNames = [
    // string[6] private floorNames = [
    // string[7] private glassesNames = [
    // string[5] private shirtNames = [
    // string[10] private groundNames = [
    // string[6] private handNames = [
    // string[7] private headNames = [
    // string[4] private neckNames = [
    // string[4] private shoesNames = ['Sneaks', 'Sandles', 'Fins', 'Flips'];

    // const allParts = [
    //   'body',
    //   'floor',
    //   'glasses',
    //   'shirt',
    //   'ground',
    //   'hand',
    //   'headtop',
    //   'neck',
    //   'shoes',
    // ];

    // ordered to match js
    uint8[9] memory choiceSizes = [9, 6, 7, 5, 10, 6, 7, 4, 4];

    // let themesMin = [
    //   [10001, 10011, 10021], // pink (done)
    //   [10031, 10041, 10051], // maroon (done)
    //   [10061, 10071, 10081], // blue (done)
    //   [10091, 10101, 10111], // green (done)
    //   [10121, 10131, 10141], // red + black (done)
    //   /// SECOND 5
    //   [10151, 10161, 10171], // beige (done)
    //   [10181, 10191, 10201], // golden (done)
    //   [10211, 10221, 10231], // purple (done)
    //   [10241, 10251, 10261], // orange (done)
    //   [10271, 10281, 10291], // white, black, white (done)
    //   /// THIRD 5
    //   [10301, 10311, 10321], // yellow and black (done)
    //   [10331, 10341, 10351], // light pink and blue (done)
    //   [10391, 10401, 10411], // brown and blue
    // ];

    // string memory choiceNames = [
    //   'Body',
    //   'Floor',   #themable
    //   'Glasses', #themable   #optional
    //   'Ground',  #themable   #optional
    //   'Hand',    #themable   #optional
    //   'Head',    #themable   #optional
    //   'Neck',    #themable   #optional
    //   'Shirt',   #themable   #optional
    //   'Shoes'    #themable
    // ];

    // const themablePartNames = [
    //   'floor',
    //   'glasses',
    //   'ground',
    //   'hand',
    //   'headtop',
    //   'neck',
    //   'shirt',
    //   'shoes',
    // ];

    // const OPTIONAL_MODELS = [
    //   'hand',
    //   'glasses',
    //   'ground',
    //   'headtop',
    //   'shirt',
    //   'neck'
    // ];

    uint256[18] memory selection;
    // for every choice, pop a number and mod it
    for (uint256 i = 0; i <= 8; i++) {
      numberIndex = numberIndex - 1;
      selection[i] = numbers[numberIndex] % choiceSizes[i];
    }

    // uint8 percentOfSkippedModels = 15;
    // uint8 percentOfTheme = 80;
    // uint8 themeMatchPercent = 50;
    // uint8 themeTotal = 13;

    numberIndex = numberIndex - 1;
    uint256 themeMatch = numbers[numberIndex] % 13; //themeCount;
    uint8 skippedModels = 0;
    uint256 firstNumber;
    uint256 secondNumber;

    uint8[13] memory themeUsed = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

    // themeable
    for (uint256 i = 9; i <= 16; i++) {
      numberIndex = numberIndex - 1;
      firstNumber = numbers[numberIndex];

      numberIndex = numberIndex - 1;
      secondNumber = numbers[numberIndex];

      uint256 themeApplication = (firstNumber % 10) * 10 + (secondNumber % 10);

      // percentOfTheme
      if (themeApplication < 80) {
        // themeMatchPercent
        if (themeApplication < 50) {
          selection[i] = themeMatch;
        } else {
          numberIndex = numberIndex - 1;
          selection[i] = numbers[numberIndex] % 13; // themeCount;
        }
      } else {
        selection[i] = 999;
      }

      if (i >= 10 && i <= 15) {
        numberIndex = numberIndex - 1;
        firstNumber = numbers[numberIndex];

        numberIndex = numberIndex - 1;
        secondNumber = numbers[numberIndex];

        // percentOfSkippedModels
        if ((firstNumber % 10) * 10 + (secondNumber % 10) < 15) {
          selection[i - 8] = 800;
          selection[i] = 700;
          skippedModels = skippedModels + 1;
        }
      }

      if (selection[i] < 100) {
        themeUsed[selection[i]] = themeUsed[selection[i]] + 1;
      }
    }

    // find the index of themeUsed which has the largest value

    numberIndex = numberIndex - 1;
    selection[17] = numbers[numberIndex] % 4;

    return (selection, skippedModels, themeUsed);
  }

  function traits(uint256 tokenId) public view returns (string memory) {
    uint8 skippedModels;
    uint256[18] memory selection;
    uint8[13] memory themeUsed;

    (selection, skippedModels, themeUsed) = sel(tokenId);

    uint8 max = themeUsed[0];
    for (uint8 j = 1; j < themeUsed.length; j++) {
      if (themeUsed[j] > max) {
        max = themeUsed[j];
      }
    }

    // const allParts = [
    //   'body',
    //   'floor',
    //   'glasses',
    //   'shirt',
    //   'ground',
    //   'hand',
    //   'headtop',
    //   'neck',
    //   'shoes',
    // ];

    string memory none = 'None';
    string memory zero = '0';

    string memory first = string(
      abi.encodePacked(
        '{"Character": "',
        selection[0] > 100 ? none : bodyNames[selection[0]],
        '", "Location": "',
        selection[1] > 100 ? none : floorNames[selection[1]],
        '", "Glasses": "',
        selection[2] > 100 ? none : glassesNames[selection[2]],
        '", "Shirt": "',
        selection[3] > 100 ? none : shirtNames[selection[3]],
        '", "Ground": "',
        selection[4] > 100 ? none : groundNames[selection[4]],
        '", "Holding": "',
        selection[5] > 100 ? none : handNames[selection[5]],
        '", "Head": "',
        selection[6] > 100 ? none : headNames[selection[6]],
        '", "Necklace": "',
        selection[7] > 100 ? none : neckNames[selection[7]]
      )
    );

    string memory second = string(
      abi.encodePacked(
        first,
        '", "Shoes": "',
        selection[8] > 100 ? none : shoesNames[selection[8]],
        '", "Location Theme": "',
        (selection[9] < 100) ? themeNames[selection[9]] : none,
        '", "Glasses Theme": "',
        (selection[10] < 100) ? themeNames[selection[10]] : none,
        '", "Shirt Theme": "',
        (selection[11] < 100) ? themeNames[selection[11]] : none,
        '", "Ground Theme": "',
        (selection[12] < 100) ? themeNames[selection[12]] : none
      )
    );

    string memory third = string(
      abi.encodePacked(
        second,
        '", "Holding Theme": "',
        (selection[13] < 100) ? themeNames[selection[13]] : none,
        '", "Head Theme": "',
        (selection[14] < 100) ? themeNames[selection[14]] : none,
        '", "Necklace Theme": "',
        (selection[15] < 100) ? themeNames[selection[15]] : none,
        '", "Shoes Theme": "',
        (selection[16] < 100) ? themeNames[selection[16]] : none,
        '", "Sky": "',
        selection[17] > 100 ? none : skyNames[selection[17]]
      )
    );

    // string[13] private themeNames = [
    //   'Pink',
    //   'Maroon',
    //   'Blue',
    //   'Green',
    //   'Red & Black',
    //   'Beige',
    //   'Golden',
    //   'Purple',
    //   'Orange',
    //   'White, Black',
    //   'Yellow & Black',
    //   'Light Pink & Blue',
    //   'Brown & Blue'
    // ];

    string memory forth = string(
      abi.encodePacked(
        third,
        '", "Pink Count": "',
        (themeUsed[0] > 0) ? toString(themeUsed[0]) : zero,
        '", "Maroon Count": "',
        (themeUsed[1] > 0) ? toString(themeUsed[1]) : zero,
        '", "Blue Count": "',
        (themeUsed[2] > 0) ? toString(themeUsed[2]) : zero,
        '", "Green Count": "',
        (themeUsed[3] > 0) ? toString(themeUsed[3]) : zero,
        '", "Red & Black Count": "',
        (themeUsed[4] > 0) ? toString(themeUsed[4]) : zero
      )
    );

    string memory fifth = string(
      abi.encodePacked(
        forth,
        '", "Beige Count": "',
        (themeUsed[5] > 0) ? toString(themeUsed[5]) : zero,
        '", "Golden Count": "',
        (themeUsed[6] > 0) ? toString(themeUsed[6]) : zero,
        '", "Purple Count": "',
        (themeUsed[7] > 0) ? toString(themeUsed[7]) : zero,
        '", "Orange Count": "',
        (themeUsed[8] > 0) ? toString(themeUsed[8]) : zero,
        '", "White, Black Count": "',
        (themeUsed[9] > 0) ? toString(themeUsed[9]) : zero
      )
    );

    string memory sixth = string(
      abi.encodePacked(
        fifth,
        '", "Yellow & Black Count": "',
        (themeUsed[10] > 0) ? toString(themeUsed[10]) : zero,
        '", "Light Pink & Blue Count": "',
        (themeUsed[11] > 0) ? toString(themeUsed[11]) : zero,
        '", "Brown & Blue Count": "',
        (themeUsed[12] > 0) ? toString(themeUsed[12]) : zero
      )
    );

    return
      string(
        abi.encodePacked(
          sixth,
          '", "Clean Rank": "',
          toString(skippedModels),
          '", "Matching Rank": "',
          toString(max),
          '"}'
        )
      );
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    string memory stringTokenId = toString(tokenId);
    string memory html = '<for on/in chain art, call htmlForToken with id>';

    string memory _traits = traits(tokenId);

    // the read gas limit is too low, so we've turned this off for now.
    if (showHtml == true) {
      html = htmlForToken(tokenId);
    }

    string memory imageUrl = string(
      abi.encodePacked(baseUri, '/preview/', stringTokenId, '.png')
    );

    string memory animationUrl = string(
      abi.encodePacked(baseUri, '/animation/', stringTokenId, '.html')
    );

    string memory externalUrl = string(
      abi.encodePacked(baseUri, '/gallery/', stringTokenId)
    );

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "Tickle Beach #',
            stringTokenId,
            '", "image": "',
            imageUrl,
            '", "animation_url": "',
            animationUrl,
            '", "traits": ',
            _traits,
            ', "external_url": "',
            externalUrl,
            '", "description": "Tickle Beach loves you.',
            // we did forever3d to avoid api collisons, can change when a standard emerges
            '", "forever3d_html": "data:text/html;base64,',
            Base64.encode(bytes(html)),
            '"}'
          )
        )
      )
    );

    return string(abi.encodePacked('data:application/json;base64,', json));
  }

  // ///////////////// utils /////////////////

  function hash(uint256 tokenId) public view returns (string memory) {
    string memory _hash = toString(
      uint256(keccak256(abi.encodePacked(toString(tokenId), randomKey)))
    );

    return _hash;
  }

  function substring(
    string memory str,
    uint256 startIndex,
    uint256 endIndex
  ) public pure returns (string memory) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIndex - startIndex);
    for (uint256 i = startIndex; i < endIndex; i++) {
      result[i - startIndex] = strBytes[i];
    }

    return string(result);
  }

  // MIT
  // https://github.com/ensdomains/ens-contracts/blob/master/contracts/ethregistrar/StringUtils.sol
  function strlen(string memory s) internal pure returns (uint256) {
    uint256 len;
    uint256 i = 0;
    uint256 bytelength = bytes(s).length;
    for (len = 0; i < bytelength; len++) {
      bytes1 b = bytes(s)[i];
      if (b < 0x80) {
        i += 1;
      } else if (b < 0xE0) {
        i += 2;
      } else if (b < 0xF0) {
        i += 3;
      } else if (b < 0xF8) {
        i += 4;
      } else if (b < 0xFC) {
        i += 5;
      } else {
        i += 6;
      }
    }
    return len;
  }

  function strToUint(string memory _str) public pure returns (uint256 res) {
    for (uint256 i = 0; i < bytes(_str).length; i++) {
      if (
        (uint8(bytes(_str)[i]) - 48) < 0 || (uint8(bytes(_str)[i]) - 48) > 9
      ) {
        return 0;
      }
      res += (uint8(bytes(_str)[i]) - 48) * 10**(bytes(_str).length - i - 1);
    }

    return res;
  }

  function numberFromAscII(bytes1 b) private pure returns (uint8 res) {
    if (b >= '0' && b <= '9') {
      return uint8(b) - uint8(bytes1('0'));
    } else if (b >= 'A' && b <= 'F') {
      return 10 + uint8(b) - uint8(bytes1('A'));
    } else if (b >= 'a' && b <= 'f') {
      return 10 + uint8(b) - uint8(bytes1('a'));
    }
    return uint8(b); // or return error ...
  }

  function convertString(string memory str)
    public
    pure
    returns (uint256 value)
  {
    bytes memory b = bytes(str);
    uint256 number = 0;
    for (uint256 i = 0; i < b.length; i++) {
      number = number << 4; // or number = number * 16
      number |= numberFromAscII(b[i]); // or number += numberFromAscII(b[i]);
    }
    return number;
  }

  // Inspired by OraclizeAPI's implementation - MIT license
  // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
  function toString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return '0';
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }
}