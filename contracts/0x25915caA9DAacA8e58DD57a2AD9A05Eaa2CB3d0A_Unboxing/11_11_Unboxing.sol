//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/IGarmentNFT.sol";
import "./interfaces/IInkNFT.sol";

contract Unboxing is ReentrancyGuard, Ownable {
  using ECDSA for bytes32;

  IERC721 public trunks;
  IGarmentNFT public garmentNFT;
  IInkNFT public inkNFT;

  address public deadAddress = 0x000000000000000000000000000000000000dEaD;

  bool public ENABLED = false;

  constructor(IERC721 _trunks, IGarmentNFT _garmentNFT, IInkNFT _inkNFT) {
    trunks = _trunks;
    garmentNFT = _garmentNFT;
    inkNFT = _inkNFT;
  }

  modifier noContract() {
    require(msg.sender == tx.origin, "Contract not allowed");
    _;
  }

  function setDeadAddress(address _address) external onlyOwner {
    deadAddress = _address;
  }

  function setGarmentNFT(IGarmentNFT _address) external onlyOwner {
    garmentNFT = _address;
  }

  function setInkNFT(IInkNFT _adderss) external onlyOwner {
    inkNFT = _adderss;
  }

  function setTrunksAddress(IERC721 _address) external onlyOwner {
    trunks = _address;
  }

  function setEnabled(bool _bool) external onlyOwner {
    ENABLED = _bool;
  }

  function unbox(uint256 tokenId) external noContract {
    require(ENABLED, "unboxing is disabled");
    trunks.safeTransferFrom(msg.sender, deadAddress, tokenId);
    garmentNFT.mint(msg.sender, 1);
    inkNFT.mint(msg.sender, 1);
  }
}