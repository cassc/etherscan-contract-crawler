//                                                    _     _                       _  _        _     _
//                                                   (_)   (_)                     (_)(_)      (_)   (_)
//        _  _  _  _    _  _  _  _   _       _  _  _  _  _ (_) _  _    _  _  _  _     (_)    _  _  _ (_) _  _    _  _  _  _      _  _  _  _
//      _(_)(_)(_)(_)  (_)(_)(_)(_)_(_)_  _ (_)(_)(_)(_)(_)(_)(_)(_)  (_)(_)(_)(_)_   (_)   (_)(_)(_)(_)(_)(_)  (_)(_)(_)(_)_  _(_)(_)(_)(_)
//     (_)_  _  _  _   (_)        (_) (_)(_)         (_)   (_)       (_) _  _  _ (_)  (_)      (_)   (_)       (_) _  _  _ (_)(_)_  _  _  _
//       (_)(_)(_)(_)_ (_)        (_) (_)            (_)   (_)     _ (_)(_)(_)(_)(_)  (_)      (_)   (_)     _ (_)(_)(_)(_)(_)  (_)(_)(_)(_)_
//        _  _  _  _(_)(_) _  _  _(_) (_)          _ (_) _ (_)_  _(_)(_)_  _  _  _  _ (_) _  _ (_) _ (_)_  _(_)(_)_  _  _  _     _  _  _  _(_)
//       (_)(_)(_)(_)  (_)(_)(_)(_)   (_)         (_)(_)(_)  (_)(_)    (_)(_)(_)(_)(_)(_)(_)(_)(_)(_)  (_)(_)    (_)(_)(_)(_)   (_)(_)(_)(_)
//                     (_)
//                     (_)
// SPDX-License-Identifier: MIT
// @author LookingForOwls

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

error MintingNotStarted();
error ExceedsMaxMintQuantity();
error ExceedsMaxSupply();
error EthValueTooLow();

contract Spritelites is ERC721A, Ownable {
  constructor() ERC721A("Spritelites", "LITES") {}

  string private baseURI;
  bool public started = false;
  bool public claimed = false;
  uint32 public maxSupply = 6767;

  // Constants
  uint256 public constant cost = 0.02 ether;
  uint256 public constant maxMintAmount = 10;
  address constant DAO = 0x42A21bA79D2fe79BaE4D17A6576A15b79f5d36B0;

  function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
  }

  function mint(uint256 quantity) external payable {
    if (!started) revert MintingNotStarted();
    if (quantity > maxMintAmount) revert ExceedsMaxMintQuantity();
    if (quantity + totalSupply() > maxSupply) revert ExceedsMaxSupply();
    if (msg.value < cost * quantity) revert EthValueTooLow();
    // mint
    _safeMint(msg.sender, quantity);
  }

  function teamClaim() external onlyOwner {
    require(!claimed, "Team already claimed");
    // claim
    _safeMint(DAO, 50);
    claimed = true;
  }

  function setBaseURI(string memory baseURI_) external onlyOwner {
      baseURI = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
  }

  function enableMint(bool _state) public onlyOwner {
      started = _state;
  }

  function reduceSupply(uint32 _supply) public onlyOwner {
      require(_supply < maxSupply, "Supply can not be increased");
      require(_supply >= totalSupply(), "Must be greater than current supply");
      maxSupply = _supply;
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    Address.sendValue(payable(DAO), balance);
  }
}