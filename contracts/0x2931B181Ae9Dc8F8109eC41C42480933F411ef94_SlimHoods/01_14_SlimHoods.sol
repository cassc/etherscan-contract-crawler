// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**

  .d88888b  dP oo            dP     dP                          dP
  88.    "' 88               88     88                          88
  `Y88888b. 88 dP 88d8b.d8b. 88aaaaa88a .d8888b. .d8888b. .d888b88 .d8888b.
        `8b 88 88 88'`88'`88 88     88  88'  `88 88'  `88 88'  `88 Y8ooooo.
  d8'   .8P 88 88 88  88  88 88     88  88.  .88 88.  .88 88.  .88       88
   Y88888P  dP dP dP  dP  dP dP     dP  `88888P' `88888P' `88888P8 `88888P'

  Hi fren!

*/

contract SlimHoods is ERC721, ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI = "https://slimhoods.com/api/";

  uint256 public price = 0.05 ether;
  uint256 public saleState = 0; // 0 = closed, 1 = presale, 2 = public
  uint256 constant MAX_HOODS = 5000;

  address public addr1;
  address public addr2;

  mapping(address => uint256) public presaleList;

  constructor(address _addr1, address _addr2) ERC721("SlimHoods", "SLMHDS") {
    addr1 = _addr1;
    addr2 = _addr2;
  }

  /* -- Accessors -- */

  function setBaseURI(string memory newBaseURI) public onlyOwner {
    baseURI = newBaseURI;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setSaleState(uint256 state) public onlyOwner {
    saleState = state;
  }

  function addPresaleAddresses(address[] memory addresses, uint256 reservedAmount) public onlyOwner {
    for (uint256 i; i < addresses.length; i++) {
      presaleList[addresses[i]] = reservedAmount;
    }
  }

  function setAddresses(address[2] memory addr) public onlyOwner {
    addr1 = addr[0];
    addr2 = addr[1];
  }

  /* -- Minting -- */

  function _internalMint(address destination, uint256 count) private {
    uint256 currentSupply = totalSupply();

    require(currentSupply + count <= MAX_HOODS, "Maximum SlimHoods supply exceeded");

    for (uint256 i = 1; i <= count; i++) {
      _safeMint(destination, currentSupply + i);
    }
  }

  function hoodsAvailableForPresale(address addr) public view returns (uint256) {
    return presaleList[addr];
  }

  function mintPresaleHoods(uint256 count) public payable {
    require(saleState > 0, "Sale is closed");

    uint256 reservedAmount = presaleList[msg.sender];
    require(reservedAmount > 0, "No reserved hoods for wallet");
    require(count <= reservedAmount, string(abi.encodePacked("Can't mint more than reserved presale amount (", reservedAmount.toString(), ")")));
    require(msg.value >= price * count, "Insufficient amount");

    presaleList[msg.sender] = reservedAmount - count;

    _internalMint(msg.sender, count);
  }

  function mintHoods(uint256 count) public payable {
    require(saleState > 1, "Sale is closed");
    require(count <= 5, "You can only mint 5 or less at once");
    require(msg.value >= price * count, "Insufficient amount");

    _internalMint(msg.sender, count);
  }

  function giveAway(address destination, uint256 amount) public onlyOwner {
    _internalMint(destination, amount);
  }

  /* -- Withdraw -- */

  function withdraw() public onlyOwner {
    uint256 perc = uint256(address(this).balance) / 100;
    uint256 addr1amount = perc * 90;
    uint256 addr2amount = perc * 10;

    require(payable(addr1).send(addr1amount));
    require(payable(addr2).send(addr2amount));
  }

  /* -- Required overrides -- */

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}