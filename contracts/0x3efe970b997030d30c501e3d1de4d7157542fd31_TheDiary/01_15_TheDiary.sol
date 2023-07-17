// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TheDiary is ERC721, ReentrancyGuard, Ownable, ERC721Enumerable {
  using SafeMath for uint256;
  using Strings for uint256;

  // maps tokenId to diary
  mapping (uint256 => string) internal _diaries;
  uint256 public initPrice = 0.1 ether;
  uint256 public deployTs;
  uint256 public lastAuctionDay;
  constructor() ERC721("The Diary", "DIARY") {
    uint256 _now = block.timestamp;
    deployTs = _now.sub(_now.mod(86400));
    lastAuctionDay = deployTs;
  }

  // Unix timestamp of the day in epoch seconds (UTC)
  function mint(uint256 epochSeconds, string memory message) external nonReentrant payable {
    uint256 _now = block.timestamp;
    uint256 requestedDay = epochSeconds.sub(epochSeconds.mod(86400));
    uint256 today = _now.sub(_now.mod(86400));
    require(requestedDay <= today, "Future mint is not allowed");
    require(requestedDay >= deployTs, "Too old");
    require(!_exists(requestedDay), "Already minted");
    uint256 mintPice = initPrice;
    uint256 startPrice = initPrice;
    uint256 daysSinceLatestMint = (today.sub(lastAuctionDay)).div(86400);
    if(daysSinceLatestMint > 1 && startPrice > 0.1 ether){
      // previous days not sold, adapt the initial price
      for (uint256 i = 1; i < daysSinceLatestMint; i++) {
        startPrice = startPrice.div(2);
        if(startPrice < 0.1 ether) {
          startPrice = 0.1 ether;
          break;
        }
      }
    }
    uint256 _hours = (_now.sub(today)).div(3600);
    if(requestedDay < today) {
      // date is out of auction
      mintPice = startPrice.div(20);
    } else {
      mintPice = startPrice.sub(startPrice.div(25).mul(_hours));
      if(mintPice < startPrice.div(20)) {
        mintPice = startPrice.div(20);
      }
    }
    require( msg.value >= mintPice, "Not enough Ether to mint the token.");
    if(requestedDay == today) {
      initPrice = startPrice;
      if(mintPice == initPrice) {
        initPrice = initPrice.mul(2);
      } else if (_hours > 22) {
        initPrice = startPrice.div(2);
        if(initPrice < 0.1 ether) {
          initPrice = 0.1 ether;
        }
      }
      lastAuctionDay = today;
    }
    _diaries[requestedDay] = message;
    _safeMint(msg.sender, requestedDay);
    if (msg.value > mintPice) {
      payable(msg.sender).transfer(msg.value - mintPice);
    }
  }

  function getMintPrice(uint256 timestamp) public view returns (uint256) {
    uint256 _now = block.timestamp;
    uint256 requestedDay = timestamp.sub(timestamp.mod(86400));
    uint256 today = _now.sub(_now.mod(86400));
    require(requestedDay <= today, "Future mint is not allowed.");
    require(requestedDay >= deployTs, "Too old.");
    require(!_exists(requestedDay), "Already minted");
    uint256 mintPice = initPrice;
    uint256 startPrice = initPrice;
    uint256 daysSinceLatestMint = (today.sub(lastAuctionDay)).div(86400);
    if(daysSinceLatestMint > 1 && startPrice > 0.1 ether){
      // not sold, adapt the initial price
      for (uint256 i = 1; i < daysSinceLatestMint; i++) {
        startPrice = startPrice.div(2);
        if(startPrice < 0.1 ether) {
          startPrice = 0.1 ether;
          break;
        }
      }
    }
    uint256 _hours = (_now.sub(today)).div(3600);
    if(requestedDay < today) {
      // date is out of auction
      mintPice = startPrice.div(20);
    } else {
      mintPice = startPrice.sub(startPrice.div(25).mul(_hours));
      if(mintPice < startPrice.div(20)) {
        mintPice = startPrice.div(20);
      }
    }
    return mintPice;
  }

  function getTokenIdByTimestamp(uint256 timestamp) public pure returns(uint256){
    return timestamp.sub(timestamp.mod(86400));
  }

  function getDiaryByTimestamp(uint256 timestamp) public view returns(string memory){
    uint256 _ts = timestamp.sub(timestamp.mod(86400));
    require(_exists(_ts), "not exists");
    return _diaries[_ts];
  }


  function getDiary(uint256 tokenId) public view returns(string memory){
    require(_exists(tokenId), "not exists");
    return _diaries[tokenId];
  }

  function tokenURI(uint256 tokenId) public override view returns(string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
      string memory _diary = _diaries[tokenId];
      uint256 _time = tokenId;
      uint256 _day = (_time.sub(deployTs)).div(86400);
      // starts from zero
      _day = _day.add(1);
      string memory message =  string(abi.encodePacked(_diary));
      message = normalize(message);
      string memory part1 = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: black; font-family: serif; font-size: 14px; }</style>';
      string memory part2 = string(abi.encodePacked('<rect width="100%" height="100%" fill="white" /><foreignObject width="350" height="350" requiredExtensions="http://www.w3.org/1999/xhtml"><body xmlns="http://www.w3.org/1999/xhtml"><div style="overflow: auto; padding: 0;margin: 0;line-height: 1.5;color:#333;">', message,'</div></body></foreignObject>'));
      string memory part3 = '</svg>';
      string memory output = Base64.encode(bytes(string(abi.encodePacked(part1, part2, part3))));
      string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Day ', _day.toString(), '", "description": "Only one diary per day can be minted. Future mint is not allowed. Timestamp is the midnight timestamp of the given date at 00:00:00 in UTC standard (Universal Time Coordinated) which is also used as the token id.", "image": "data:image/svg+xml;base64,', output, '"}'))));
      output = string(abi.encodePacked('data:application/json;base64,', json));
      return output;
  }

  function normalize(string memory str) internal pure returns(string memory) {
    bytes memory strBytes = bytes(str);
    bytes1 char;
    uint8 charCode;
    string memory message ='';
    for (uint256 i; i < strBytes.length; i++) {
        char = strBytes[i];
        charCode = uint8(char);
        if (charCode == 38) {
          message =  string(abi.encodePacked(message, '&amp;')); // &
        } else if (charCode == 60) {
          message =  string(abi.encodePacked(message, '&lt;')); // <
        } else if (charCode == 62) {
          message =  string(abi.encodePacked(message, '&gt;')); // >
        } else if (charCode == 42) {
          message =  string(abi.encodePacked(message, '&quot;')); // '
        } else if (charCode == 47) {
          message =  string(abi.encodePacked(message, '&#x27;')); // "
        } else {
          message =  string(abi.encodePacked(message, char));
        }
    }
    return message;
  }

  function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
       super._beforeTokenTransfer(from, to, tokenId);
   }

   function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
       return super.supportsInterface(interfaceId);
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