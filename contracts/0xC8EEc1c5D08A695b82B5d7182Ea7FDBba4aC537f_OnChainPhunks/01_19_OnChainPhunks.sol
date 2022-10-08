// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Strings.sol";

interface CryptopunksData {
  function punkImageSvg(uint16 index) external view returns (string memory svg);
  function punkAttributes(uint16 index) external view returns (string memory attributes);
}

contract OnChainPhunks is ERC721, ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using strings for *;

    /// @notice The maximum number of On-Chain Phunks available for minting.
    uint256 public constant MAX_TOKENS = 10000;

    /// @notice The maximum number of On-Chain Phunks that can be minted at a time.
    uint256 public constant MAX_TOKENS_PER_PURCHASE = 1;

    /// @notice The cost of one On-Chain Phunk.
    uint256 private price = 55555555555555555; // 0.055555555555555555 Ether

    /// @notice The contract address of the original CryptopunksData.
    address public renderingContractAddress;

    /// @notice A randomly selected punk from the CryptopunksData contract.
    uint16[10000] private assignedPunk;

    /// @notice A count of the total number of available punks.
    uint16[10001] private availablePunks;

    /// @notice The description for an On-Chain Phunk.
    string[10000] private description;

    /**
     * @notice A six character hex color code for the top color of a gradient background.
     * To get a single color background set the same value for the second color.
     */
    string[10000] private firstColor;

    /**
     * @notice A six character hex color code for the bottom color of a gradient background.
     * To get a single color background set the same value for the first color.
     */
    string[10000] private secondColor;

    constructor() ERC721("OnChainPhunks", "ONCHAINPHUNKS") Ownable() {}

    /// @notice Generate a random color hex code value using current blockchain details.
    /// @param number Any arbitrary number selected as an input value. 
    /// @return A six character string usable as a gradient or background color hex code value.
    /// @dev Uses keccak256 hash of "you create you".
    function bottomGradient(uint256 number) external view returns (string memory) {
      string[32] memory r;
      string[32] memory s = ["7", "4", "c", "5", "2", "b", "d", "6", "0", "f", "e", "3", "8", "a", "1", "9", "4", "0", "b", "f", "1", "e", "d", "a", "3", "7", "c", "9", "2", "6", "5", "8"];

      uint l = s.length;
      uint i;
      string memory t;

      while (l > 0) {
          uint256 v = random(string(abi.encodePacked("96c8d88e6b901a0ab86e8df79de15c9e2677af5ee97a8ad288119a61b2707893", block.timestamp, block.difficulty, toString(number))));
          i = v % l--;
          t = s[l];
          s[l] = s[i];
          s[i] = t;
      }

      r = s;

      string memory j = string(abi.encodePacked(r[13],r[16],r[8],r[6],r[0],r[2]));

      return j;
    }

    /// @notice The description given to an On-Chain Phunk at mint.
    /// @param tokenId The tokenId for which to retrieve a description.
    /// @return A description for the On-Chain Phunk as a string.
    function getDescription(uint256 tokenId) external view returns (string memory) {
        require(tokenId >= 0 && tokenId < 10000);
        string memory d = description[tokenId];
        return d;
    }

    /// @notice Get the current price of an On-Chain Phunk.
    /// @return The price of an On-Chain Phunk in Wei.
    function getPrice() external view returns (uint256) {
        return price;
    }

    /// @notice Get the base svg for any created On-Chain Phunk.
    /// @param tokenId The tokenId for which an svg is to be retrieved.
    /// @return The svg for an On-Chain Phunk returned as a string.
    function getSvg(uint256 tokenId) external view returns (string memory) {
        require(tokenId >= 0 && tokenId < 10000);
        string[7] memory g;

        g[0] = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.2" viewBox="0 0 600 600" style="-moz-transform: scaleX(-1); -o-transform: scaleX(-1); -webkit-transform: scaleX(-1); transform: scaleX(-1);"><defs><linearGradient id="backgroundGradient" x1="0" x2="0" y1="0" y2="1"><stop offset="0%" stop-color="#';

        g[1] = firstColor[tokenId];

        g[2] = '"/><stop offset="100%" stop-color="#';

        g[3] = secondColor[tokenId];

        g[4] = '"/></linearGradient></defs><rect viewBox="0 0 600 600" width="600" height="600" fill="url(#backgroundGradient)" />';

        g[5] = getPlain(tokenId);

        g[6] = '</svg>';

        string memory k = string(abi.encodePacked(g[0], g[1], g[2], g[3], g[4], g[5], g[6]));

        return k;
    }

    /// @notice Get the On-Chain Phunk traits combined with the original CryptoPunk attributes.
    /// @param tokenId The tokenId for which traits are being retrieved.
    /// @return A json string with the traits of an On-Chain Phunk.
    function getTraits(uint256 tokenId) external view returns (string memory) {
        require(tokenId >= 0 && tokenId < 10000);
        string[5] memory traits;
        string memory originalPunk = toString(assignedPunk[tokenId]);

        traits[0] = string(abi.encodePacked('{"trait_type":"First Color #","value":"', firstColor[tokenId], '"}'));
        traits[1] = string(abi.encodePacked('{"trait_type":"Second Color #","value":"', secondColor[tokenId], '"}'));
        traits[2] = string(abi.encodePacked('{"trait_type":"Original Punk #","value":"', originalPunk, '"}'));
        traits[3] = string(abi.encodePacked(getAttributes(tokenId)));
        traits[4] = string(abi.encodePacked('{"trait_type":"Description","value":"', description[tokenId], '"}'));

        string memory w = string(abi.encodePacked(traits[0], ',', traits[1], ',', traits[2], ',', traits[3], ',', traits[4]));

        return w;
    }

    /// @notice Sets the contract address for the CryptopunksData contract.
    /// @param _renderingContractAddress The address for the CryptopunksData contract.
    function setRenderingContractAddress(address _renderingContractAddress) external onlyOwner {
        renderingContractAddress = _renderingContractAddress;
    }

    /// @notice Enter your wallet address to see which On-Chain Phunks you own.
    /// @param _owner The wallet address of an On-Chain Phunk owner.
    /// @return An array of tokenIds of the On-Chain Phunks owned by the address.
    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = this.tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    /// @notice Generate a random color hex code value using current blockchain details.
    /// @param number Any arbitrary number selected as an input value.
    /// @return A six character string usable as a gradient or background color hex code value.
    /// @dev Uses keccak256 hash of "time is only now".
    function topGradient(uint256 number) external view returns (string memory) {
      string[32] memory r;
      string[32] memory s = ["a", "3", "4", "1", "e", "7", "5", "9", "b", "d", "2", "8", "f", "0", "c", "6", "2", "8", "e", "3", "9", "6", "0", "b", "5", "d", "f", "4", "a", "1", "7", "c"];

      uint l = s.length;
      uint i;
      string memory t;

      while (l > 0) {
          uint256 v = random(string(abi.encodePacked("40f27b0db601f225eb5a4d3a8082fb02afb72b4aeb7eec29e8bac021ca3a20b5", block.timestamp, block.difficulty, toString(number))));
          i = v % l--;
          t = s[l];
          s[l] = s[i];
          s[i] = t;
      }

      r = s;

      string memory j = string(abi.encodePacked(r[3],r[17],r[1],r[14],r[9],r[12]));

      return j;
    }

    /// @notice Mint an On-Chain Phunk.
    /// @param _count The number of On-Chain Phunks to mint.
    /// @param first The first hex color code value.
    /// @param second The second hex color code value.
    /// @param text The text to be used as a description.
    function mint(
        uint256 _count,
        string memory first,
        string memory second,
        string memory text
      ) public
        payable
        nonReentrant
    {
        uint256 totalSupply = this.totalSupply();
        require(_count > 0 && _count < MAX_TOKENS_PER_PURCHASE + 1);
        require(totalSupply + _count < MAX_TOKENS + 1);
        require(msg.value >= price.mul(_count));

        for (uint256 i = 0; i < _count; i++) {
            _safeMint(msg.sender, totalSupply + i);
            assignedPunk[totalSupply + i] = randomPunk(totalSupply + 1);
            firstColor[totalSupply + i] = first;
            secondColor[totalSupply + i] = second;
            description[totalSupply + i] = text;
        }
    }

      /// @notice The owner of the On-Chain Phunks contract can pause transactions.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice The On-Chain Phunks contract owner can change the mint price.
    /// @param _newPrice The new price to be set for an On-Chain Phunk.
    function setPrice(uint256 _newPrice) public onlyOwner() {
        price = _newPrice;
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

    /// @notice The owner of the On-Chain Phunks contract can resume transactions.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice The On-Chain Phunk contract owner can withdraw ETH accumulated in the contract.
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    /// @notice Generate a random value used to select an original CryptoPunk.
    /// @param tokenId The current tokenId being minted.
    /// @return An integer value used to select an original CryptoPunk.
    /// @dev Using keccak256 hash of the work "punk" and the following implementation: https://www.justinsilver.com/technology/cryptocurrency/nft-mint-random-token-id/
    function randomPunk(uint256 tokenId) public returns (uint16) {
        uint256 currentLength = availablePunks.length - tokenId;
        require(currentLength > 0, 'No punks available.');
        uint256 v = uint(keccak256(abi.encodePacked("4c71ce6ba2ee0cfaa5acee977e8e67e2cd9b456dcdf1ab291519d32de27f4ece", block.timestamp, block.difficulty, toString(tokenId)))) % currentLength;
        uint16 originalPunk = uint16(availablePunks[v] != 0 ? availablePunks[v] : v);
        availablePunks[v] = uint16(availablePunks[currentLength - 1] == 0 ? currentLength - 1 : availablePunks[currentLength - 1]);
        availablePunks[currentLength - 1] = 0;
        return originalPunk;
    }

    /// @notice Generate the tokenURI for each On-Chain Phunk.
    /// @param tokenId The tokenId of an On-Chain Phunk used to select stored values and generate attributes.
    /// @return A base64 encoded string representing an On-Chain Phunk.
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[7] memory p;

        p[0] = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.2" viewBox="0 0 600 600" style="-moz-transform: scaleX(-1); -o-transform: scaleX(-1); -webkit-transform: scaleX(-1); transform: scaleX(-1);"><defs><linearGradient id="backgroundGradient" x1="0" x2="0" y1="0" y2="1"><stop offset="0%" stop-color="#';

        p[1] = firstColor[tokenId];

        p[2] = '"/><stop offset="100%" stop-color="#';

        p[3] = secondColor[tokenId];

        p[4] = '"/></linearGradient></defs><rect viewBox="0 0 600 600" width="600" height="600" fill="url(#backgroundGradient)" />';

        p[5] = getPlain(tokenId);

        p[6] = '</svg>';

        string memory o = string(abi.encodePacked(p[0], p[1], p[2], p[3], p[4], p[5], p[6]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Item #', toString(tokenId), '", "description": "', description[tokenId], '", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(o)), '", "attributes": \x5B ', makeAttributes(tokenId), ' \x5D}'))));
        o = string(abi.encodePacked('data:application/json;base64,', json));

        return o;
    }

    /// @dev Required override for ERC721Enumerable.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @notice Get and modify the attributes of an original CryptoPunk.
    /// @param tokenId The tokenId value used to retrieve the assigned CryptoPunk.
    /// @return A json string with the modified CryptoPunk attributes.
    function getAttributes(uint256 tokenId) private view returns (string memory) {
        CryptopunksData cryptopunksData = CryptopunksData(renderingContractAddress);

        uint16 t = assignedPunk[tokenId];

        string memory attributes = cryptopunksData.punkAttributes(t);

        strings.slice memory sliceAttributes = attributes.toSlice();
        strings.slice memory delim = ",".toSlice();
        string[] memory parts = new string[](sliceAttributes.count(delim) + 1);

        for (uint i = 0; i < parts.length; i++) {
            parts[i] = sliceAttributes.split(delim).beyond(" ".toSlice()).toString();
        }

        string memory attr;

        for (uint i = 0; i < parts.length; i++) {
            attr = string(abi.encodePacked(attr, '{'));
            if (i == 0) {
                attr = string(abi.encodePacked(attr, '"trait_type": "Type",'));
            } else {
                attr = string(abi.encodePacked(attr, '"trait_type": "Attribute",'));
            }
            attr = string(abi.encodePacked(attr, '"value": "', parts[i], '"'));
            if (i == parts.length - 1) {
                attr = string(abi.encodePacked(attr, '}'));
            } else {
                attr = string(abi.encodePacked(attr, '},'));
            }
        }

        return attr;
    }

    /// @notice Retrieve svg values of a CryptoPunk while trimming unused values.
    /// @param tokenId The tokenId value used to retrieve the assigned CryptoPunk.
    /// @return A string containing the svg representation of an original CryptoPunk.
    function getPlain(uint256 tokenId) private view returns (string memory) {
        CryptopunksData cryptopunksData = CryptopunksData(renderingContractAddress); // Running

        uint16 t = assignedPunk[tokenId];

        string memory punkSvg = cryptopunksData.punkImageSvg(t); // Running
        strings.slice memory slicedSvg = punkSvg.toSlice().beyond('data:image/svg+xml;utf8,'.toSlice());
        punkSvg = slicedSvg.toString();

        return punkSvg;
    }

    /// @notice Combine On-Chain Phunk attributes with original CryptoPunk attributes.
    /// @param tokenId The tokenId for which attributes are being generated.
    /// @return A json string with the combined attributes for an On-Chain Phunk.
    function makeAttributes(uint256 tokenId) private view returns (string memory) {
        string[5] memory traits;
        string memory originalPunk = toString(assignedPunk[tokenId]);

        traits[0] = string(abi.encodePacked('{"trait_type":"First Color #","value":"', firstColor[tokenId], '"}'));
        traits[1] = string(abi.encodePacked('{"trait_type":"Second Color #","value":"', secondColor[tokenId], '"}'));
        traits[2] = string(abi.encodePacked('{"trait_type":"Original Punk #","value":"', originalPunk, '"}'));
        traits[3] = string(abi.encodePacked(getAttributes(tokenId)));
        traits[4] = string(abi.encodePacked('{"trait_type":"Description","value":"', description[tokenId], '"}'));

        string memory attributes = string(abi.encodePacked(traits[0], ',', traits[1], ',', traits[2], ',', traits[3], ',', traits[4]));

        return attributes;
    }

    /// @notice A basic random value generator not using an oracle but sufficient for use.
    /// @param input A string value inputted to generate the random output.
    /// @return An integer value randomly generated using keccak256.
    function random(string memory input) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    /// @dev Utility function.
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
    function toString(uint256 value) private pure returns (string memory) {
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

}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64.
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