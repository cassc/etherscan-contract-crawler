// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721 }  from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC2981 } from "@openzeppelin/contracts/token/common/ERC2981.sol";

// Contract by: @backseats_eth

interface IInvisibles {
  function isApprovedForAll(address owner, address operator) external view returns (bool);
  function ownerOf(uint tokenId) external returns (address);
  function transferFrom(address from, address to, uint tokenId) external;
}

// Errors

error CatAlreadyMinted();
error BadID();
error CantMintZero();
error CatAlreadyExists();
error InvisibleAlreadyTransferred(uint id);
error MintClosed();
error MintedOut();
error MintingTooMany();
error WrongPrice();
error WrongPriceWithNounterpart();

// The Contract

contract NounCats is ERC721, ERC2981, Ownable {

  // Cats are free if you burn an Invisible
  // They're 0.025 if you use your Invisible to mint is Nounterpart Cat
  // Minting a cat and its corresponding Invisible is 0.05 per pair
  uint public price = 0.025 ether;

  // A private property for tracking supply. See `totalSupply()` for a public function
  uint _tokenSupply;

  // 5,000 Cats
  uint constant MAX_SUPPLY = 5_000;

  string public _baseTokenURI;

  bool public mintOpen;

  // The address of the Invisibles contract
  address public constant INVISIBLES = 0xB5942dB8d5bE776CE7585132616D3707f40D46e5;

  // The address of the team wallet that holds the Invisibles for transfer
  address constant TREASURY = 0xcac5cc8dbccc684C1530fF1502fD48a2fD2AFbe3;

  // Events

  event CatMinted(address indexed _by, uint indexed _tokenId);
  event InvisibleBurned(address indexed _by, uint indexed _tokenId);
  event InvisibleMinted(address indexed _by, uint indexed _tokenId);
  event NounterpartMinted(address indexed _to, uint indexed _tokenId);

  // Modifier

  modifier mintIsOpen() {
    if (mintOpen == false) revert MintClosed();
    _;
  }

  // Constructor

  constructor() ERC721("Noun Cats", "NOUNCATS") {}

  // Mint

  // Go to the Invisibles contract and run function 10, `setApprovedForAll` to the following values:
  // The first value is this contract's address and the second value is `true`
  // https://etherscan.io/address/0xb5942db8d5be776ce7585132616d3707f40d46e5#writeContract
  // NOTE: This function locks your Invisible in this contract before minting, effectively burning that Invisible
  // You will no longer own the Invisible afterwards
  function burnAndReveal(uint[] calldata _ids) external mintIsOpen() {
    uint idsLength = _ids.length;
    if (idsLength == 0) revert CantMintZero();

    IInvisibles invis = IInvisibles(INVISIBLES);
    require(invis.isApprovedForAll(msg.sender, address(this)), "Contract not approved to burn");

    uint tokenSupply = _tokenSupply;
    uint id;

    for(uint i; i < idsLength;) {
      id = _ids[i];

      if (id > MAX_SUPPLY) revert BadID();

      if (invis.ownerOf(id) == msg.sender && !_exists(id)) {
        // Burn your Invisible to this contract, forever
        invis.transferFrom(msg.sender, address(this), id);

        emit InvisibleBurned(msg.sender, id);

        unchecked { ++tokenSupply; }

        // Reveal your Noun Cat!
        _mint(msg.sender, id);

        emit CatMinted(msg.sender, id);
      }

      unchecked { ++i; }
    }

    _tokenSupply = tokenSupply;
  }

  // Mint function that doesn't burn Invisibles and instead mints the corresponding Cat to your Invisible
  // (ie your Nounterpart)
  function mintNounterpart(uint[] calldata _ids) external payable mintIsOpen() {
    uint idsLength = _ids.length;
    if (idsLength == 0) revert CantMintZero();

    IInvisibles invis = IInvisibles(INVISIBLES);

    // Use a count and an array of N values
    // count and idsToMint.length may differ if the check in the loop fails
    // Arrays of N length are initiated with N 0's as starting values
    uint count;
    uint[] memory idsToMint = new uint[](idsLength);

    for(uint i; i < idsLength;) {
      uint id = _ids[i];

      if (id > MAX_SUPPLY) revert BadID();

      if (invis.ownerOf(id) == msg.sender && !_exists(id)) {
        idsToMint[i] = id;
        unchecked { ++count; }
      }

      unchecked { ++i; }
    }

    if (count == 0) revert CantMintZero();
    if (msg.value != (count * price)) revert WrongPrice();

    uint tokenSupply = _tokenSupply;

    for (uint j; j < count;) {
      uint id = idsToMint[j];
      if (id != 0) {
        unchecked { ++tokenSupply; }

        _mint(msg.sender, id);

        emit CatMinted(msg.sender, id);

        // An Invisible minted his Cat!
        emit NounterpartMinted(msg.sender, id);
      }

      unchecked { ++j; }
    }

    _tokenSupply = tokenSupply;
  }

  // Shopping!

  // Mint 1 or more Cats and their corresponding Invisibles (if you so choose).
  // The price doubles due to minting both the Cat and corresponding Invisible
  function mintCats(uint[] calldata _ids, bool mintNounterparts) external payable mintIsOpen() {
    if (totalSupply() == MAX_SUPPLY) revert MintedOut();

    uint idsLength = _ids.length;
    if (idsLength == 0) revert CantMintZero();

    if (mintNounterparts) {
      if (msg.value != ((idsLength * 2) * price)) revert WrongPriceWithNounterpart();
    } else {
      if (msg.value != (idsLength * price)) revert WrongPrice();
    }

    uint tokenSupply = _tokenSupply;
    uint id;

    for (uint i; i < idsLength;) {
      id = _ids[i];
      // IDs 3782 and greater are for purchase
      if (id < 3782 || id > MAX_SUPPLY) revert BadID();
      if (_exists(id)) revert CatAlreadyMinted();

      if (mintNounterparts) _transferInvisible(id);

      unchecked { ++tokenSupply; }

      // Mint msg.sender the Cat
      _mint(msg.sender, id);

      emit CatMinted(msg.sender, id);

      unchecked { ++i; }
    }

    _tokenSupply = tokenSupply;
  }

  // Mint an Invisible
  function mintInvisibles(uint[] calldata _ids) external payable mintIsOpen() {
    if (_ids.length == 0) revert CantMintZero();
    if (msg.value != (_ids.length * price)) revert WrongPrice();

    uint id;

    for (uint i; i < _ids.length;) {
      id = _ids[i];
      // IDs 3782 and greater are for purchase
      if (id < 3782 || id > MAX_SUPPLY) revert BadID();

      _transferInvisible(id);

      unchecked { ++i; }
    }
  }

  function _transferInvisible(uint _id) internal {
    IInvisibles invis = IInvisibles(INVISIBLES);
    invis.transferFrom(TREASURY, msg.sender, _id);

    emit InvisibleMinted(msg.sender, _id);
  }

  // Owner

  // Allows the team to give Cats to people. Specifies IDs because of the nature of minting and matching above
  function promoMint(address _to, uint[] calldata _ids) external onlyOwner {
    if (totalSupply() == MAX_SUPPLY) revert MintedOut();

    uint tokenSupply = _tokenSupply;
    uint id;

    for (uint i; i < _ids.length;) {
      id = _ids[i];
      if (_exists(id) || id > MAX_SUPPLY) revert BadID();

      _mint(_to, id);

      emit CatMinted(_to, id);

      unchecked {
        ++i;
        ++tokenSupply;
      }
    }

    _tokenSupply = tokenSupply;
  }

  // View

  function totalSupply() public view returns (uint) {
    return _tokenSupply;
  }

  // Setters

  function setRoyaltyInfo(address receiver, uint96 feeBasisPoints) external onlyOwner {
    _setDefaultRoyalty(receiver, feeBasisPoints);
  }

  function setBaseURI(string calldata _baseURI) external onlyOwner {
    _baseTokenURI = _baseURI;
  }

  function setMintOpen(bool _val) external onlyOwner {
    mintOpen = _val;
  }

  function setPrice(uint _newPrice) external onlyOwner {
    price = _newPrice;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  // Boilerplate

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  // Withdraw

  function withdraw() external onlyOwner {
    address w1 = 0x702457481718bEF08C5bb0124083A1369fAB4542;
    address w2 = 0x5390B04839C6EBaA765886E1EDe2BCE7116e462F;
    address w3 = 0x6d42a9542f76eFeb405d6755317C9A81dBA33EEF;
    address w4 = 0x3733f44e9FF13d398512449E4d96E78Bc5594708;
    address w5 = 0x3230086971D2D50D30642e3e344233f56BECB5C5;

    uint balance = address(this).balance;
    uint smallBal = balance * 50/1000;
    uint largeBal = balance * 425/1000;

    (bool sent, ) = w1.call{value: smallBal}("");
    require(sent, "w1 Send failed");
    (bool sent2, ) = w2.call{value: smallBal}("");
    require(sent2, "w2 Send failed");
    (bool sent3, ) = w3.call{value: smallBal}("");
    require(sent3, "w3 Send failed");
    (bool sent4, ) = w4.call{value: largeBal}("");
    require(sent4, "w4 Send failed");
    (bool sent5, ) =  w5.call{value: largeBal}("");
    require(sent5, "w5 Send failed");
  }

}