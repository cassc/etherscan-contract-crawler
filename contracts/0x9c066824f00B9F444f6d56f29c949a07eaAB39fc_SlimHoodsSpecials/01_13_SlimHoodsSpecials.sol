// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**

  .d88888b  dP oo            dP     dP                          dP
  88.    "' 88               88     88                          88
  `Y88888b. 88 dP 88d8b.d8b. 88aaaaa88a .d8888b. .d8888b. .d888b88 .d8888b.
        `8b 88 88 88'`88'`88 88     88  88'  `88 88'  `88 88'  `88 Y8ooooo.
  d8'   .8P 88 88 88  88  88 88     88  88.  .88 88.  .88 88.  .88       88
   Y88888P  dP dP dP  dP  dP dP     dP  `88888P' `88888P' `88888P8 `88888P'

  Hi Special fren!

*/

interface ISlimHoods is IERC721, IERC721Enumerable {

}

contract SlimHoodsSpecials is ERC1155, Ownable {
  string private _contractURI = "https://slimhoods.com/api/contracts/SlimHoodsSpecials";

  enum SaleState {
    Closed,
    Open
  }

  mapping(uint256 => SaleState) private _saleStates;

  using EnumerableSet for EnumerableSet.UintSet;

  mapping(uint256 => bool) public availableSpecialNumbers;
  mapping(uint256 => EnumerableSet.UintSet) private _minted;

  address public slimhoodsAddress;
  ISlimHoods private _slimhoodsContract;

  constructor(address _slimhoodsAddress) ERC1155("https://slimhoods.com/api/specials/{id}") {
    slimhoodsAddress = _slimhoodsAddress;
    _slimhoodsContract = ISlimHoods(slimhoodsAddress);
  }

  // ** METADATA **

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setContractURI(string memory newuri) public onlyOwner {
    _contractURI = newuri;
  }

  function setURI(string memory newuri) public onlyOwner {
    _setURI(newuri);
  }

  // ** SALE STATE **

  function setSaleState(uint256 specialNumber, SaleState _saleState) public onlyOwner {
    require(availableSpecialNumbers[specialNumber], "No such special");
    _saleStates[specialNumber] = _saleState;
  }

  function saleState(uint256 specialNumber) public view returns (SaleState) {
    return _saleStates[specialNumber];
  }

  // ** RELEASES **

  function addSpecialNumber(uint256 specialNumber) public onlyOwner {
    availableSpecialNumbers[specialNumber] = true;
  }

  function removeSpecialNumber(uint256 specialNumber) public onlyOwner {
    delete availableSpecialNumbers[specialNumber];
    delete _saleStates[specialNumber];
  }

  // ** MINTING **

  function unmintedSlimHoodIds(uint256 specialNumber, address addr) public view returns (uint256[] memory) {
    uint256 balance = _slimhoodsContract.balanceOf(addr);
    uint256[] memory result = new uint256[](balance);
    uint256 tokenId;
    uint256 counter = 0;

    for (uint256 i = 0; i < balance; i++) {
      tokenId = _slimhoodsContract.tokenOfOwnerByIndex(addr, i);
      if (!specialHasBeenMinted(specialNumber, tokenId)) {
        result[counter] = tokenId;
        counter++;
      }
    }

    return result;
  }

  function specialHasBeenMinted(uint256 specialNumber, uint256 slimHoodId) public view returns (bool) {
    return _minted[specialNumber].contains(slimHoodId);
  }

  function mintSpecialForSlimHoods(uint256 specialNumber, uint256[] memory hoodIds) public virtual {
    require(availableSpecialNumbers[specialNumber], "No special for given number");
    require(_saleStates[specialNumber] == SaleState.Open, "Sale is closed");

    uint256 hoodId;
    for (uint256 i = 0; i < hoodIds.length; i++) {
      hoodId = hoodIds[i];

      require(_slimhoodsContract.ownerOf(hoodId) == msg.sender, "Wallet doesn't hold given SlimHood");
      require(!specialHasBeenMinted(specialNumber, hoodId), "Special already minted for this SlimHood");

      _minted[specialNumber].add(hoodId);
      _mint(msg.sender, specialNumber, 1, "");
    }
  }
}