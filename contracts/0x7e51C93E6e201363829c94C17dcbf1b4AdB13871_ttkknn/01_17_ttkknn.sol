// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title ttkknn mint contract.
/// @author 67ac2b3e1a1f71cdf69d11eb2baf93ad284264f20087ffc2866cfce01204fe91
/// @notice ttkknns are a general use token.
contract ttkknn is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    /// @notice The maximum number of ttkknns available for minting.
    uint256 public constant MAX_TOKENS = 100000;

    /// @notice The maximum number of ttkknns that can be purchased per transaction.
    uint256 public constant MAX_TOKENS_PER_PURCHASE = 1;

    constructor() ERC721("ttkknn", "ttkknn") Ownable() {}

    /// @notice Mint a ttkknn.
    /// @param _count How many ttkknns you would like to mint.
    function mint(uint256 _count) public nonReentrant {
        uint256 totalSupply = totalSupply();
        require(_count > 0 && _count < MAX_TOKENS_PER_PURCHASE + 1);
        require(totalSupply + _count < MAX_TOKENS + 1);
        for(uint256 i = 0; i < _count; i++){
            _safeMint(msg.sender, totalSupply + i);
        }
    }

    /// @dev Required override for ERC721Enumerable.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Enter your wallet address to see which ttkknns you own.
    /// @param _owner The wallet address of a ttkknn token owner.
    /// @return An array of the ttkknn tokenIds owned by the address.
    function tokensByOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    /// @notice Generates the tokenURI for each ttkknn.
    /// @param tokenId The ttkknn token for which a URI is to be generated.
    /// @return The tokenURI formatted as a string.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string[7] memory p;

        p[0] = '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" preserveAspectRatio="xMidYMid meet" viewBox="0 0 700 700"><rect width="700" height="700" fill="#';
        p[1] = shuffleBackground(tokenId);
        p[2] = '"></rect><rect x="340" y="340" width="10" height="10" fill="#';
        p[3] = shuffleLeftSquare(tokenId);
        p[4] = '"></rect><rect x="350" y="340" width="10" height="10" fill="#';
        p[5] = shuffleRightSquare(tokenId);
        p[6] = '"></rect></svg>';

        string memory o = string(abi.encodePacked(p[0], p[1], p[2], p[3], p[4], p[5], p[6]));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "ttkknn #', toString(tokenId), '", "description": "A general use token.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(o)), '", "attributes": \x5B ', makeAttributes(tokenId), ' \x5D}'))));
        o = string(abi.encodePacked('data:application/json;base64,', json));
        return o;
    }

    /// @dev Required override for ERC721Enumerable.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @notice Returns an integer value as a string.
    /// @param value The integer value to have a type change.
    /// @return A string of the inputted integer value.
    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        if (value == 0) {
            return "0";
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

    /// @notice A general random function to be used to shuffle and generate values.
    /// @param input Any string value to be randomized.
    /// @return The output of a random hash using keccak256.
    function random(string memory input) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    /// @notice A shuffle function to output a random hex string for the left square color.
    /// @param tokenId The tokenId for which a left square color value is to be generated.
    /// @return A string providing a hex color value.
    function shuffleLeftSquare(uint256 tokenId) private view returns (string memory) {
      string[32] memory r;
      string[32] memory s = ["a", "3", "4", "1", "e", "7", "5", "9", "b", "d", "2", "8", "f", "0", "c", "6", "2", "8", "e", "3", "9", "6", "0", "b", "5", "d", "f", "4", "a", "1", "7", "c"];

      uint l = s.length;
      uint i;
      string memory t;

      while (l > 0) {
          uint256 v = random(string(abi.encodePacked("f9d20005acf7", block.timestamp, block.difficulty, msg.sender, toString(tokenId))));
          i = v % l--;
          t = s[l];
          s[l] = s[i];
          s[i] = t;
      }

      r = s;
      string memory j = string(abi.encodePacked(r[3],r[17],r[1],r[14],r[9],r[12]));
      return j;
    }

    /// @notice A shuffle function to output a random hex string for the right square color.
    /// @param tokenId The tokenId for which a right square color value is to be generated.
    /// @return A string providing a hex color value.
    function shuffleRightSquare(uint256 tokenId) private view returns (string memory) {
      string[32] memory r;
      string[32] memory s = ["7", "4", "c", "5", "2", "b", "d", "6", "0", "f", "e", "3", "8", "a", "1", "9", "4", "0", "b", "f", "1", "e", "d", "a", "3", "7", "c", "9", "2", "6", "5", "8"];

      uint l = s.length;
      uint i;
      string memory t;

      while (l > 0) {
          uint256 v = random(string(abi.encodePacked("9a2a23789155", block.timestamp, block.difficulty, msg.sender, toString(tokenId))));
          i = v % l--;
          t = s[l];
          s[l] = s[i];
          s[i] = t;
      }

      r = s;
      string memory j = string(abi.encodePacked(r[13],r[16],r[8],r[6],r[0],r[2]));
      return j;
    }

    /// @notice A shuffle function to output a random hex string for the background color.
    /// @param tokenId The tokenId for which a background color value is to be generated.
    /// @return A string providing a hex color value.
    function shuffleBackground(uint256 tokenId) private view returns (string memory) {
      string[32] memory r;
      string[32] memory s = ["1", "6", "3", "9", "c", "4", "b", "d", "e", "8", "5", "0", "a", "f", "2", "7", "b", "7", "5", "1", "8", "d", "2", "a", "6", "c", "4", "f", "9", "0", "e", "3"];

      uint l = s.length;
      uint i;
      string memory t;

      while (l > 0) {
          uint256 v = random(string(abi.encodePacked("f09ceaa019e6", block.timestamp, block.difficulty, msg.sender, toString(tokenId))));
          i = v % l--;
          t = s[l];
          s[l] = s[i];
          s[i] = t;
      }

      r = s;

      string memory m = r[16];
      string memory f = "f";
      string memory o = "0";
      string memory j;

      if (keccak256(bytes(m)) == keccak256(bytes(f))) {
          j = "ffffff";
      } else if (keccak256(bytes(m)) == keccak256(bytes(o))) {
          j = "000000";
      } else {
          j = string(abi.encodePacked(r[5],r[11],r[7],r[4],r[10],r[15]));
      }

      return j;
    }

    /// @notice Generate the attributes to be used for the token metadata.
    /// @param tokenId The token for which the metadata is to be generated.
    /// @return A string of the metadata for the token.
    function makeAttributes(uint256 tokenId) private view returns (string memory) {
        string[3] memory traits;

        traits[0] = string(abi.encodePacked('{"trait_type":"left:","value":"', shuffleLeftSquare(tokenId), '"}'));
        traits[1] = string(abi.encodePacked('{"trait_type":"right:","value":"', shuffleRightSquare(tokenId), '"}'));
        traits[2] = string(abi.encodePacked('{"trait_type":"background:","value":"', shuffleBackground(tokenId), '"}'));

        string memory attributes = string(abi.encodePacked(traits[0], ',', traits[1], ',', traits[2]));

        return attributes;
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