// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

import './EverydayRenderer.sol';

/*
                              (
      (   )     (  (   (     )\ )   ) (
      ))\ /((   ))\ )(  )\ ) (()/(( /( )\ )
    /((_|_))\ /((_|()\(()/(  ((_))(_)|()/(
    (_)) _)((_|_))  ((_))(_)) _| ((_)_ )(_))
    / -_)\ V // -_)| '_| || / _` / _` | || |
    \___| \_/ \___||_|  \_, \__,_\__,_|\_, |
                        |__/           |__/

              -> everyday.photo <-
*/

contract Everyday is ERC721, AccessControl, IEverydayRenderer {
  // Everyday contract created by Jacob Bijani <bijani.com> for Noah Kalina <noahkalina.com>

  using Address for address payable;
  using Math for uint256;

  bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');

  address public rendererAddress;

  uint256 public price = 0.05 ether;
  uint256 public limitPerTnx = 365;

  uint256 public highestTokenId;

  address private walletNoah;
  address private walletJacob;
  address private walletHenry;
  address private walletMatt;

  // split percent as basis points (e.g 250 is 2.5%). noah gets remainder.
  uint256 private splitJacob = 1500; // 15%
  uint256 private splitHenry = 750; // 7.5%
  uint256 private splitMatt = 750; // 7.5%

  constructor() ERC721('Everyday', 'DAY') {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MANAGER_ROLE, msg.sender);
  }

  function setRendererAddress(address to) external onlyRole(DEFAULT_ADMIN_ROLE) {
    rendererAddress = to;
  }

  function render(uint256 tokenId) public view override returns (string memory) {
    return IEverydayRenderer(rendererAddress).render(tokenId);
  }

  // delegate tokenURI to renderer contract
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), 'ERC721: invalid token ID');
    return render(tokenId);
  }

  function setPrice(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
    price = amount;
  }

  function setWallets(
    address noah,
    address jacob,
    address henry,
    address matt
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    walletNoah = noah;
    walletJacob = jacob;
    walletHenry = henry;
    walletMatt = matt;

    _grantRole(MANAGER_ROLE, noah);
    _grantRole(MANAGER_ROLE, jacob);
    _grantRole(MANAGER_ROLE, henry);
    _grantRole(MANAGER_ROLE, matt);
  }

  function setSplits(
    uint256 jacob,
    uint256 henry,
    uint256 matt
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(jacob >= 0 && henry >= 0 && matt >= 0, 'invalid input');

    splitJacob = jacob;
    splitHenry = henry;
    splitMatt = matt;
  }

  function setLimitPerTnx(uint256 amount) external onlyRole(MANAGER_ROLE) {
    limitPerTnx = amount;
  }

  function setHighestTokenId(uint256 tokenId) external onlyRole(MANAGER_ROLE) {
    // validate input
    require(tokenId > 0 && tokenId > highestTokenId, 'invalid input');

    // set new value
    highestTokenId = tokenId;
  }

  function mint(uint256 tokenId) external payable {
    // ensure price is met
    require(msg.value >= price, 'price not met');

    // ensure token is mintable
    require(tokenId > 0 && tokenId <= highestTokenId, 'invalid tokenId');

    // mint token to caller
    _mint(_msgSender(), tokenId);
  }

  function multiMint(uint256[] calldata tokenIds) external payable {
    // ensure price is met
    require(msg.value >= price * tokenIds.length, 'price not met');

    // ensure amount is within limit
    require(tokenIds.length <= limitPerTnx, 'limit exceeded');

    // track msg.value actually spent
    uint256 balance = msg.value;

    // attempt to mint each tokenId
    for (uint256 i = 0; i < tokenIds.length; i++) {
      if (tokenIds[i] > 0 && tokenIds[i] <= highestTokenId && !_exists(tokenIds[i])) {
        _mint(_msgSender(), tokenIds[i]);
        balance -= price;
      }
    }

    // return remaining balance to caller
    if (balance > 0) payable(_msgSender()).sendValue(balance);
  }

  function adminMint(uint256[] calldata tokenIds, address to) external onlyRole(DEFAULT_ADMIN_ROLE) {
    // mint tokens for free
    for (uint256 i = 0; i < tokenIds.length; i++) {
      if (tokenIds[i] > 0 && !_exists(tokenIds[i])) {
        _mint(to, tokenIds[i]);
      }
    }
  }

  function withdraw() external onlyRole(MANAGER_ROLE) {
    require(
      walletNoah != address(0x0) && walletJacob != address(0x0) && walletHenry != address(0x0) && walletMatt != address(0x0),
      'null wallets'
    );

    uint256 total = address(this).balance;
    require(total > 0, 'zero balance');

    uint256 totalJacob = Math.mulDiv(total, splitJacob, 10000);
    uint256 totalHenry = Math.mulDiv(total, splitHenry, 10000);
    uint256 totalMatt = Math.mulDiv(total, splitMatt, 10000);
    uint256 totalNoah = total - totalJacob - totalHenry - totalMatt;

    // distribute funds
    payable(walletNoah).sendValue(totalNoah);
    payable(walletJacob).sendValue(totalJacob);
    payable(walletHenry).sendValue(totalHenry);
    payable(walletMatt).sendValue(totalMatt);
  }

  // === REQUIRED OVERRIDES ===

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}