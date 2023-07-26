// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IVhilsNFT {
  struct TokenInfo {
    uint8 state;
    bool locked;
    uint8[4] tearIdUsed;
    uint64 name;
    string uri;
  }

  function getTokenInfo(uint16 _tokenId) external view returns (TokenInfo memory);
}

contract VhilsBurn is Ownable2Step, ERC721Holder, ERC1155Holder {
  struct Edition {
    bool active;
    uint16 allocation;
    uint16 minted;
    uint32 start;
    uint32 end;
    uint120 price;
  }

  // variables
  address public vhilsNFT = 0xa9248a0935EB476cFE2f286Df813a48D06ffd2e2;
  address public vhilsUtility = 0x3077674dd77c532B2E2D9945808C900940DE50aE;

  uint16[] public layerRewards;
  mapping(uint8 => Edition) public editions;

  // events
  event Burned(uint16 tokenId, uint8 _type);

  constructor() {
    editions[0] = Edition(false, 20, 0, 1689876000, type(uint32).max, 0.1 ether);
    // 1689876000 - 1690480860
    editions[1] = Edition(true, 20, 0, 1680390000, 1690480860, 0.3 ether);
    editions[2] = Edition(true, 20, 0, 1680390000, 1690480860, 1 ether);
  }

  function burn(uint16 _tokenId, uint8 _type) external payable {
    address account = msg.sender;
    Edition storage edition = editions[_type];
    require(tx.origin == account, "Not allowed");
    require(edition.active, "Not available");
    require(block.timestamp >= edition.start && block.timestamp <= edition.end, "Not active");
    require(edition.minted < edition.allocation, "Sold out");
    IVhilsNFT.TokenInfo memory tokenInfo = IVhilsNFT(vhilsNFT).getTokenInfo(_tokenId);
    require(tokenInfo.state == 3, "Require fully revealed");
    require(edition.price == msg.value, "Invalid ETH");
    require(layerRewards.length > 0, "No reward");

    IERC721(vhilsNFT).safeTransferFrom(account, address(this), _tokenId);

    // burn
    _burnToken(account);

    edition.minted++;

    emit Burned(_tokenId, _type);
  }

  function setVhilsNFT(address _vhilsNFT) public onlyOwner {
    vhilsNFT = _vhilsNFT;
  }

  function setVhilsUtility(address _vhilsUtility) public onlyOwner {
    vhilsUtility = _vhilsUtility;
  }

  function setPrices(uint8[] memory _types, uint120[] memory _prices) public onlyOwner {
    require(_types.length == _prices.length, "Invalid length");
    for (uint8 i = 0; i < _types.length; i++) {
      editions[_types[i]].price = _prices[i];
    }
  }

  function setAllocations(uint8[] memory _types, uint8[] memory _allocations) public onlyOwner {
    require(_types.length == _allocations.length, "Invalid length");
    for (uint8 i = 0; i < _types.length; i++) {
      editions[_types[i]].allocation = _allocations[i];
    }
  }

  function setTimeRange(uint8[] memory _types, uint32 _start, uint32 _end) public onlyOwner {
    for (uint8 i = 0; i < _types.length; i++) {
      editions[_types[i]].start = _start;
      editions[_types[i]].end = _end;
    }
  }

  function setActive(uint8[] memory _types, bool[] memory _active) public onlyOwner {
    require(_types.length == _active.length, "Invalid length");
    for (uint8 i = 0; i < _types.length; i++) {
      editions[_types[i]].active = _active[i];
    }
  }

  function setEdition(uint8 _type, bool _active, uint16 _allocation, uint32 _start, uint32 _end, uint120 _price) public onlyOwner {
    editions[_type] = Edition(_active, _allocation, 0, _start, _end, _price);
  }

  function depositLayerRewards(address _from, uint16[] memory _tokenIds) public onlyOwner {
    require(_tokenIds.length > 0, "Invalid tokenIds");
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      layerRewards.push(_tokenIds[i]);
      IVhilsNFT.TokenInfo memory tokenInfo = IVhilsNFT(vhilsNFT).getTokenInfo(_tokenIds[i]);
      require(tokenInfo.state == 0, "Require not revealed");
      IERC721(vhilsNFT).safeTransferFrom(_from, address(this), _tokenIds[i]);
    }
  }

  function withdraw721(address _to, address _token, uint256[] memory _tokenIds) public onlyOwner {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      IERC721(_token).safeTransferFrom(address(this), _to, _tokenIds[i]);
    }
  }

  function withdraw1155(address _to, address _token, uint256[] memory _tokenIds, uint256[] memory _amounts) public onlyOwner {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      IERC1155(_token).safeTransferFrom(address(this), _to, _tokenIds[i], _amounts[i], "");
    }
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  /* Internal */
  function _burnToken(address _account) internal {
    uint8 utilityAmount = 3;
    // 1 = alpha, 2 = beta
    IERC1155(vhilsUtility).safeTransferFrom(address(this), _account, 2, utilityAmount, "");

    // get reward token from list
    uint16 rewardTokenId = layerRewards[layerRewards.length - 1];
    layerRewards.pop();
    IERC721(vhilsNFT).safeTransferFrom(address(this), _account, rewardTokenId);
  }
}