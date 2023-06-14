// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import { ERC721 } from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { Exit10 } from './Exit10.sol';
import { Artwork } from './artwork/Artwork.sol';

contract NFT is ERC721, Ownable {
  Exit10 public exit10;
  address public artwork;
  uint256 public immutable TRANSFER_LOCKOUT_PERIOD_SECONDS;
  uint256 public totalSupply;

  event SetExit10(address indexed caller, address exit10);
  event SetArtwork(address indexed caller, address artwork);

  modifier onlyAuthorized() {
    require(msg.sender == address(exit10), 'NFT: Caller must be Exit10');
    _;
  }

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 transferLockoutPeriodSeconds_
  ) ERC721(name_, symbol_) {
    TRANSFER_LOCKOUT_PERIOD_SECONDS = transferLockoutPeriodSeconds_;
  }

  function setExit10(address payable exit10_) external onlyOwner {
    require(address(exit10) == address(0), 'NFT: exit10 can only be set once');
    exit10 = Exit10(exit10_);
    emit SetExit10(msg.sender, exit10_);
  }

  function setArtwork(address artwork_) external onlyOwner {
    artwork = artwork_;
    emit SetArtwork(msg.sender, artwork_);
  }

  function mint(address recipient) external onlyAuthorized returns (uint256 tokenID) {
    tokenID = ++totalSupply;
    _mint(recipient, tokenID);
  }

  function tokenURI(uint256 tokenID) public view override returns (string memory) {
    require(_exists(tokenID), 'NFT: URI query for nonexistent token');
    return Artwork(artwork).tokenURI(tokenID);
  }

  function getBondAmount(uint256 tokenID) external view returns (uint256 tokenAmount) {
    (tokenAmount, , , , ) = exit10.getBondData(tokenID);
  }

  function getBondClaimed(uint256 tokenID) external view returns (uint256 claimedBLP) {
    (, claimedBLP, , , ) = exit10.getBondData(tokenID);
  }

  function getBondStartTime(uint256 tokenID) external view returns (uint256 startTime) {
    (, , startTime, , ) = exit10.getBondData(tokenID);
  }

  function getBondEndTime(uint256 tokenID) external view returns (uint256 endTime) {
    (, , , endTime, ) = exit10.getBondData(tokenID);
  }

  function getBondStatus(uint256 tokenID) external view returns (uint8 status) {
    (, , , , status) = exit10.getBondData(tokenID);
  }

  // Prevent transfers for a period of time after chickening in or out
  function _beforeTokenTransfer(address _from, address _to, uint256 _tokenID, uint256 _batchSize) internal override {
    if (_from != address(0)) {
      (, , , uint256 endTime, uint8 status) = exit10.getBondData(_tokenID);

      require(
        status == uint8(Exit10.BondStatus.active) || block.timestamp >= endTime + TRANSFER_LOCKOUT_PERIOD_SECONDS,
        'NFT: Cannot transfer during lockout period'
      );
    }

    super._beforeTokenTransfer(_from, _to, _tokenID, _batchSize);
  }
}