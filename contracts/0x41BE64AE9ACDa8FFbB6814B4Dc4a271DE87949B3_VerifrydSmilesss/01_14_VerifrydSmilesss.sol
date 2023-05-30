// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// All Smilesss LLC (www.smilesss.com)
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*********************************ALLSMILESSS**********************************@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@&(**********/%@@@@@@@@@@@@@@*******************************&(@@@@@@@@@@/%*******************************@@@@@@@@@@@@@&(**********/%@@@@@@@@@@@@@@@@
// @@@@@@@@@@@(********************/&@@@@@@@@@@**************************(@@@@@@@@@@@@@@@@@@@@/&*************************@@@@@@@@@@(********************/&@@@@@@@@@@@
// @@@@@@@@%**************************/@@@@@@@@@**********************%@@@@@@@@@@@@@@@@@@@@@@@@@@/**********************@@@@@@@@%**************************/@@@@@@@@@
// @@@@@@&******************************(@@@@@@@@*******************&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(*******************@@@@@@@&******************************(@@@@@@@
// @@@@@#********************#(***********@@@@@@@@*****************#@@@@@@@@@@@@@@@@@@@@#(@@@@@@@@@@@*****************@@@@@@@#********************#(***********@@@@@@
// @@@@#********************/@@%***********@@@@@@@@***************#@@@@@@@@@@@@@@@@@@@@/**%@@@@@@@@@@@***************@@@@@@@#********************/@@%***********@@@@@
// @@@@/*****@@@@@/*@@@@@%***#@@#***********%@@@@@@@**************/@@@@@*****/@*****%@@@#**#@@@@@@@@@@@%************@@@@@@@@/*****@@@@@/*@@@@@%***#@@#***********%@@@
// @@@@******@@@@@/*@@@@@*****@@@**********#@@@@@@@@@*************@@@@@@*****/@*****@@@@@***@@@@@@@@@@#************@@@@@@@@@******@@@@@/*@@@@@*****@@@**********#@@@@
// @@@@/**********************@@@**********%@@@@@@@@@@************/@@@@@@@@@@@@@@@@@@@@@@***@@@@@@@@@@%***********@@@@@@@@@@/**********************@@@**********%@@@@
// @@@@%*****@@@@@/*@@@@@****#@@#*********(@@@@@@@@@@@@***********%@@@@@*****/@*****@@@@#**#@@@@@@@@@(***********@@@@@@@@@@@%*****@@@@@/*@@@@@****#@@#*********(@@@@@
// @@@@@&****@@@@@/*@@@@@***/@@%*********/@@@@@@@@@@@@@@***********&@@@@*****/@*****@@@/**%@@@@@@@@@/***********@@@@@@@@@@@@@&****@@@@@/*@@@@@***/@@%*********/@@@@@@
// @@@@@@@/******************#(*********%@@@@@@@@@@@@@@@@************/@@@@@@@@@@@@@@@@@@#(@@@@@@@@@%***********@@@@@@@@@@@@@@@@/******************#(*********%@@@@@@@
// @@@@@@@@@/*************************&@@@@@@@@@@@@@@@@@@@*************/@@@@@@@@@@@@@@@@@@@@@@@@@&************@@@@@@@@@@@@@@@@@@@/*************************&@@@@@@@@@
// @@@@@@@@@@@@(*******************%@@@@@@@@@@@@@@@@@@@@@@@***************(@@@@@@@@@@@@@@@@@@@%**************@@@@@@@@@@@@@@@@@@@@@@@(*******************%@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@&%(//***/(#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@******************&%(//@@@/(#&******************@@@@@@@@@@@@@@@@@@@@@@@@@@@@&%(//***/(#&@@@@@@@@@@@@@@@@@
// @@[email protected]@@@@@@@@@@@[email protected]@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@[email protected]@@@@@@@@@@@@*O*************R*************C**************R*@@@@@@@@@@@@[email protected]@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@[email protected]@

// Project: Verifry'd Smilesss
// Artist: Verifry'd

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract VerifrydSmilesss is ERC721Enumerable, Ownable, ReentrancyGuard {
  using Strings for uint256;

  bool public isActive = false;
  ERC721 Smilesssvrs = ERC721(0x177EF8787CEb5D4596b6f011df08C86eb84380dC);

  // ERC721 params
  string private tokenName = "Verifry'd Smilesss";
  string private tokenId = 'VSSS';
  string private _baseTokenURI = 'http://www.smilesss.com/api/gif/';

  // Withdraw address
  address private withdraw_address = 0xe5eFA11dfe58E21f505CE88B269BADb6c00ABb2F;

  // Collection params
  uint256 public constant TOT = 8888;

  // Utils
  mapping(address => bool) public claimedAddresses;

  // Event declaration
  event MintEvent(uint256 indexed id);
  event ChangedActiveEvent(bool newActive);
  event ChangedBaseURIEvent(string newURI);
  event ChangedWithdrawAddress(address newAddress);

  // Constructor
  constructor() ERC721(tokenName, tokenId) {}

  // Private mint function
  function mint(uint256 _id) external nonReentrant {
    require(isActive, "not active");
    require(_id > 0 && _id <= TOT, 'Invalid token id');
    require(Smilesssvrs.ownerOf(_id) == msg.sender, 'You do not own the correspondent Smilesss');
    require(!claimedAddresses[msg.sender], 'Only one free claim per wallet');
    require(!_exists(_id), 'Token already claimed');
    
    claimedAddresses[msg.sender] = true;
    _safeMint(msg.sender, _id);
    emit MintEvent(_id);
  }
 
  // Setters
  function setActive(bool _active) external onlyOwner {
    isActive = _active;
    emit ChangedActiveEvent(_active);
  }

  function setBaseURI(string memory _URI) public onlyOwner {
    _baseTokenURI = _URI;
    emit ChangedBaseURIEvent(_URI);
  }

  function setWithdrawAddress(address _withdraw) external onlyOwner {
    withdraw_address = _withdraw;
    emit ChangedWithdrawAddress(_withdraw);
  }

  function tokenExists(uint256 _tokenId) public view returns (bool) {
    return _exists(_tokenId);
  }

  // URI
  function tokenURI(uint256 _tokenId)
    public
    view
    override(ERC721)
    returns (string memory)
  {
    require(_exists(_tokenId), 'Token does not exist');
    return string(abi.encodePacked(_baseTokenURI, _tokenId.toString()));
  }

  // Withdraw function
  function withdrawAll() external payable onlyOwner {
    require(address(this).balance != 0, 'Balance is zero');
    require(payable(withdraw_address).send(address(this).balance));
  }
}