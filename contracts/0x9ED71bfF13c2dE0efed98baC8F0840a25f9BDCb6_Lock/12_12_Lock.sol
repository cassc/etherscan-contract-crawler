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

    uint8 internal currentStage;

     struct Stage {
        uint256 start;
        uint256 end;
        uint256 amount;
        uint256 price;
    }

     mapping (uint8 => Stage) internal stages;

     struct Trait {
        uint256 offset;
        uint256 prize;
        uint256 amount;
        uint8 lockup;
        uint8 vesting;
        uint8 rate;
    }

    mapping(uint256 => Trait) internal traits;

    // nft token id => prize
    mapping(uint256 => uint256) internal prizes;

    // referral => stage => number of tokens
    mapping(address => mapping(uint8 => uint256)) public referrals;

    // stage => sum minted => reward rate
    mapping(uint8 => mapping(uint256 => uint256)) public refRewards;

    // NFT Collection contract address
    IERC721Extended public nft;

    // Payment token (USDT)
    IERC20Metadata public paymentToken;

    // Vesting token (CHO)
    IERC20Metadata public vestingToken;

    IVesting public vesting;

    event RecipientChanged(address newRecipient);
    event Minted(address owner, address refferal, uint256[] tokenId, uint8 stage);
    event Claimed(uint256 tokenId, uint256 amount, uint256 timestamp);
    
    constructor(IERC721Extended _nft, address _paymentToken, address _vestingToken, address _recipient, address _tokenWallet, address _vesting) { 
      nft = _nft;
      paymentToken = IERC20Metadata(_paymentToken);
      vestingToken = IERC20Metadata(_vestingToken);
      recipient = _recipient;
      tokenWallet = _tokenWallet;
      vesting = IVesting(_vesting);
      currentStage = 1;
    }

    /*
    * @dev NFT minting
    * @param _sender address of nft owner 
    * @param _refferal address of refferal 
    * @param _amount amount of nft to mint at once (less or equal to 20)    
    */
    function mint(address _sender, address _refferal, uint256 _amount) external whenNotPaused {
      require(!paused(), "Paused");
      require(currentStage >= 1 && currentStage <= 6, "Unsupported stage"); 
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
      _setPrizes(tokenIds);

      referrals[_refferal][currentStage] = tokenIds.length;

      emit Minted(_sender, _refferal, tokenIds, currentStage);
    }

    function airdrop(address[] memory _sender, address[] memory _refferal, uint256[] memory _amount) public whenNotPaused onlyOwner {
        require(!paused(), "Paused");
        require(currentStage >= 1 && currentStage <= 6, "Unsupported stage"); 
        uint256 freeAmount = stages[currentStage].amount - nft.getStageSupplies(currentStage);
        uint256 totalAmount;
        for (uint8 i = 0; i < _amount.length; i++) {
          totalAmount = totalAmount + _amount[i];
        }
        require(freeAmount >= totalAmount, "Stage nft limit exceeded");  
 
        uint256[] memory tokenIds;
        for (uint8 i = 0; i < _amount.length; i++) {
          tokenIds = nft.airdrop(_sender[i], _amount[i], currentStage); 
          _lock(_sender[i], tokenIds);
          _setPrizes(tokenIds);

          referrals[_refferal[i]][currentStage] = tokenIds.length;

          emit Minted(_sender[i], _refferal[i], tokenIds, currentStage);
        }
    }

    function _lock(address _sender, uint256[] memory _tokenIds) private {
      uint8 index;
      uint256 start;
      uint256 end;
      uint rate;
      uint256 amount;
      for(uint8 i = 0; i < _tokenIds.length; i++) {
        index = getTraitsType(_tokenIds[i]);
        require(index >=1 && index <=33, "Incorrect traits type");
        start = block.timestamp + traits[index].lockup * VESTING_PERIOD;
        end = start + traits[index].vesting * VESTING_PERIOD;
        rate = traits[index].rate;
        amount = reward.add(reward.mul(rate).div(100));
        vesting.createVestingWallet(
          _sender, 
          _tokenIds[i],
          block.timestamp, 
          start, 
          end, 
          traits[index].vesting, 
          amount
        );

      }
    }

    function setPrizes(uint256[] memory _tokenIds) public onlyOwner {
      _setPrizes(_tokenIds);
    }

    function _setPrizes(uint256[] memory _tokenIds) private {
      uint8 index;
      for (uint8 i = 0; i <  _tokenIds.length; i++) {
        index = getTraitsType(_tokenIds[i]);
        prizes[_tokenIds[i]] = traits[index].prize;
      }
    }

    function claimPrize(uint256 _id) public {
      require(msg.sender == nft.ownerOf(_id), "Not an owner");
      require(block.timestamp > stages[currentStage].end, "Stage not finished");
      uint8 index = getTraitsType(_id);
      require(prizes[_id] > 0 && traits[index].prize > 0, "No prize or already claimed");
      uint256 prize = prizes[_id].mul(tokenRate).mul((10 ** vestingToken.decimals()).div(10 ** paymentToken.decimals()));  
      prizes[_id] = 0;
      vestingToken.safeTransferFrom(tokenWallet, msg.sender, prize); 

      emit Claimed(_id, prize, block.timestamp); 
    }
 
    ///
    /// Stages
    ///

    /*
    * @dev Set stages
    * @param _start start of a stage (timestamp) 
    * @param _end end of a stage (timestamp)
    * @param _amount maximum amount of nft in a stage  
    * @param _price price of nft in a stage
    */
    function setStages(uint256[6] calldata _start, uint256[6] calldata _end, uint256[6] calldata _amount, uint256[6] calldata _price) public onlyOwner {
      Stage memory stage;
      for (uint8 i = 0; i < 6; i++) {
        stage = Stage({
          start: _start[i],
          end: _end[i],
          amount: _amount[i],
          price: _price[i]
        });
        stages[i + 1] = stage; // stages from 1 to 6
      }
    }

    function setCurrentStage(uint8 _stage) public onlyOwner {
      currentStage = _stage;
    }

    /* 
    * @dev Get stage info by number
    * @param _numStage number of stage (from 1 to 6)
    * @return Stage
    */
  function getStageInfo(uint8 _numStage) external view returns(Stage memory) {
    return stages[_numStage];
  }

    /*
    * @dev Set stage details
    * @param _numStage stage number (from 1 to 6)  
    * @param _start start of a stage (timestamp) 
    * @param _end end of a stage (timestamp)
    * @param _amount maximum amount to mint in a stage  
    * @param _price price of nft in a stage   
    */
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

    ///
    /// Traits
    ///

    /* 
    * @dev Set traits
    * @param _amount token amount
    * @param _lockup lockup period in months
    * @param _vesting vesting period in months
    * @param _rate extra rate %
    * @param _prize given prize
    * @param _offset token id offset, depends on token type
    */
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

    /* 
    * @dev Trait details
    * @param _type type of trait (from 1 to 33)
    */
    function getTraits(uint256 _type) public view returns (Trait memory) {
        return traits[_type];
    }

    /* 
    * @dev Traits type by nft id
    * @param _tokenId nft id 
    */
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

    function getReferralInfo(address _referral, uint8 _stage) external view returns(uint256) {
      return referrals[_referral][_stage];
    }

    function setRefRewards(uint8 _stage, uint256 _sum, uint256 _rate) public onlyOwner {
      refRewards[_stage][_sum] = _rate;
    }

    function setRate(uint256 _rate) public onlyOwner {
      tokenRate = _rate;
    }

    function setVesting(address _vesting) public onlyOwner {
      vesting = IVesting(_vesting);
    }

    ///
    /// Additional functions
    ///

    function changeRecipient(address newRecipient) external onlyOwner {
		  _changeRecipient(newRecipient);
	  }

    function _changeRecipient(address newRecipient) internal onlyOwner {
      recipient = newRecipient;
      emit RecipientChanged(newRecipient);
    }

    function getRecipient() external view returns(address) {
      return recipient;
    }

    function changeTokenWallet(address newTokenWallet) external onlyOwner {
		  _changeRecipient(newTokenWallet);
	  }

    function _changeTokenWallet(address newTokenWallet) internal onlyOwner {
      tokenWallet = newTokenWallet;
      emit RecipientChanged(newTokenWallet);
    }

    function getTokenWallet() external view returns(address) {
      return tokenWallet;
    }

    function pause() public onlyOwner {
      _pause();
    }

    function unpause() public onlyOwner {
      _unpause();
    }

}