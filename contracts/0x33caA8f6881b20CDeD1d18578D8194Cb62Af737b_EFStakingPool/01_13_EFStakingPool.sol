// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./IERC20UtilityToken.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";


contract EFStakingPool is AccessControl, ERC721Holder {
  
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  struct AccountRewardVars {
    uint32 lastUpdated;
    uint128 pointsBalance;
    uint64 totalStaked;
  }

  mapping(address => AccountRewardVars) public accountRewardVars;
  mapping(address => mapping(uint256 => bool)) public stakedNFTs;

  uint256 public rewardEndTime;
  uint256 public rewardRate;
  address public nftContractAddress;
  IERC20UtilityToken public rewardToken;
  
  constructor(uint256 _rewardRate, uint256 _rewardEndTime, address _nftContractAddress, address rewardTokenAddress) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    rewardEndTime = _rewardEndTime;
    rewardRate = _rewardRate;
    nftContractAddress = _nftContractAddress;
    rewardToken = IERC20UtilityToken(rewardTokenAddress);
  }

  modifier onlyOwner() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "caller is not an owner");
    _;
  }

  modifier onlyBurner() {
    require(hasRole(BURNER_ROLE, _msgSender()), "caller is not a burner");
    _;
  }

  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, _msgSender()), "caller is not a minter");
    _;
  }

  
  function balanceUpdate(address _owner, uint256 _valueStakedDiff, bool isSubtracted) internal {
    AccountRewardVars memory _rewardVars = accountRewardVars[_owner];

    if (lastTimeRewardApplicable() > _rewardVars.lastUpdated) {
      uint256 reward = calculateReward(_rewardVars.totalStaked, lastTimeRewardApplicable() - _rewardVars.lastUpdated);
      _rewardVars.pointsBalance += uint128(reward);
    }

    if (_valueStakedDiff != 0) {
      if (isSubtracted) {
        _rewardVars.totalStaked -=  uint64(_valueStakedDiff);
      } else {
        _rewardVars.totalStaked +=  uint64(_valueStakedDiff);
      }
    }
    
    _rewardVars.lastUpdated = uint32(block.timestamp);

    accountRewardVars[_owner] = _rewardVars;
  }

  function getStaked(address _owner) 
    public view returns(uint256) {
      return accountRewardVars[_owner].totalStaked;
  }

  function getStakedTokens(address _address, uint256 _cardCount) 
    external view returns (uint256[] memory tokens) {

      uint256[] memory _amounts = new uint256[](_cardCount);
      uint256 count;
      for (uint256 i = 1; i <= _cardCount; i++) {
        bool isStaked = stakedNFTs[_address][i];
        if (isStaked) {
          _amounts[count] = i;
          count++;
        }
      }

      uint256[] memory _amounts2 = new uint256[](count);
      for (uint256 i = 0; i < count; i++) {
        _amounts2[i] = _amounts[i];
      }

      return _amounts2;
  }
  
  function balanceOf(address _owner)
    public view returns(uint256) {
      uint256 reward = 0;
      if (lastTimeRewardApplicable() > accountRewardVars[_owner].lastUpdated) {
        reward = calculateReward(accountRewardVars[_owner].totalStaked, lastTimeRewardApplicable() - accountRewardVars[_owner].lastUpdated);
      }
      return accountRewardVars[_owner].pointsBalance + reward;
  }

  function setReward(uint256 _rewardRate)
    external onlyOwner {
      rewardRate = _rewardRate;
  }

  function setRewardEndTime(uint256 _rewardEndTime)
    external onlyOwner {
    rewardEndTime = _rewardEndTime;
  }

  function lastTimeRewardApplicable() public view returns (uint256) {
    return Math.min(block.timestamp, rewardEndTime);
  }

  function stake(uint256[] memory _tokenId)
    external {

      uint256 addedStakingValue = 0;

      for (uint256 i = 0; i < _tokenId.length; i++) {

        IERC721 tokenContract = IERC721(nftContractAddress);

        addedStakingValue += 1;

        tokenContract.safeTransferFrom(_msgSender(), address(this), _tokenId[i]);

        stakedNFTs[_msgSender()][_tokenId[i]] = true;
      }

      balanceUpdate(_msgSender(), addedStakingValue, false);
  }
  
  function unstake(uint256[] memory _tokenId)
    external {

      uint256 subtractedStakingValue = 0;

      for (uint256 i = 0; i < _tokenId.length; i++) {

        require(stakedNFTs[_msgSender()][_tokenId[i]], 'not the owner');

        IERC721 tokenContract = IERC721(nftContractAddress);

        subtractedStakingValue += 1;

        tokenContract.safeTransferFrom(address(this), _msgSender(), _tokenId[i]);

        stakedNFTs[_msgSender()][_tokenId[i]] = false;
      }

      balanceUpdate(_msgSender(), subtractedStakingValue, true);
  }
  
  function mint(address[] calldata _addresses, uint256[] calldata _points) 
    external onlyMinter {
      for (uint256 i = 0; i < _addresses.length; i++) {
        accountRewardVars[_addresses[i]].pointsBalance += uint128(_points[i]);
      }
  }
  
  function burn(address _owner, uint256 _amount) 
    external onlyBurner {
      balanceUpdate(_owner, 0, false);
      accountRewardVars[_owner].pointsBalance -= uint128(_amount);
  }
    
  function calculateReward(uint256 _amount, uint256 _duration) 
    private view returns(uint256) {
      uint256 rewardPerToken = _amount > 3 ? 45 : (_amount == 3 ? 40 : (_amount == 2 ? 36 : 30));
      return (rewardPerToken * _duration * rewardRate * _amount) / 30;
  }

  function withdrawReward(uint256 _amount) 
    external {
      balanceUpdate(_msgSender(), 0, false);
      accountRewardVars[_msgSender()].pointsBalance -= uint128(_amount);
      rewardToken.mint(_msgSender(), _amount);
  }

  function supportsInterface(bytes4 interfaceId) 
    public virtual override(AccessControl) view returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId
            || interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
  }

}