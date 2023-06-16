// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "base64-sol/base64.sol";
import "hardhat/console.sol";


/**
 * @title Collective Canvas contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract CollectiveCanvas is ERC721, Ownable {

    enum ValidationState {
      LOOKING_FOR_OPEN_TAG_OPEN_BRACKET,
      LOOKING_FOR_OPEN_TAG_CLOSE_BRACKET,
      LOOKING_FOR_OPEN_TAG_CLOSE_BRACKET_EXCLUSIVE,
      LOOKING_FOR_CLOSE_TAG_OPEN_BRACKET,
      LOOKING_FOR_CLOSE_TAG_SLASH,
      LOOKING_FOR_CLOSE_TAG_CLOSE_BRACKET,
      LOOKING_FOR_CLOSE_QUOTE
    }

    struct ValidationStackFrame {
      ValidationState state;
      uint            index;
    }

    struct TokenMetadata {
      address creator;
      uint256 timestamp;
      uint256 funded;
      uint256 withdrawn;
    }

    uint256 public basePrice;

    bytes[] private _layers;

    mapping(uint256 => TokenMetadata) private _tokenMetadata;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
      basePrice = 24000000000000000; //0.024 ETH
    }

    function mint(bytes memory layer) public payable returns (uint256) {
      require(currentPriceToMint() <= msg.value, "Eth value sent is not sufficient");
      
      _validateLayer(layer);

      uint mintIndex = _layers.length;
      _layers.push(layer);

      _safeMint(msg.sender, mintIndex);
      _tokenMetadata[mintIndex] = TokenMetadata({creator: msg.sender, 
                                                 timestamp: block.timestamp, 
                                                 funded: msg.value, 
                                                 withdrawn: 0});

      return mintIndex;
    }

    function balanceOfToken(uint256 tokenId) public view returns (uint256) {
      require(_exists(tokenId), "Query for nonexistent token");

      uint256 balance = 0;

      for (uint256 i=tokenId;i<_layers.length;i++) {
        balance += (_tokenMetadata[i].funded / (i + 1));
      }

      return balance - _tokenMetadata[tokenId].withdrawn;
    }

    function totalFunded() public view returns (uint256) {
      uint256 result = 0;

      for (uint256 i=0;i<_layers.length;i++) {
        result += _tokenMetadata[i].funded;
      }

      return result;
    }

    function withdraw(uint256 tokenId, uint256 amount) public {
      uint256 balance = balanceOfToken(tokenId);
      require(balance >= amount, "Attempt to withdraw more than balance");
      require(ownerOf(tokenId) == msg.sender, "Unauthorized attempt to withdraw");

      TokenMetadata storage metadata = _tokenMetadata[tokenId];
      metadata.withdrawn += amount;

      _tokenMetadata[tokenId] = metadata;
      payable(msg.sender).transfer(amount);
    }

    function currentPriceToMint() public view returns (uint256) {
      return basePrice * ((_layers.length / 10) + 1);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

      string memory svgUri  = _encodeSvgUriAtTokenId(_layers.length-1);
      string memory json    = Base64.encode(abi.encodePacked('{"name":"Autonomous Art #', Strings.toString(tokenId), '","image":"', svgUri, '"}'));
      string memory jsonUri = string(abi.encodePacked("data:application/json;base64,", json));

      return jsonUri;
    }

    function layerCount() public view returns (uint256) {
      return _layers.length;
    }

    function historicalImageAt(uint256 tokenId) public view returns (string memory) {
      require(_exists(tokenId), "Query for nonexistent token");

      return _encodeSvgUriAtTokenId(tokenId);
    }

    function creatorAt(uint256 tokenId) public view returns (address) {
      require(_exists(tokenId), "Query for nonexistent token");

      return _tokenMetadata[tokenId].creator;
    }

    function timestampAt(uint256 tokenId) public view returns (uint256) {
      require(_exists(tokenId), "Query for nonexistent token");

      return _tokenMetadata[tokenId].timestamp;
    }

    function setBasePrice(uint256 updatedBasePrice) public onlyOwner {
      basePrice = updatedBasePrice;
    } 

    function _encodeSvgUriAtTokenId(uint256 tokenId) private view returns (string memory) {
      return string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(_encodeSvgAtTokenId(tokenId))));
    }

    function _encodeSvgAtTokenId(uint256 tokenId) private view returns (bytes memory) {
        bytes memory svg        = '<svg viewBox="0 0 500 500" xmlns="http://www.w3.org/2000/svg">';
        uint         layerIndex = 0;

        for (layerIndex = 0 ; layerIndex < tokenId+1; layerIndex++) {
          svg = abi.encodePacked(svg, '<g>', _layers[layerIndex], '</g>');
        }

        svg = abi.encodePacked(svg, '</svg>');

        return svg;
    }

    function _validateLayer(bytes memory layer) public pure {
      ValidationStackFrame[] memory stack = new ValidationStackFrame[](10);
      uint16                        index = 0;

      stack[0] = ValidationStackFrame({state: ValidationState.LOOKING_FOR_OPEN_TAG_OPEN_BRACKET, index: 0});

      for (uint i=0;i<layer.length;i++) {
        if (stack[index].state == ValidationState.LOOKING_FOR_OPEN_TAG_OPEN_BRACKET) {
          require(layer[i] == 0x3c, "Expecting '<'");
          require(index + 1 < stack.length, "Stack space exceeded");
          stack[++index] = ValidationStackFrame({state: ValidationState.LOOKING_FOR_OPEN_TAG_CLOSE_BRACKET, index: i+1});
        } else if (stack[index].state == ValidationState.LOOKING_FOR_OPEN_TAG_CLOSE_BRACKET) {
          if (layer[i] == 0x2f) { // '/'
            stack[index] = ValidationStackFrame({state: ValidationState.LOOKING_FOR_OPEN_TAG_CLOSE_BRACKET_EXCLUSIVE, index: i});
          } else if (layer[i] == 0x22) { // '"'
            require(index + 1 < stack.length, "Stack space exceeded");
            stack[++index] = ValidationStackFrame({state: ValidationState.LOOKING_FOR_CLOSE_QUOTE, index: i});
          } else if (layer[i] == 0x3e) { // '>'
            stack[index] = ValidationStackFrame({state: ValidationState.LOOKING_FOR_CLOSE_TAG_OPEN_BRACKET, index: stack[index].index});
          } else {
            require((layer[i] >= 0x30 && layer[i] <= 0x39) || (layer[i] >= 0x41 && layer[i] <= 0x7a) || (layer[i] == 0x3d) || (layer[i] == 0x20) || (layer[i] == 0x2d), string(abi.encodePacked("Expecting '0-9', 'a-zA-Z', '=', '-', or ' ' but got: ", layer[i])));
          }
        } else if (stack[index].state == ValidationState.LOOKING_FOR_OPEN_TAG_CLOSE_BRACKET_EXCLUSIVE) {
          require(layer[i] == 0x3e, "Expecting '>'");
          index--;
        } else if (stack[index].state == ValidationState.LOOKING_FOR_CLOSE_TAG_OPEN_BRACKET) {
          require(layer[i] == 0x3c, "Expecting '<'");
          stack[index] = ValidationStackFrame({state: ValidationState.LOOKING_FOR_CLOSE_TAG_SLASH, index: stack[index].index});
        } else if (stack[index].state == ValidationState.LOOKING_FOR_CLOSE_TAG_SLASH) {
          if (layer[i] == 0x2f) { // '/'
            stack[index] = ValidationStackFrame({state: ValidationState.LOOKING_FOR_CLOSE_TAG_CLOSE_BRACKET, index: i + 1 - stack[index].index});
          } else {
            require((layer[i] >= 0x41 && layer[i] <= 0x7a), "Expecting a-zA-Z");
            require(index + 1 < stack.length, "Stack space exceeded");
            stack[index]   = ValidationStackFrame({state: ValidationState.LOOKING_FOR_CLOSE_TAG_OPEN_BRACKET, index: stack[index].index});
            stack[++index] = ValidationStackFrame({state: ValidationState.LOOKING_FOR_OPEN_TAG_CLOSE_BRACKET, index: i});
          }
        } else if (stack[index].state == ValidationState.LOOKING_FOR_CLOSE_TAG_CLOSE_BRACKET) {
          if (layer[i] == 0x3e) { // '>'
            index--;
          } else {
            require(layer[i] == layer[i - stack[index].index], string(abi.encodePacked("Expecting a-zA-Z to match: ", layer[i - stack[index].index])));
          }
        } else if (stack[index].state == ValidationState.LOOKING_FOR_CLOSE_QUOTE) {
          if (layer[i] == 0x22) { // '"'
            index--; 
          } else {
            require((layer[i] >= 0x20 && layer[i] <= 0x7e), string(abi.encodePacked("Expecting ascii 0x20-0x7e, but got: ", layer[i])));
          }
        }
      }

      require(index == 0, "Invalid layer, ended with non-zero index");
    }
}