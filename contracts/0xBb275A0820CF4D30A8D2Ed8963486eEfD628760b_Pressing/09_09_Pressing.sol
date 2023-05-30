//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Pressing is ReentrancyGuard, Ownable {
  using ECDSA for bytes32;

  IERC721 public garmentNFT;
  IERC721 public inkNFT;
  address public deadAddress = 0x000000000000000000000000000000000000dEaD;
  mapping(uint256 => uint256) public presses;
  bool public REPRESSING_ENABLED = false;
  bool public ENABLED = false;

  event Press(address indexed by, uint256 indexed garmentID, uint256 indexed inkID);

  constructor(IERC721 _garmentNFT, IERC721 _inkNFT) {
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

  function setGarmentNFT(IERC721 _address) external onlyOwner {
    garmentNFT = _address;
  }

  function setInkNFT(IERC721 _adderss) external onlyOwner {
    inkNFT = _adderss;
  }

  function setEnabled(bool _bool) external onlyOwner {
    ENABLED = _bool;
  }

  function setRepressingEnabled(bool _bool) external onlyOwner {
    REPRESSING_ENABLED = _bool;
  }

  function press(uint256 garmentID, uint256 inkID) external noContract {
    require(ENABLED, "Pressing is disabled");
    require(garmentNFT.ownerOf(garmentID) == msg.sender, "You do not own this garment");
    if (!REPRESSING_ENABLED) {
      require(presses[garmentID] == 0, "This garment has already been pressed");
    }
    inkNFT.safeTransferFrom(msg.sender, deadAddress, inkID);
    presses[garmentID] = inkID;
    emit Press(msg.sender, garmentID, inkID);
  }
}