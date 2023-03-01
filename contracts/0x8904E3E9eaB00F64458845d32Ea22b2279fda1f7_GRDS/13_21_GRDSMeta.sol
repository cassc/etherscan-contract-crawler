// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IGRDS.sol";
import "./interfaces/IGRDSData.sol";
import "./libraries/GRDSLib.sol";

struct CharNum {
  uint8 num;
  string char;
}

contract GRDSMeta is Ownable {

    address _dataAddress;
    IGRDSData _dataContract;

    using GRDSLib for string;
    using GRDSLib for uint;
    mapping (uint => string) fontsMapping;
    uint8 fontMappingsUint = 1;

    string _description;

    string[25] _friendlyNames = [
      "Zephyr blue","Micro-chip","Coral Pink","Canyon Clay","Withered Rose",
      "Butterfly","Jade Lime","Grass Green","Greenbriar","Parakeet",
      "Cherry Blossom","Begonia Pink", "Opera Mauve","Radiant Orchid","Striking Purple",
      "Golden Haze","Daffodil","Bird-of-paradise","Orange Tiger","Poppy Red",
      "Tanager Turquoise","Aquarius","Malibu Blue","Methyl Blue","Directoire Blue"
    ];
    string[26] _friendlySymbols = [
      'Anonymice','Wonderpals','Unordinals','Robotos','Creature World','OnChainMonkey','Beanz','Cool Cats','PhantaBear','Creepz','My Pet Hooligan','Mfers','Murakami Flowers','CrypToadz','CyberKongz','NFT Worlds','TSRF','Otherside','Checks','Killabears','Pudgy Penguins','Moonbirds','XCOPY','Doodles','BAYC','CryptoPunks'
    ];

    constructor() { fontsMapping[0] = 'GRDS'; }

    function setFontMappingsCount(uint8 _val) external onlyOwner {
      fontMappingsUint = _val;
    }
    
    function setFontMapping(uint _id, string memory _font) external onlyOwner {
      fontsMapping[_id] = _font;
    }

    function getFontMapping(uint _id) public view returns (string memory) {
      return fontsMapping[_id];
    }

    function setDataContract(address _address) external onlyOwner {
      _dataAddress = _address;
      _dataContract = IGRDSData(_address);
    }

    function setFriendlyNames(string[25] memory _newNames) external onlyOwner {
      _friendlyNames = _newNames;
    }
    function setFriendlySymbols(string[26] memory _newSymbolNames) external onlyOwner {
      _friendlySymbols = _newSymbolNames;
    }
    function getFriendlyNames() public view returns(string[25] memory)  {
      return _friendlyNames;
    }
    function getFriendlySymbols() public view returns(string[26] memory)  {
      return _friendlySymbols;
    }
    function setDescription(string memory _d) external onlyOwner {
      _description = _d;
    }

    function division(uint256 decimalPlaces, uint256 numerator, uint256 denominator) internal pure returns(uint256 quotient, uint256 remainder, string memory result) {

        uint256 factor = 10**decimalPlaces;
        quotient  = numerator / denominator;
        bool rounding = 2 * ((numerator * factor) % denominator) >= denominator;
        remainder = (numerator * factor / denominator) % factor;
        if (rounding) {
            remainder += 1;
        }
        result = string(abi.encodePacked(quotient.toString(), '.', numToFixedLengthStr(decimalPlaces, remainder)));
    }

    function numToFixedLengthStr(uint256 decimalPlaces, uint256 num) pure internal returns(string memory result) {
        bytes memory byteString;
        for (uint256 i = 0; i < decimalPlaces; i++) {
            uint256 remainder = num % 10;
            byteString = abi.encodePacked(remainder.toString(), byteString);
            num = num/10;
        }
        result = string(byteString);
    }

    function possibleGrids() public pure returns (uint8[6] memory) {
        return [4, 9, 16, 25, 36, 49];
    }

    function possibleIterations() public pure returns (uint8[6] memory) {
        return [2, 3, 4, 5, 6, 7];
    }

    function findGridValue(uint _len) public pure returns (uint) {

      uint8[6] memory grids = possibleGrids();
      if (_len == 1) { return 1; }
      if (_len == 4) { return 4; }
      if (_len == 9) { return 9; }
      if (_len == 16 ) { return 16; }
      if (_len == 25 ) { return 25; }
      if (_len == 49 ) { return 49; }

        for (uint i = 0; i < grids.length; i++) {
            (uint _q, uint _r,) = division(2, _len, grids[i]);
            if ( _r > 0 && _q == 0) {
                return grids[i];
            }
        }

        revert("No grid value found");
    }

    function fillGrid(string[] memory _colors, string memory _filler) public pure returns (string[] memory) {

      string[] memory _grid = new string[](findGridValue(_colors.length));

      for (uint i = 0; i < _grid.length; i++) {
        if (i < _colors.length) {
          _grid[i] = _colors[i];
        } else {
          _grid[i] = _filler;
        }
      }

      bytes memory result;
        for (uint i = 0; i < _grid.length; i++) {
            bytes memory bytesString = bytes(_grid[i]);
            i == 0 ? result = abi.encodePacked(result, bytesString) : result = abi.encodePacked(result,',', bytesString);
        }

      return _grid;
    }

    function gridCompleted(uint256 colorsLength) public pure returns (bool) {

      uint8[6] memory grids = possibleGrids();

      for (uint256 i = 0; i < grids.length; i++) {
          if (grids[i] == colorsLength) {
              return true;
          }
      }
      return false;
    }

    function collateUniques(uint[2][] memory uniqueColorIDs,uint[2][] memory uniqueSymbolIDs, string[25] memory _caFriendly, string[26] memory _saFriendly) internal pure returns (IGRDS.NameCount[] memory, IGRDS.NameCount[] memory) {

      IGRDS.NameCount[] memory _colorNames = new IGRDS.NameCount[](uniqueColorIDs.length);
      IGRDS.NameCount[] memory _symbolNames = new IGRDS.NameCount[](uniqueSymbolIDs.length);

      for (uint i = 0; i < uniqueColorIDs.length; i++) {
        uint8 _ct = uint8(uniqueColorIDs[i][0]);
        _colorNames[i] = IGRDS.NameCount(_caFriendly[_ct], uniqueColorIDs[i][1]);
      }
      for (uint i = 0; i < uniqueSymbolIDs.length; i++) {
        uint8 _st = uint8(uniqueSymbolIDs[i][0]);
        _symbolNames[i] = IGRDS.NameCount(_saFriendly[_st], uniqueSymbolIDs[i][1]);
      }
            
      return (_colorNames,_symbolNames);
    }

    function tokenMetadata(IGRDS.GroupingExpanded memory _ge) public view returns (string memory) {

        (IGRDS.NameCount[] memory colors,  IGRDS.NameCount[] memory symbols) = collateUniques(_ge.cidsUnique, _ge.sidsUnique, _friendlyNames, _friendlySymbols);

        // console.log(symbols.length == 1, _ge.isGrid, _ge.special);
        _ge.allSameSwitch = (symbols.length == 1 && _ge.isGrid && _ge.special) ? 1 : 0;

        string memory imageBase64 = GRDSLib.encode(bytes(string(abi.encodePacked(_getSvgGrouping(_ge)))));
        string memory _image = string(abi.encodePacked('data:image/svg+xml;base64,', imageBase64));
        
        string memory attributes = string(abi.encodePacked(
            '"attributes": [',
            '{"trait_type": "Difficulty", "value": "', _ge.gridName, '"},',
            _ge.isGrid ? _ge._sPatterns : ''
            ));
        for (uint i = 0; i < symbols.length; i++) {
            attributes = string(abi.encodePacked(attributes, trait(symbols[i].name,uint(symbols[i].count).toString(),',')));
        }
        for (uint i = 0; i < colors.length; i++) {
            bool isLast = i == colors.length - 1;
            string memory _append = isLast ? '' : ',';
            attributes = string(abi.encodePacked(attributes, trait(colors[i].name,uint(colors[i].count).toString(),_append)));
        }
        attributes = string(abi.encodePacked(attributes,']'));

        console.log(attributes);

        string memory _metadata = string(abi.encodePacked(
            '{',
                '"name": "GRDS #', _ge.tokenID.toString(), '",',
                '"description": "', _description, '",',
                attributes,',',
                '"image":"', _image, '"'
            '}'
        ));

        string memory encodeBase64 = GRDSLib.encode(bytes(string(abi.encodePacked(_metadata))));
        string memory _metadataBase64 = string(abi.encodePacked('data:application/json;base64,', encodeBase64));

        return _metadataBase64;
    }

    function trait(
        string memory traitType, string memory traitValue, string memory append
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '{',
                '"trait_type": "', traitType, '",'
                '"value": "', traitValue, '"'
            '}',
            append
        ));
    }

    function _getSvgGrouping(IGRDS.GroupingExpanded memory _ge) internal view returns (string memory) {

        string memory _radius = (_ge.circleRadius).toString();
        uint _steps = 3 + _ge.gridValue;
        uint _itStart = 2;
        uint nextID = 0;
        string[] memory _svgParts = new string[](_steps);
        bytes memory idleString;
        if ( _ge.animationIdle && !_ge.isGrid ) {
          string memory _smallerCircleRadius = (((_ge.rectHeight * 77)/200).toString());
          idleString = abi.encodePacked(
            '<animate attributeName="r" values="',
            _radius,';',_smallerCircleRadius,';',_radius,
            '" dur="5.5s" begin="0s" repeatCount="indefinite"></animate>');
        }
        string memory _idleString = string(idleString);
        if (!_ge.animationIdle) _idleString = "";

        _svgParts[0] = '<svg viewBox="0 0 2520 2520" fill="none" xmlns="http://www.w3.org/2000/svg" style="width: 100%; background: black;">';
        _svgParts[0] = string(abi.encodePacked(_svgParts[0],
        '<style>',
        // getFontMappings(),
        '@font-face {font-family: ',getFontMapping(_ge.allSameSwitch),'; src: url("data:application/octet-stream;base64,',
        _dataContract.getSymData(_ge.allSameSwitch),
        '") format("woff");}'
        '</style>'
        ));
        _svgParts[1] = '<g transform="translate(630, 630) scale(0.5)">';

        for( uint16 y = 0; y < _ge.gridDimension; y++ ) {
            for( uint16 x = 0; x < _ge.gridDimension; x++ ) {
              
              CharNum memory _chNum = CharNum( _ge.allSameSwitch, _ge.filledSymbols[nextID]);
              string memory _symbol = textSVG(x,y,_ge.rectHeight,_chNum);

              uint _circleX = (x * _ge.rectHeight) + (_ge.rectHeight / 2);
              uint _circleY = (y * _ge.rectHeight) + (_ge.rectHeight / 2);

               string memory nextColor = _ge.filledColors[nextID];
               _svgParts[_itStart] = string(abi.encodePacked(
                '<circle r="',
                _radius,
                '" cx="',
               _circleX.toString(),
               '" cy="',
               _circleY.toString(),
               '" fill="#',
               nextColor,
               '">',
                _idleString,
               '</circle>',
               _symbol
               ));
               unchecked { _itStart++; nextID++; }
            }
        }

        _svgParts[_steps-1] = string(abi.encodePacked(
          '</g>',
           bytes(_ge.specialCode).length > 0 ? _ge.specialCode : '',
          '</svg>'
          ));

        bytes memory byteString;
        for (uint i = 0; i < _svgParts.length; i++) {
            byteString = abi.encodePacked(byteString, _svgParts[i]);
          }
        return string(byteString); 
    }


    function textSVG(uint16 _x, uint16 _y, uint _rectHeight, CharNum memory _chNum) internal view returns (string memory) {
          
          bytes memory _symbol = abi.encodePacked(
            '<text text-anchor="middle" alignment-baseline="middle" dominant-baseline="middle" font-size="',
            (_rectHeight/2).toString(),
            '" font-family="',
            getFontMapping(_chNum.num),
            '" x="',
            ((_x * _rectHeight) + _rectHeight/2).toString(),
            '" y="',
            ((_y * _rectHeight) + _rectHeight/2).toString(),
            '" fill="black">',
            _chNum.char,
            '</text>'
          );
        return string(_symbol);
    }
}