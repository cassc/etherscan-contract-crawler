// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

import '@openzeppelin/contracts/token/common/ERC2981.sol';
import {UpdatableOperatorFilterer} from 'operator-filter-registry/src/UpdatableOperatorFilterer.sol';
import {RevokableDefaultOperatorFilterer} from 'operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol';

// interface AnotherERC721Contract {
//   function balanceOf(address owner) external view returns (uint256 balance);
// }

contract PhantomCrush is
  ERC721,
  ERC2981,
  Ownable,
  RevokableDefaultOperatorFilterer
{
  address[] enabledContracts = [
    0x898157afB3E158cc835D19B9ecd37C69bF460f8C, // oasis
    // 0xc6532Ec32BC8e4C33546d1bb7783F44c8e396289, // fixme: some random other project on goerli
    0x9B02B12c0dC57d8B150DA76f1789b309673c4349, // indiscreet units
    0x20C70BDFCc398C1f06bA81730c8B52ACE3af7cc3, // mutant garden seeder
    0x518f0C4A832b998ee793D87F0E934467b8b6E587, // markov's dream
    0x71d7b2adf7Be0377C1AFAAC8666e8dfB30a1956F // markov's dream: orb lite
  ];

  uint16 private tokenTokenIdMax = 444;
  string private baseURIValue =
    'ipfs://QmdfMFhnByrxnVXckbNF2oP5VF8Y7oAciLA5eBXvFNYNdV/';
  uint256 private price = 0.1 ether;
  uint256 public currentTokenId = 0;
  bool private paused = false;
  bool private publicMintEnabled = false;

  address payable private payoutAddress =
    payable(0xbE72830aEeD1BFbe3e6dcF52cb461cb5f76861D8);

  constructor() ERC721('Phantom Crush', unicode'👻') {
    _setDefaultRoyalty(payoutAddress, 850); // 8.5%
  }

  function owner()
    public
    view
    virtual
    override(Ownable, UpdatableOperatorFilterer)
    returns (address)
  {
    return Ownable.owner();
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC2981, ERC721) returns (bool) {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC2981).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function setTokenIdMax(uint16 newTokenIdMax) external onlyOwner {
    tokenTokenIdMax = newTokenIdMax;
  }

  function setPaused(bool newPaused) external onlyOwner {
    paused = newPaused;
  }

  function addAddressToEnableList(address _addr) external onlyOwner {
    enabledContracts.push(_addr);
  }

  function getEnabledContracts() external view returns (address[] memory) {
    return enabledContracts;
  }

  function getPaused() external view returns (bool) {
    return paused;
  }

  function getPrice() external view returns (uint256) {
    return price;
  }

  function getPublicMintEnabled() external view returns (bool) {
    return publicMintEnabled;
  }

  function setPublicMintEnabled(bool newEnabled) external onlyOwner {
    publicMintEnabled = newEnabled;
  }

  function mint(address recipient) external payable {
    require(!paused, 'Contract not activated yet');
    require(msg.value >= price, 'You did not send enough ether');
    require(currentTokenId < tokenTokenIdMax, 'Max supply reached');
    require(
      publicMintEnabled || isEnableListed(msg.sender),
      'Only holders of enabled contracts can mint at this moment'
    );
    payoutAddress.transfer(msg.value);
    return _safeMint(recipient, ++currentTokenId);
  }

  function isContract(address _addr) private view returns (bool) {
    uint32 size;
    assembly {
      size := extcodesize(_addr)
    }
    return (size > 0);
  }

  function isEnableListed(address wallet) public view returns (bool) {
    for (uint8 i = 0; i < enabledContracts.length; i++) {
      if (!isContract(enabledContracts[i])) continue;
      IERC721 OtherContractInstance = IERC721(enabledContracts[i]);
      if (OtherContractInstance.balanceOf(wallet) > 0) return true;
    }
    return false;
  }

  function updatePayoutAddress(
    address payable newPayoutAddress
  ) external onlyOwner {
    payoutAddress = newPayoutAddress;
  }

  function adminMint(address recipient) external onlyOwner {
    require(currentTokenId < tokenTokenIdMax, 'Max supply reached');
    _safeMint(recipient, ++currentTokenId);
  }

  function setPrice(uint256 newPrice) external onlyOwner {
    price = newPrice;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURIValue;
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURIValue = newBaseURI;
  }

  function totalSupply() public view returns (uint256) {
    return currentTokenId;
  }

  function getMaxSupply() public view returns (uint256) {
    return tokenTokenIdMax;
  }

  function setApprovalForAll(
    address operator,
    bool approved
  ) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(
    address operator,
    uint256 tokenId
  ) public override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}