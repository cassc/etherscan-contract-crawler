// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/utils/Base64.sol';

import './Library.sol';
import './interfaces/IAssets.sol';
import './interfaces/ITacticalGear.sol';

import './opensea-enforcer/DefaultOperatorFilterer.sol';

contract Keys is ERC1155, Ownable, Pausable, DefaultOperatorFilterer {
  using Counters for Counters.Counter;
  Counters.Counter public tokenIds;

  uint256 MAX_SUPPLY = 174;
  uint256 APARTMENT_KEY = 0;

  IAssets private assets;
  ITacticalGear private tacticalGear;

  constructor(address assetsAddress, address tacticalGearAddress) ERC1155('') {
    assets = IAssets(assetsAddress);
    tacticalGear = ITacticalGear(tacticalGearAddress);
  }

  function forge(address to) external {
    require(_msgSender() == address(tacticalGear), 'Only callable by Gear contract');
    require(tokenIds.current() <= MAX_SUPPLY, 'No more Keys available');
    tokenIds.increment();
    _mint(to, APARTMENT_KEY, 1, '');
  }

  function getCardImage() private view returns (string memory) {
    string memory itemGraphic = assets.getAsset('key');
    string memory cardGraphic = assets.getAsset('card');
    string memory suffixGraphic = assets.getAsset('of the Kami');
    string memory font = assets.getAsset('font');
    string memory fontSize = Library.calculateFontSize('Apartment Key');

    // prettier-ignore
    return
      string(
        abi.encodePacked(
          "<svg version='1.1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' xmlns:xhtml='http://www.w3.org/1999/xhtml' width='760' height='1140' preserveAspectRatio='xMidYMid meet' viewBox='0 0 76 114' style='stroke-width:0; background-color:hsl(0,0%,0%); margin: auto;height: -webkit-fill-available'>",
            abi.encodePacked(
              abi.encodePacked(
                "<style type='text/css'>",
                  "@font-face { font-family: GearFont; src: url('", font, "'); }",
                  ".pixelated { image-rendering: pixelated; }",
                  ".name { font-family: GearFont; font-size: ", fontSize, "; text-transform: uppercase; fill: black; }",
                "</style>"
              ),
              abi.encodePacked(
                "<rect width='100%' height='100%' x='0' y='0' fill='#887e88' />",
                Library.foreignImage('0', '0', '76', '114', cardGraphic),
                Library.foreignImage('6', '18', '64', '64', itemGraphic),
                Library.foreignImage('30', '0', '16', '12', suffixGraphic),
                "<text x='50%' y='104.50' text-anchor='middle' dominant-baseline='middle' class='name'>Apartment Key</text>"
              )
            ),
          "</svg>"
        )
      );
  }

  function uri(uint256) public view override returns (string memory) {
    // prettier-ignore
    string memory metadata = string(
      abi.encodePacked(
        '{',
          '"name": "0N1 Gear Apartment Key",',
          '"description": "0N1 Gear Apartment Key",',
          '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(getCardImage())), '",',
          '"attributes": []',
        '}'
      )
    );

    return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(metadata))));
  }

  // OpenSea Enforcer functions
  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, amount, data);
  }

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual override onlyAllowedOperator(from) {
    super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }
}