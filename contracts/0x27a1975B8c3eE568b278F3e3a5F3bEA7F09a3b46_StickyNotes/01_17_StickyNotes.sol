// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @custom:security-contact [email protected]
contract StickyNotes is ERC721, ERC721Enumerable, AccessControl, Ownable {
  using Counters for Counters.Counter;
  using Strings for uint256;
  Counters.Counter public tokenIdCounter;
  struct StickyData {
    string message;
    string color;
    bool isSBT;
    address creator;
  }
  uint256 public price = 0.005 ether;
  address public bank = 0x72B1202c820e4B2F8ac9573188B638866C7D9274;
  mapping(uint256 => StickyData) public stickies;
  string constant _SBTVG =
    "</tspan></text><g id='icon' transform='translate(574.587 48.134)'><path id='Path_1' data-name='Path 1' d='M21.5,6.68V5a5,5,0,0,0-5-5,5.277,5.277,0,0,0-4.91,5c-.021.022,0,1.485,0,1.9h2.076c0-.073-.054-1.523,0-1.9.059-1.078,1.295-2.923,2.834-2.923A2.927,2.927,0,0,1,19.426,5V6.68H9.884V16.851H23.121V6.68ZM17.329,13v2.233H15.677V13a1.462,1.462,0,1,1,1.652,0Z' transform='translate(-9.884)' fill='#ff7474'/></g></g><rect id='textBG' width='526' height='464' transform='translate(55 111)' fill='#fff' opacity='0.17'/></g>";
  string constant _NFTVG =
    "</tspan></text><g id='icon' transform='translate(574.587 48.134)'><g id='Mask_Group_1' data-name='Mask Group 1' clip-path='url(#clip-path)'><g id='Mask_Group_2' data-name='Mask Group 2' clip-path='url(#clip-path-2)'><path id='Path_1-3' data-name='Path 1' d='M21.5,6.68V5a5,5,0,0,0-5-5c-2.757,0-4.966.735-4.966,3.491H13.61c0-1.612,1.278-1.415,2.89-1.415A2.927,2.927,0,0,1,19.426,5V6.68H9.884V16.851H23.121V6.68ZM17.329,13v2.233H15.677V13a1.462,1.462,0,1,1,1.652,0Z' transform='translate(-9.884)' fill='#717171'/></g></g></g></g><rect id='textBG' width='526' height='464' transform='translate(55 111)' fill='#fff' opacity='0.17'/></g>";
  string constant _NFTTEXT =
    "'/></g><rect id='noteTop' width='563' height='48' transform='translate(37 35)' fill='#fff' opacity='0.263'/><g id='modeToggle'><text id='label' transform='translate(575 73)' font-size='6'><tspan x='0' y='0'>";
  string constant _SBTTEXT =
    "'/></g><rect id='noteTop' width='563' height='48' transform='translate(37 35)' fill='#fff' opacity='0.263'/><g id='modeToggle'><text id='label' transform='translate(575 73)' font-size='6' fill='#ff7474'><tspan x='0' y='0'>";

  constructor() ERC721("Sticky Notes", "Note") {
    _grantRole(DEFAULT_ADMIN_ROLE, 0xa126d74de3623734100F2c15F497F35D576FB0bf);
    _transferOwnership(0xE42E4F21A750C1cC1ba839E5B1e4EfC3eD1fe454);
  }

  function mint(
    address to,
    string calldata message,
    string calldata color,
    bool isSBT
  ) public payable {
    require(price == msg.value);
    uint256 tokenId = tokenIdCounter.current();
    stickies[tokenId].message = message;
    stickies[tokenId].isSBT = isSBT;
    stickies[tokenId].creator = msg.sender;
    stickies[tokenId].color = color;
    tokenIdCounter.increment();
    _mint(to, tokenId);
    (bool result, ) = payable(bank).call{ value: msg.value }("");
    require(result);
  }

  function setPrice(uint256 _price) public onlyRole(DEFAULT_ADMIN_ROLE) {
    price = _price;
  }

  function setBank(address _bank) public onlyRole(DEFAULT_ADMIN_ROLE) {
    bank = _bank;
  }

  function getSvg(uint256 tokenId) public view returns (string memory) {
    _requireMinted(tokenId);
    string memory message = stickies[tokenId].message;
    bool isSBT = stickies[tokenId].isSBT;
    string memory color = stickies[tokenId].color;
    string[7] memory parts;
    parts[
      0
    ] = "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' width='636' height='636' viewBox='0 0 636 636'><defs><filter id='noteBG' x='28' y='32' width='581' height='581' filterUnits='userSpaceOnUse'><feOffset dy='3' input='SourceAlpha'/><feGaussianBlur stdDeviation='3' result='blur'/><feFlood flood-opacity='0.161'/><feComposite operator='in' in2='blur'/><feComposite in='SourceGraphic'/></filter><clipPath id='clip-path'><path id='Path_1' data-name='Path 1' d='M21.5,6.68V5a5,5,0,0,0-5-5,5.277,5.277,0,0,0-4.91,5c-.021.022,0,1.485,0,1.9h2.076c0-.073-.054-1.523,0-1.9.059-1.078,1.295-2.923,2.834-2.923A2.927,2.927,0,0,1,19.426,5V6.68H9.884V16.851H23.121V6.68ZM17.329,13v2.233H15.677V13a1.462,1.462,0,1,1,1.652,0Z' transform='translate(-9.884)' fill='#ff7474'/></clipPath><clipPath id='clip-path-2'><path id='Path_1-2' data-name='Path 1' d='M21.5,6.68V5a5,5,0,0,0-5-5,5.277,5.277,0,0,0-4.91,5c-.021.022,0,1.485,0,1.9h2.076c0-.073-.054-1.523,0-1.9.059-1.078,1.3-2.923,2.834-2.923A2.927,2.927,0,0,1,19.426,5V6.68H9.884V16.851H23.121V6.68ZM17.329,13v2.233H15.677V13a1.462,1.462,0,1,1,1.652,0Z' transform='translate(-9.884)' fill='#ff7474'/></clipPath><clipPath id='clip-NFT'><rect width='636' height='636'/></clipPath></defs><g id='NFT' clip-path='url(#clip-NFT)'><rect width='636' height='636' fill='#f5f5f5'/><g transform='matrix(1, 0, 0, 1, 0, 0)' filter='url(#noteBG)'><rect id='noteBG-2' data-name='noteBG' width='563' height='563' transform='translate(37 38)' fill='";
    parts[1] = color;
    parts[2] = isSBT ? _SBTTEXT : _NFTTEXT;
    parts[3] = isSBT ? "SBT" : "NFT";
    parts[4] = isSBT ? _SBTVG : _NFTVG;
    parts[5] = message;
    parts[6] = "</svg>";
    return
      Base64.encode(
        abi.encodePacked(
          parts[0],
          parts[1],
          parts[2],
          parts[3],
          parts[4],
          parts[5],
          parts[6]
        )
      );
  }

  function burn(uint256 tokenId) public {
    require(msg.sender == stickies[tokenId].creator);
    delete stickies[tokenId];
    _burn(tokenId);
  }

  /**
   * @notice admin burn in case of really nasty message
   */
  function adminBurn(uint256 tokenId) public onlyRole(DEFAULT_ADMIN_ROLE) {
    delete stickies[tokenId];
    _burn(tokenId);
  }

  // The following functions are overrides required by Solidity.

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    _requireMinted(tokenId);
    address sender = stickies[tokenId].creator;
    string memory svgData = getSvg(tokenId);
    bool isSBT = stickies[tokenId].isSBT;
    string memory color = stickies[tokenId].color;
    string memory json = Base64.encode(
      abi.encodePacked(
        '{"description":"Send on-chain notes to any ETH wallet. StickyNotes.wtf","external_url":"https://stickynotes.wtf/","name":"Sticky Note #',
        tokenId.toString(),
        '","attributes":[{"trait_type": "Sender","value":"',
        Strings.toHexString(uint160(sender), 20),
        '"},{"trait_type": "Type","value":"',
        isSBT ? "SBT" : "NFT",
        '"},{"trait_type": "Color", "value":"',
        color,
        '"}],"image":"data:image/svg+xml;base64,',
        svgData,
        '"}'
      )
    );
    return string(abi.encodePacked("data:application/json;base64,", json));
  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    if (stickies[tokenId].isSBT) revert("Read the definition of 'SBT'");
    super._transfer(from, to, tokenId);
  }

  function _strlen(string memory s) internal pure returns (uint256) {
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
}