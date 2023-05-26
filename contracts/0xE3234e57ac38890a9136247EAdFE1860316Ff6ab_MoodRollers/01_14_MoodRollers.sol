// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/*****************************************************************\
*       __  ___                ______        ____                 *
*      /  |/  /___  ____  ____/ / __ \____  / / /__  __________   *
*     / /|_/ / __ \/ __ \/ __  / /_/ / __ \/ / / _ \/ ___/ ___/   *
*    / /  / / /_/ / /_/ / /_/ / _, _/ /_/ / / /  __/ /  (__  )    *
*   /_/  /_/\____/\____/\__,_/_/ |_|\____/_/_/\___/_/  /____/     *
*                                                                 *
\*****************************************************************/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MoodRollers is ERC721, ERC721Enumerable, Ownable {
  uint256 constant MAX_SUPPLY = 5000;
  uint256 constant MAX_PER_TRANSACTION = 3;

  string public baseURI = "https://moodrollers.com/api/";
  string private _contractURI = "https://moodrollers.com/api/contracts/MoodRollers";

  enum SaleState {
    Closed,
    Presale,
    Public
  }

  SaleState public saleState = SaleState.Closed;

  uint256 public presalePrice = 0.075 ether;
  uint256 public publicSalePrice = 0.09 ether;

  mapping(address => uint256) private _presaleList;

  address public beneficiary;

  constructor(address _beneficiary) ERC721("MoodRollers", "MOODRLS") {
    beneficiary = _beneficiary;
  }

  // •[email protected]☻@-• Accessors

  function setBeneficiary(address _beneficiary) public onlyOwner {
    beneficiary = _beneficiary;
  }

  function setSaleState(SaleState state) public onlyOwner {
    saleState = state;
  }

  function setBaseURI(string memory uri) public onlyOwner {
    baseURI = uri;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setContractURI(string memory uri) public onlyOwner {
    _contractURI = uri;
  }

  // •[email protected]☻@-• Presale

  function remainingPresaleMints(address _address) public view returns (uint256) {
    return _presaleList[_address];
  }

  function addPresaleAddresses(address[] memory addresses, uint256 reservedAmount) public onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      _presaleList[addresses[i]] = reservedAmount;
    }
  }

  // •[email protected]☻@-• Minting

  function _internalMint(address destination, uint256 count) private {
    uint256 currentSupply = totalSupply();

    require(currentSupply + count <= MAX_SUPPLY, "Maximum supply exceeded");

    for (uint256 i = 1; i <= count; i++) {
      _safeMint(destination, currentSupply + i);
    }
  }

  function mintPresaleRollers(uint256 amount) public payable {
    require(saleState == SaleState.Presale, "Presale is closed");

    uint256 reservedAmount = _presaleList[_msgSender()];
    require(reservedAmount > 0, "No presale rollers left");
    require(amount <= reservedAmount, "Trying to mint more than allotted");
    require(msg.value == presalePrice * amount, "Incorrect payable amount");

    _presaleList[_msgSender()] = reservedAmount - amount;

    _internalMint(_msgSender(), amount);

    payable(beneficiary).transfer(msg.value);
  }

  function mintRollers(uint256 amount) public payable {
    require(saleState == SaleState.Public, "Public sale is closed");
    require(amount <= MAX_PER_TRANSACTION, "At most 3 per transaction");
    require(msg.value == publicSalePrice * amount, "Incorrect payable amount");

    _internalMint(_msgSender(), amount);

    payable(beneficiary).transfer(msg.value);
  }

  // •[email protected]☻@-• Required overrides

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