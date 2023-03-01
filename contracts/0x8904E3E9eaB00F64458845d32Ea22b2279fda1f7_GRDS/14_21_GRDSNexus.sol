// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IGRDS.sol";
import "./interfaces/IGRDSpecial.sol";
import "./interfaces/IGRDSMeta.sol";
import "./GRDSMeta.sol";
import "./libraries/GRDSLib.sol";

contract GRDSNexus is IGRDS, Ownable {

  address _metaAddress;
  IGRDSMeta _metaContract;
  address _specialContractAddress;
  IGRDSpecial _specialContract;
  bool _special;

  mapping (uint => string) _gridNamesArray;

  using GRDSLib for uint;

  string[25] _colorsHEX = [
      'D3D9D1', 'BABCC0', 'E8A798', 'CE8477', 'A26666',
      'CADEA5', 'A1CA7B', '7BB369', '4B9B69', '008C69',
      'F7CEE0', 'EC9ABE', 'CA80B1', 'AD5E99', '944E87',
      'FBD897', 'FDC04E', 'FF8C55', 'F96714', 'DC343B',
      '91DCE8', '3CADD4', '008CC1', '0074A8', '0061A3'
  ];

  struct SpecialPatternValues {
    string _sType;
    string _sValue;
  }

  function setSpecial(address _specialAddress) external onlyOwner {
    _specialContractAddress = _specialAddress;
    _specialContract = IGRDSpecial(_specialAddress);
    _special = true;
  }

  function setMeta(address _address) external onlyOwner {
    _metaAddress = _address;
    _metaContract = IGRDSMeta(_metaAddress);
  }

  function COLORS_ARRAY() public view returns (string[25] memory) {
    return _colorsHEX;
  }

  function setCOLORS(string[25] memory _newColors) external onlyOwner {
    _colorsHEX = _newColors;
  }

  function SYMBOLS_ARRAY() public pure returns (string[26] memory) {
    string[26] memory _sa = ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'];
    return _sa;
  }

  function setGridNames(string[] memory _names) public onlyOwner {
    uint8[7] memory _grid = [1,4,9,16,25,36,49];
    for (uint i = 0; i < _grid.length; i++) {
      _gridNamesArray[_grid[i]] = _names[i];
    }
  }
  function GRID_NAMES(uint gridValue) public view returns( string memory) {
      return _gridNamesArray[gridValue];
  }

  function countUniques(uint8[] memory input) internal pure returns (uint[2][] memory) {
    uint[2][] memory result = new uint[2][](input.length);
    uint count = 0;
    for (uint i = 0; i < input.length; i++) {
        bool found = false;
        for (uint j = 0; j < count; j++) {
            if (result[j][0] == input[i]) {
                found = true;
                result[j][1] += 1;
                break;
            }
        }
        if (!found) {
            result[count] = [uint(input[i]), 1];
            count += 1;
        }
    }
    uint[2][] memory uniqueNumbers = new uint[2][](count);
    for (uint k = 0; k < count; k++) {
        uniqueNumbers[k] = result[k];
    }
    return uniqueNumbers;
  }

  function findStepsPerIteration(uint _gridValue) internal pure returns (uint) {
      if ( _gridValue == 4 ) {return 2;}
      if ( _gridValue == 9 ) {return 3;}
      if ( _gridValue == 16 ) {return 4;}
      if ( _gridValue == 25 ) {return 5;}
      if ( _gridValue == 36 ) {return 6;}
      if ( _gridValue == 49 ) {return 7;}
      revert("Invalid grid value");
  }

  function expandedGrouping(uint tokenID, uint8[] memory _cidsIDs, uint8[] memory _sidsIDs) public view returns (GroupingExpanded memory) {
    string[25] memory _ca = COLORS_ARRAY();
    string[26] memory _sa = SYMBOLS_ARRAY();
    GroupingExpanded memory _ge;
    uint len = _cidsIDs.length;
    string[] memory _c = new string[](len);
    string[] memory _s = new string[](len);

    for (uint i = 0; i < len; i++) {
      _c[i] = _ca[_cidsIDs[i]]; 
      _s[i] = _sa[_sidsIDs[i]]; 
    }

    uint[2][] memory _cidsUnique = countUniques(_cidsIDs);
    uint[2][] memory _sidsUnique = countUniques(_sidsIDs);

    bool isGrid = _metaContract.gridCompleted(len);
    uint gridValue = _metaContract.findGridValue(len);
    uint gridDimension = findStepsPerIteration(gridValue);
    string memory _patterns;
    if (isGrid) {
      bytes memory _syms = stringsToBytes(_s);
      _patterns = countAll(_syms,gridDimension);
    }
    // console.log(_patterns);

    _ge.tokenID = tokenID;
    _ge.hexColors = _c;
    _ge.symbols = _s;
    _ge.isGrid = isGrid;
    _ge.gridValue = gridValue;
    _ge.gridName = GRID_NAMES(_ge.gridValue);
    _ge.gridDimension = gridDimension;
    _ge.filledColors = _metaContract.fillGrid(_ge.hexColors, '222222');
    _ge.filledSymbols = _metaContract.fillGrid(_ge.symbols, '');
    _ge.rectHeight = 2520 / _ge.gridDimension;
    _ge.circleRadius = (_ge.rectHeight * 17)/40;
    _ge.animationIdle = !_ge.isGrid; 
    _ge.cidsUnique = _cidsUnique;
    _ge.sidsUnique = _sidsUnique;
    _ge._sPatterns = _patterns;
    return _ge;
  }

  function getSingleNames(uint8 _id, bool _colorsMode) public view returns (string[] memory) {
    if (_colorsMode) {
      string[25] memory _fn = _metaContract.getFriendlyNames();
      string[] memory _c = new string[](1);
      _c[0] = _fn[_id];
      return _c;
    } else {
      string[26] memory _fs = _metaContract.getFriendlySymbols();
      string[] memory _s = new string[](1);
      _s[0] = _fs[_id];
      return _s;
    }
  }
  function getGroupingNames(uint8[] memory _values, bool _colorsMode) public view returns (string[] memory) {

    if (_colorsMode) {

      string[25] memory _fn = _metaContract.getFriendlyNames();

      string[] memory _c = new string[](_values.length);

      for (uint i = 0; i < _values.length; i++) {
        _c[i] = _fn[_values[i]];
      }
      return _c;

    } else {
      string[26] memory _fs = _metaContract.getFriendlySymbols();
      string[] memory _s = new string[](_values.length);

      for (uint i = 0; i < _values.length; i++) {
        _s[i] = _fs[_values[i]];
      }
      return _s;
    }
  }

  function expandedSingle(uint tokenID, uint8 _cidID, uint8 _sidID) public view returns (GroupingExpanded memory) {
    string[25] memory _ca = COLORS_ARRAY();
    string[26] memory _sa = SYMBOLS_ARRAY();
    // console.log('expandedSingle');
    GroupingExpanded memory _ge;
    string[] memory _c = new string[](1);
    _c[0] = _ca[_cidID];
    string[] memory _s = new string[](1);
    _s[0] = _sa[_sidID];

    uint[2][] memory _cidsUnique = new uint[2][](1);
    _cidsUnique[0][0] = _cidID;
    _cidsUnique[0][1] = 1;
    uint[2][] memory _sidsUnique = new uint[2][](1);
    _sidsUnique[0][0] = _sidID;
    _sidsUnique[0][1] = 1;

    _ge.tokenID = tokenID;
    _ge.hexColors = _c;
    _ge.symbols = _s;
    _ge.isGrid = false;
    _ge.gridValue = 1;
    _ge.gridName = 'Base';
    _ge.gridDimension = 1;
    _ge.filledColors = _c;
    _ge.filledSymbols = _s;
    _ge.rectHeight = 2520 / _ge.gridDimension;
    _ge.circleRadius = (_ge.rectHeight * 17)/40;
    _ge.animationIdle = !_ge.isGrid; 
    _ge.cidsUnique = _cidsUnique;
    _ge.sidsUnique = _sidsUnique;
    return _ge;
  }

  function getMeta(GroupingExpanded memory _ge) public view returns (string memory) {
    if (_special && _ge.isGrid) {
      if (_ge.gridValue >= 9) {
        _ge.special = true;
        _ge.specialCode = _specialContract.isGrid(_ge.gridValue, _ge.hexColors, _ge.symbols);
      }
    }

    return _metaContract.tokenMetadata(_ge);
  }

  function countCols(bytes memory letters, uint256 gridSize) internal pure returns (uint256) {
  uint256 numCols = gridSize;
  uint256 colMatchCount = 0;

  bytes32 firstLetter;
  bytes32 letter;

  for (uint256 c = 0; c < numCols; c++) {
    bool isMatch = true;
    firstLetter = bytes32(letters[c]);

    for (uint256 r = 1; r < gridSize; r++) {
      letter = bytes32(letters[r * numCols + c]);
      if (letter != firstLetter) {
        isMatch = false;
        break;
      }
    }

    if (isMatch) {
      colMatchCount++;
    }
  }

  return colMatchCount;
}

 function countRows(bytes memory letters, uint256 gridSize) internal pure returns (uint256) {
        uint256 numRows = gridSize;
        uint256 rowMatchCount = 0;
        
        assembly {
            let lettersLength := mload(letters)
            let lettersPointer := add(letters, 32)
            
            for { let r := 0 } lt(r, numRows) { r := add(r, 1) } {
                let isMatch := 1
                let firstLetter := byte(0, mload(add(lettersPointer, mul(r, gridSize))))
                
                for { let c := 1 } lt(c, gridSize) { c := add(c, 1) } {
                    let letter := byte(0, mload(add(lettersPointer, add(mul(r, gridSize), c))))
                    if iszero(eq(letter, firstLetter)) {
                        isMatch := 0
                        break
                    }
                }
                
                if isMatch {
                    rowMatchCount := add(rowMatchCount, 1)
                }
            }
        }
        
        return rowMatchCount;
    }

function isPlus(bytes memory letters, uint256 gridSize) internal pure returns (uint256) {
        if (gridSize % 2 == 0) {
            return 0;
        }

        uint256 middleIndex = gridSize / 2;
        uint256 middleRowIndex = middleIndex * gridSize;
        uint256 middleColIndex = middleIndex;

        bool rowMatch = true;
        bool colMatch = true;
        bytes1 letter = letters[middleRowIndex + middleColIndex];

        for (uint256 i = 0; i < gridSize; i++) {
            if (letters[middleRowIndex + i] != letter) {
                rowMatch = false;
            }
            if (letters[i * gridSize + middleColIndex] != letter) {
                colMatch = false;
            }
        }

        uint256 count = 0;
        if (rowMatch && colMatch) {
            count++;
        }

        return count;
    }

function coundDiagonals(bytes memory letters, uint256 gridSize) internal pure returns (uint256 diagonalCount) {
    uint256 numRows = gridSize;
    uint256 numCols = gridSize;
    diagonalCount = 0;

    bool diagonalMatch1 = true;
    for (uint256 i = 1; i < numRows; i++) {
        uint256 index1 = i * numCols + i;
        uint256 index2 = (i - 1) * numCols + i - 1;

        bytes1 val1;
        bytes1 val2;

        assembly {
            val1 := mload(add(add(letters, 32), mul(index1, 1)))
            val2 := mload(add(add(letters, 32), mul(index2, 1)))
        }

        if (val1 != val2) {
            diagonalMatch1 = false;
            break;
        }
    }

    if (diagonalMatch1) {
        diagonalCount = 1;
    }

    bool diagonalMatch2 = true;
    for (uint256 i = 1; i < numRows; i++) {
        uint256 index1 = i * numCols + (numCols - i - 1);
        uint256 index2 = (i - 1) * numCols + (numCols - i);

        bytes1 val1;
        bytes1 val2;

        assembly {
            val1 := mload(add(add(letters, 32), mul(index1, 1)))
            val2 := mload(add(add(letters, 32), mul(index2, 1)))
        }

        if (val1 != val2) {
            diagonalMatch2 = false;
            break;
        }
    }

    if (diagonalMatch2) {
        diagonalCount += 1;
    }
}

  mapping (uint => SpecialPatternValues) _patternValues;

  function setPatternsValues(SpecialPatternValues[6] memory _pats) public onlyOwner {
    uint8[6] memory _arr = [2,3,4,5,6,7];
    for (uint8 i = 0; i < _arr.length; i++) {
      _patternValues[_arr[i]] = SpecialPatternValues(_pats[i]._sType,_pats[i]._sValue);
    }
  }

  function getSpecialPattern(uint _gridD) public view returns (SpecialPatternValues memory)  {
    return _patternValues[_gridD];
  }

  function countAll(bytes memory letters, uint256 gridDimension) public view returns (string memory pattern) {
    uint cols = countCols(letters, gridDimension);
    uint rows = countRows(letters, gridDimension);
    uint diags = coundDiagonals(letters, gridDimension);
    uint plus = isPlus(letters, gridDimension);

    // Write these and test OS deployment of SVG+GSAP

    if (cols == gridDimension && rows == gridDimension) {
        SpecialPatternValues memory _pData = getSpecialPattern(gridDimension);
        if (bytes(_pData._sType).length > 0) {
          if (gridDimension == 7) {
              pattern = string(abi.encodePacked(pattern, trait(_pData._sType, _pData._sValue, ', ')));
          } else {
              pattern = string(abi.encodePacked(pattern, trait(_pData._sType, _pData._sValue, ', ')));
              pattern = string(abi.encodePacked(pattern, trait('Cloning', 'Activated', ', ')));
          }
        }
    } 
    if (cols > 0) {
    pattern = string(abi.encodePacked(pattern, trait('Columns Count', GRDSLib.toString(cols), ', ')));
    }
    if (rows > 0) {
    pattern = string(abi.encodePacked(pattern, trait('Rows Count', GRDSLib.toString(rows), ', ')));
    }
    if (diags == 1) {
    pattern = string(abi.encodePacked(pattern, trait('Diagonal', GRDSLib.toString(1), ', ')));
    }
    if (diags == 2) {
    pattern = string(abi.encodePacked(pattern, trait('Diagonal', GRDSLib.toString(2), ', ')));
    pattern = string(abi.encodePacked(pattern, trait('X Pattern', GRDSLib.toString(1), ', ')));
    }
    if (plus > 0) {
    pattern = string(abi.encodePacked(pattern, trait('Plus Pattern', GRDSLib.toString(1), ', ')));
    }

  }

 function stringsToBytes(string[] memory _inputs) internal pure returns (bytes memory) {
        string memory _input;
        for (uint i = 0; i < _inputs.length; i++) {
            _input = string(abi.encodePacked(_input, _inputs[i]));
        }
        return abi.encodePacked(_input);
  }

    function trait(
        string memory traitType, string memory traitValue, string memory append
    ) public pure returns (string memory) {
        return string(abi.encodePacked(
            '{',
                '"trait_type": "', traitType, '",'
                '"value": "', traitValue, '"'
            '}',
            append
        ));
    }
}