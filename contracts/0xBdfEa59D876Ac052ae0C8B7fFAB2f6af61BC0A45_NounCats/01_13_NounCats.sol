//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721 }  from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC2981 } from "@openzeppelin/contracts/token/common/ERC2981.sol";

// Contract by: @backseats_eth

interface IInvisibles {
  function isApprovedForAll(address owner, address operator) external view returns (bool);
  function ownerOf(uint256 tokenId) external returns (address);
  function transferFrom(address from, address to, uint256 tokenId) external;

  function promoMint(address _to, uint _amount) external;
  function transferOwnership(address newOwner) external;
}

// Errors

error CantMintZero();
error CatAlreadyExists();
error MintClosed();
error MintingTooMany();
error SoldOut();
error WrongPrice();

// The Contract

contract NounCats is ERC721, ERC2981, Ownable {

  uint256 public price = 0.025 ether;

  uint256 public currentInvisibleId;

  string public _baseTokenURI;

  bool public mintOpen;

  address public constant INVISIBLES = 0xB5942dB8d5bE776CE7585132616D3707f40D46e5;

  // Events

  event BothMinted(address indexed _by, uint indexed _tokenId);
  event InvisibleBurned(address indexed _by, uint indexed _tokenId);
  event InvisiblesMinted(address indexed _by, uint indexed _count);
  event NounterpartMinted(address indexed _to, uint indexed _tokenId);

  constructor() ERC721("Noun Cats", "NOUNCATS") {}

  // Mint

  // Go to the Invisibles contract and run function 10, `setApprovedForAll` to the following values:
  // The first value is this contract's address and the second value is `true`
  // https://etherscan.io/address/0xb5942db8d5be776ce7585132616d3707f40d46e5#writeContract
  // NOTE: This function locks your Invisible in this contract before minting, effectively burning that Invisible
  // You will no longer own the Invisible afterwards
  function burnAndReveal(uint256[] calldata _ids) external {
    if (mintOpen == false) revert MintClosed();
    if (_ids.length == 0) revert CantMintZero();

    IInvisibles invis = IInvisibles(INVISIBLES);
    require(invis.isApprovedForAll(msg.sender, address(this)), "Contract not approved to burn");

    for(uint i; i < _ids.length;) {
      uint id = _ids[i];
      if (invis.ownerOf(id) == msg.sender && !_exists(id)) {
        // Burn your Invisible to this contract
        invis.transferFrom(msg.sender, address(this), id);

        emit InvisibleBurned(msg.sender, id);

        // Reveal your Noun Cat!
        _mint(msg.sender, id);
      }

      unchecked { ++i; }
    }
  }

  // Mint function that doesn't burn Invisibles and instead mints your corresponding Cats
  function mintWithIds(uint256[] calldata _ids) external payable {
    if (mintOpen == false) revert MintClosed();
    IInvisibles invis = IInvisibles(INVISIBLES);

    uint idsLength = _ids.length;
    if (idsLength == 0) revert CantMintZero();

    // Use a count and an array of N values
    // count and idsToMint.length may differ if the check in the loop fails
    // Arrays of N length are initiated with N 0's as starting values
    uint count;
    uint[] memory idsToMint = new uint[](idsLength);

    for(uint i; i < idsLength;) {
      uint id = _ids[i];

      if (invis.ownerOf(id) == msg.sender && !_exists(id)) {
        idsToMint[i] = id;
        unchecked { ++count; }
      }

      unchecked { ++i; }
    }

    if (count == 0) revert CantMintZero();
    if (msg.value != (count * price)) revert WrongPrice();

    for (uint i; i < count;) {
      uint id = idsToMint[i];
      if (id != 0) {
        _mint(msg.sender, id);
        emit NounterpartMinted(msg.sender, id);
      }

      unchecked { ++i; }
    }
  }

  // Mints you an Invisible and a Cat of the same ID and attributes
  // Price is 0.025 (or price above, if changed) * 2 * amount you want to mint
  function collectEmAll(uint _amount) external payable {
    if (mintOpen == false) revert MintClosed();
    if (currentInvisibleId + _amount > 5_000) revert SoldOut();
    if (msg.value != ((price * 2) * _amount)) revert WrongPrice();

    IInvisibles invis = IInvisibles(INVISIBLES);
    invis.promoMint(msg.sender, _amount);

    for (uint i; i < _amount;) {
      uint id = currentInvisibleId + 1;
      if (_exists(id)) revert CatAlreadyExists();

      _mint(msg.sender, id);
      emit BothMinted(msg.sender, id);

      unchecked {
        ++currentInvisibleId;
        ++i;
      }
    }
  }

  // Mints up to 10 Invisible Noun Cats per transaction
  // See the collection @ https://opensea.io/collection/noun-cats-invisibles
  function mintInvisible(uint _amount) external payable {
    if (mintOpen == false) revert MintClosed();
    if (currentInvisibleId + _amount > 5_000) revert SoldOut();
    if (_amount > 10) revert MintingTooMany();
    if (msg.value != (price * _amount)) revert WrongPrice();

    IInvisibles invis = IInvisibles(INVISIBLES);
    invis.promoMint(msg.sender, _amount);

    emit InvisiblesMinted(msg.sender, _amount);

    unchecked {
      currentInvisibleId += _amount;
    }
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

  function setStartingInvisibleId(uint _val) external onlyOwner {
    currentInvisibleId = _val;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  /**
  @notice Returns whether an Invisible id has already been used to mint a Cat
  */
  function hasInvisibleBeenUsed(uint256 _id) public view returns (bool) {
    return _exists(_id);
  }

  // Boilerplate

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  // For Emergency Use Only

  function emergencyTransferInvisibleContractOwnership(address _newOwner) external onlyOwner {
    IInvisibles invis = IInvisibles(INVISIBLES);
    invis.transferOwnership(_newOwner);
  }

  // Withdraw

  function withdraw() external onlyOwner {
    address w1 = 0x702457481718bEF08C5bb0124083A1369fAB4542;
    address w2 = 0x5390B04839C6EBaA765886E1EDe2BCE7116e462F;
    address w3 = 0x6d42a9542f76eFeb405d6755317C9A81dBA33EEF;
    address w4 = 0x3733f44e9FF13d398512449E4d96E78Bc5594708;
    address w5 = 0x3230086971D2D50D30642e3e344233f56BECB5C5;

    uint balance = address(this).balance;
    uint256 smallBal = balance * 50/1000;
    uint256 largeBal = balance * 425/1000;

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