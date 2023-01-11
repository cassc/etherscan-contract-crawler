// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Extended is IERC721 {
  function airdrop(address _to, uint256 _amount, uint8 _stage) external returns (uint256[] memory);
  function getMintingStatus() external view returns(bool);
  function getStageSupplies(uint8 _stage) external view returns(uint256);
}

interface IVesting {
  function createVestingWallet(
    address beneficiary,
    uint256 id,
    uint256 lockup,
    uint256 start,
    uint256 end,
    uint256 periods,
    uint256 totalAmount
  )
    external;
}

contract Lock is Ownable, Pausable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20Metadata;

  // payments recipient
  address internal recipient; 
  address internal tokenWallet; 
  uint256 public tokenRate;
  uint256 public immutable VESTING_PERIOD = 2592000; // 30 days in seconds
  uint256 public reward = 1000 ether;

  struct Stage {
    uint256 start;
    uint256 end;
    uint256 amount;
    uint256 price;
  }

  struct Trait {
    uint256 offset;
    uint256 prize;
    uint256 amount;
    uint8 lockup;
    uint8 vesting;
    uint8 rate;
  }

  mapping (uint8 => Stage) internal stages;
  mapping(uint256 => Trait) internal traits;

  uint8 internal currentStage;
  uint8 internal maxStage;

  // NFT Collection contract address
  IERC721Extended public nft;

  // Payment token (USDT)
  IERC20Metadata public paymentToken;

  // Vesting token (CHO)
  IERC20Metadata public vestingToken;

  IVesting public vesting;

  event RecipientChanged(address newRecipient);
  event TokenWalletChanged(address newTokenWallet);
  event Minted(address owner, address referral, uint256[] tokenId, uint256 payment, uint8 stage);
  event ERC20Transfered(address sender, address to, uint256 amount);

  constructor(address _nft, address _paymentToken, address _vestingToken, address _recipient, 
  address _tokenWallet, address _vesting, uint8 _stage, uint8 _maxStage) { 
    nft = IERC721Extended(_nft);
    paymentToken = IERC20Metadata(_paymentToken);
    vestingToken = IERC20Metadata(_vestingToken);
    recipient = _recipient;
    tokenWallet = _tokenWallet;
    vesting = IVesting(_vesting);
    currentStage = _stage;
    maxStage = _maxStage;
  }

  function mint(address _sender, address _referral, uint256 _amount) external whenNotPaused {
    require(!paused(), "Paused");
    require(currentStage >= 1 && currentStage <= maxStage, "Unsupported stage"); 
    require(_amount > 0, "Zero amount");  
    uint256 freeAmount = stages[currentStage].amount - nft.getStageSupplies(currentStage);
    require(freeAmount >= _amount, "Stage nft limit exceeded");  
    
    uint256 payment = stages[currentStage].price.mul(_amount);
    require(payment > 0, "Zero payment");
    require(paymentToken.allowance(msg.sender, address(this)) >= payment, "Payment is not approved");
    paymentToken.safeTransferFrom(_sender, recipient, payment);
    
    uint256[] memory tokenIds;
    tokenIds = nft.airdrop(_sender, _amount, currentStage); 
    _lock(_sender, tokenIds);

    emit Minted(_sender, _referral, tokenIds, payment, currentStage);
  }

  function airdrop(address[] memory _sender, address[] memory _referral, uint256[] memory _amount) public whenNotPaused onlyOwner {
    require(currentStage >= 1 && currentStage <= maxStage, "Unsupported stage"); 
    uint256 freeAmount = stages[currentStage].amount - nft.getStageSupplies(currentStage);
    uint256 totalAmount;
    uint256 payment;
    for (uint8 i = 0; i < _amount.length; i++) {
      totalAmount = totalAmount + _amount[i];
    }
    require(freeAmount >= totalAmount, "Stage nft limit exceeded");  

    uint256[] memory tokenIds;
    for (uint8 i = 0; i < _amount.length; i++) {
      tokenIds = nft.airdrop(_sender[i], _amount[i], currentStage); 
      _lock(_sender[i], tokenIds);
      payment = stages[currentStage].price.mul(_amount[i]);

      emit Minted(_sender[i], _referral[i], tokenIds, payment, currentStage);
    }
  }

  function _lock(address _sender, uint256[] memory _tokenIds) private {
    uint8 index;
    uint256 start;
    uint256 end;
    uint rate;
    uint256 amount;
    uint256 periods;
    uint256 lock = 0;
    for(uint8 i = 0; i < _tokenIds.length; i++) {
      index = getTraitsType(_tokenIds[i]);
      require(index >=1 && index <=33, "Incorrect traits type");
      start = block.timestamp + traits[index].lockup * VESTING_PERIOD;
      end = start + traits[index].vesting * VESTING_PERIOD;
      rate = traits[index].rate;
      periods = traits[index].vesting == lock ? 1 : traits[index].vesting;
      amount = reward.add(reward.mul(rate).div(100));
      vesting.createVestingWallet(
        _sender, 
        _tokenIds[i],
        block.timestamp, 
        start, 
        end, 
        periods, 
        amount
      );
    }
  }

  ///
  /// Stages
  ///

  function setStages(uint256[6] calldata _start, uint256[6] calldata _end, uint256[6] calldata _amount, uint256[6] calldata _price) public onlyOwner {
    Stage memory stage;
    for (uint8 i = 0; i < maxStage; i++) {
      stage = Stage({
        start: _start[i],
        end: _end[i],
        amount: _amount[i],
        price: _price[i]
      });
      stages[i + 1] = stage; // stages from 1 to maxStage
    }
  }

  function getMaxStage() public view returns(uint256) {
    return maxStage;
  }

  function setMaxStage(uint8 _maxStage) public onlyOwner {
    maxStage = _maxStage;
  }

  function getCurrentStage() external view returns(uint8) {
    return currentStage;
  }

  function setCurrentStage(uint8 _stage) public onlyOwner {
    currentStage = _stage;
  }

  function getStageInfo(uint8 _numStage) external view returns(Stage memory) {
    return stages[_numStage];
  }

  function setStageInfo(uint8 _numStage, uint256 _start, uint256 _end, uint256 _amount, uint256 _price) external onlyOwner {
    Stage memory stage;
    stage = Stage({
      start: _start,
      end: _end,
      amount: _amount,
      price: _price
    });
    stages[_numStage] = stage; 
  }

  function getStageStart(uint8 _numStage) public view returns(uint256) {
    return stages[_numStage].start;
  }

  function getStageEnd(uint8 _numStage) public view returns(uint256) {
    return stages[_numStage].end;
  }

  function getStageByTimestamp(uint256 _timestamp) public view returns(uint8) {
    if ((_timestamp > getStageEnd(maxStage)) || (_timestamp < getStageStart(1))) {
      return 0;
    }
    for (uint8 i = maxStage; i > 0; i--) {
      if (_timestamp >= getStageStart(i) && _timestamp <= getStageEnd(i)) {
        return i;
      }
    }
    return 0;
  }

  ///
  /// Traits
  ///

  function setTraits(uint256[33] calldata _amount, uint8[33] calldata _lockup, uint8[33] calldata _vesting, uint8[33] calldata _rate, uint256[33] calldata _prize, uint256[33] calldata _offset) public onlyOwner {
    Trait memory trait;
    for (uint8 i = 0; i < 33; i++) {
      trait = Trait({
        prize: _prize[i],
        amount: _amount[i],
        lockup: _lockup[i],
        vesting: _vesting[i],
        rate: _rate[i],
        offset: _offset[i]
      });
      traits[i + 1] = trait; // trait types from 1 to 33
    }
  }

  function getTraits(uint256 _type) public view returns (Trait memory) {
    return traits[_type];
  }

  function getTraitsType(uint256 _tokenId) public view returns (uint8) {
    if (_tokenId > 130000) {
      return 0;
    }
    for(uint8 i = 1; i < 34; i++) {
      if (_tokenId > traits[i].offset)
        return i;
    }
    return 0;
  }

  ///
  /// Additional functions
  ///

  function getRate() public view returns(uint256) {
    return tokenRate;
  }

  function setRate(uint256 _rate) public onlyOwner {
    tokenRate = _rate;
  }

  function getPrize(uint256 _tokenId) external view returns (uint256) {
    return getTraits(getTraitsType(_tokenId)).prize;
  }

  function setVesting(address _vesting) public onlyOwner {
    vesting = IVesting(_vesting);
  }

  function setRecipient(address newRecipient) external onlyOwner {
    recipient = newRecipient;
    emit RecipientChanged(newRecipient);
  }

  function getRecipient() external view returns(address) {
    return recipient;
  }

  function setTokenWallet(address newTokenWallet) external onlyOwner {
    tokenWallet = newTokenWallet;
    emit TokenWalletChanged(newTokenWallet);
  }

  function getTokenWallet() external view returns(address) {
    return tokenWallet;
  }

  function transferERC20(IERC20 _token, address _to, uint _amount) external onlyOwner {
    uint256 amount = _token.balanceOf(address(this));
    require(_amount <= amount, "Insufficient balance");
    _token.transfer(_to, _amount);
    emit ERC20Transfered(msg.sender, _to, _amount);
  }
  
  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }
}