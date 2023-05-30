// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "hardhat/console.sol";

interface IVesting { 
  struct VestingWallet{
    address beneficiary;
    uint256 lockup;
    uint256 start;
    uint256 end;
    uint256 periods;
    uint256 totalAmount;
    uint256 claimed;
  } 
  function getVestingWallet(uint256 _id) external view returns(VestingWallet memory);
}

interface ILock {
  function getCurrentStage() external view returns(uint8); 
  function getStageByTimestamp(uint256 _timestamp) external view returns(uint8);
  function getPrize(uint256 _tokenId) external view returns (uint256); 
  function getRate() external view returns(uint256); 
}

interface ICalc {
  function convertToken(uint256 _amount, uint256 _rate) external view returns(uint256);
}

contract Prize is Ownable, Pausable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20Metadata; 

  uint8 public claimStage;

  // nft id => prize amount
  mapping(uint256 => uint256) public claimedPrizes;

  IERC20Metadata public paymentToken; 
  IERC20Metadata public prizeToken; 
  ICalc public calc; 

  address internal prizeWallet; 

  // NFT Collection contract 
  IERC721 public nft;

  // vestingcontract 
  IVesting public vesting;

  // Lock contract   
  ILock public lockContract;

  event PrizeClaimed(uint256 id, address owner, uint256 amount, uint256 timestamp, uint8 curStage, uint8 claimStage);
  event PrizeWalletChanged(address newPrizeWallet);
  event CalcContractChanged(address newCalcContract);
  event VestingContractChanged(address newVestingContract);

  constructor (address _nft, address _prizeToken, address _paymentToken, address _calc, address _vesting, address _lockContract, address _prizeWallet) {
    nft = IERC721(_nft);
    paymentToken = IERC20Metadata(_paymentToken);
    prizeToken = IERC20Metadata(_prizeToken);
    calc = ICalc(_calc);
    vesting = IVesting(_vesting);
    lockContract = ILock(_lockContract);
    prizeWallet = _prizeWallet;
  }

  function claimPrize(uint256 _tokenId) public whenNotPaused nonReentrant returns(uint256) {
    require(msg.sender == nft.ownerOf(_tokenId), "Not an owner");
    require(lockContract.getPrize(_tokenId) > 0, "No prize for given nft id");
    require(claimedPrizes[_tokenId] == 0, "Prize already claimed");
    uint256 lockup = vesting.getVestingWallet(_tokenId).lockup;
    uint8 mintStage = lockContract.getStageByTimestamp(lockup);
    require((mintStage > 0) && (mintStage <= claimStage), "Wrong claim stage");
    uint256 prize = calc.convertToken(lockContract.getPrize(_tokenId), lockContract.getRate());
    require(paymentToken.balanceOf(prizeWallet) >= prize, "Insufficient funds in a prize wallet");
    claimedPrizes[_tokenId] = prize;
    paymentToken.safeTransferFrom(prizeWallet, msg.sender, prize); 

    emit PrizeClaimed(_tokenId, msg.sender, prize, block.timestamp, lockContract.getCurrentStage(), claimStage); 
    return prize;
  }

  function setClaimedPrize(uint256 _tokenId, uint256 _amount) public onlyOwner {
    claimedPrizes[_tokenId] = _amount;
  }

  function getClaimedPrize(uint256 _tokenId) external view returns(uint256) {
    return claimedPrizes[_tokenId];
  }

  function getClaimStage() external view returns(uint8) {
    return claimStage;
  }

  function setClaimStage(uint8 _stage) public onlyOwner {
    claimStage = _stage;
  }

  function setPrizeWallet(address newPrizeWallet) external onlyOwner {
	prizeWallet = newPrizeWallet;
    emit PrizeWalletChanged(newPrizeWallet);
  }

  function getPrizeWallet() external view returns(address) {
    return prizeWallet;
  }

  function setCalcContract(address newCalcContract) external onlyOwner {
    calc = ICalc(newCalcContract);
    emit CalcContractChanged(newCalcContract);
  }

  function setVestingContract(address newVestingContract) external onlyOwner {
    vesting = IVesting(newVestingContract);
    emit VestingContractChanged(newVestingContract);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

}