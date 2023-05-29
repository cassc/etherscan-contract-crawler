// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract DDDProxy is Pausable, AccessControl, ReentrancyGuard, IERC721Receiver {
  uint256 public constant DDD_ORIGINAL_PRICE = 0.0666 ether;

  uint256 public limitPerWL = 2;
  uint256 public limitPerWallet = 3;
  uint256 public limitPerNFT = 1;
  uint256 public limitPerCall = limitPerWallet;
  uint256 public highestWhitelistedNftId = 2826;

  uint256 public whitelistedMintPrice = 0.005 ether;
  uint256 public nftOwnerMintPrice = 0.005 ether;
  uint256 public publicMintPrice = 0.0666 ether;

  mapping(address => bool) public isWhiteListed;

  mapping(address => uint256) public mintedByWL;
  mapping(address => uint256) public mintedByWallet;
  mapping(uint256 => uint256) public mintedByNFT;

  IDDD public dddContract = IDDD(0x6Ac645FdA81299c8eB0da31fc773953752112E82);

  modifier notContract() {
    require(!Address.isContract(msg.sender), "contract");
    _;
  }

  modifier mintRequire(uint256 _amount) {
    require(_amount <= limitPerCall, "amount too high");
    require(
      address(this).balance >= DDD_ORIGINAL_PRICE,
      "not enough ETH in contract"
    );
    _;
  }

  modifier whitelistLimit(uint256 _amount) {
    require(mintedByWL[msg.sender] + _amount <= limitPerWL, "wl limit reached");
    mintedByWL[msg.sender] += _amount;
    _;
  }

  modifier walletLimit(uint256 _amount) {
    require(
      mintedByWallet[msg.sender] + _amount <= limitPerWallet,
      "wallet limit reached"
    );
    mintedByWallet[msg.sender] += _amount;
    _;
  }

  modifier valueCheck(uint256 _amount, uint256 _price) {
    require(msg.value == _amount * _price, "wrong amount/value");
    _;
  }

  modifier whitelisted() {
    require(isWhiteListed[msg.sender], "not isWhiteListed");
    _;
  }

  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function _mintAll(uint256 _amount) private {
    for (uint256 i = 0; i < _amount; i++) {
      try dddContract.mint{value: DDD_ORIGINAL_PRICE}(1) {
        uint256 tokenId = dddContract.tokenOfOwnerByIndex(address(this), 0);
        dddContract.safeTransferFrom(address(this), msg.sender, tokenId);
        dddContract.emergencyWithdraw();
      } catch {
        revert("external call failed");
      }
    }
  }

  function nftLimit(uint256 _amount, uint256[] memory _ids) private {
    uint256 freeSum = 0;
    uint256 length = _ids.length;
    for (uint256 i = 0; i < length; i++) {
      uint256 tokenId = _ids[i];
      if (
        tokenId > highestWhitelistedNftId ||
        dddContract.ownerOf(tokenId) != msg.sender
      ) {
        continue;
      }
      uint256 diff = limitPerNFT - mintedByNFT[tokenId];
      freeSum += diff;
      mintedByNFT[tokenId] += diff;
      if (freeSum >= _amount) {
        mintedByNFT[tokenId] -= freeSum - _amount; // adjust to correct value
        return;
      }
    }
    revert("nft limit reached");
  }

  function mintWL(uint256 _amount)
    public
    payable
    whenNotPaused
    nonReentrant
    notContract
    mintRequire(_amount)
    whitelistLimit(_amount)
    walletLimit(_amount)
    valueCheck(_amount, whitelistedMintPrice)
    whitelisted
  {
    _mintAll(_amount);
  }

  function mintNFT(uint256 _amount, uint256[] memory _ids)
    public
    payable
    whenNotPaused
    nonReentrant
    notContract
    mintRequire(_amount)
    walletLimit(_amount)
    valueCheck(_amount, nftOwnerMintPrice)
  {
    nftLimit(_amount, _ids);
    _mintAll(_amount);
  }

  function mintPublic(uint256 _amount)
    public
    payable
    whenNotPaused
    nonReentrant
    notContract
    mintRequire(_amount)
    valueCheck(_amount, publicMintPrice)
  {
    _mintAll(_amount);
  }

  function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }

  function whitelistToggle(address[] memory _address)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    uint256 length = _address.length;

    for (uint256 i = 0; i < length; i++) {
      address toWhitelist = _address[i];
      isWhiteListed[toWhitelist] = !isWhiteListed[toWhitelist];
    }
  }

  function setPrice(
    uint256 _whitelistedMintPrice,
    uint256 _nftOwnerMintPrice,
    uint256 _publicMintPrice
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    whitelistedMintPrice = _whitelistedMintPrice;
    nftOwnerMintPrice = _nftOwnerMintPrice;
    publicMintPrice = _publicMintPrice;
  }

  function setLimits(
    uint256 _limitPerWL,
    uint256 _limitPerWallet,
    uint256 _limitPerNFT,
    uint256 _limitPerCall,
    uint256 _highestWhitelistedNftId
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    limitPerWL = _limitPerWL;
    limitPerWallet = _limitPerWallet;
    limitPerNFT = _limitPerNFT;
    limitPerCall = _limitPerCall;
    highestWhitelistedNftId = _highestWhitelistedNftId;
  }

  function setDDD(IDDD _dddContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
    dddContract = _dddContract;
  }

  function proxyTransferOwnership(address _newOwner)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    dddContract.transferOwnership(_newOwner);
  }

  function emergencyWithdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
    (bool success, ) = payable(msg.sender).call{
      value: address(this).balance,
      gas: 30_000
    }(new bytes(0));
    require(success, "failed");
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) returns (bytes4) {
    return this.onERC721Received.selector;
  }

  receive() external payable {}
}

abstract contract IDDD {
  function mint(uint256 amount) external payable virtual;

  function ownerOf(uint256 id) external virtual returns (address _owner);

  function transferOwnership(address newOwner) public virtual;

  function tokenOfOwnerByIndex(address owner, uint256 index)
    external
    view
    virtual
    returns (uint256);

  function safeTransferFrom(
    address,
    address,
    uint256
  ) external virtual;

  function emergencyWithdraw() external virtual;
}