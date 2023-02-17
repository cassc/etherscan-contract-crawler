/******************************************************************************************************
YDFStake Inheritable Contract for staking NFTs

Website: https://yieldification.com
Twitter: https://twitter.com/yieldification
Telegram: https://t.me/yieldification
******************************************************************************************************/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './interfaces/IYDF.sol';
import './interfaces/IYDFVester.sol';
import './interfaces/IStakeRewards.sol';

contract YDFStake is ERC721Enumerable, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  uint256 private constant ONE_YEAR = 365 days;
  uint256 private constant ONE_WEEK = 7 days;
  uint16 private constant PERCENT_DENOMENATOR = 10000;

  IERC20 internal stakeToken;
  IYDF internal ydf;
  IYDFVester internal vester;
  IStakeRewards internal rewards;

  struct AprLock {
    uint16 apr;
    uint256 lockTime;
  }
  AprLock[] internal _aprLockOptions;

  struct Stake {
    uint256 created;
    uint256 amountStaked;
    uint256 amountYDFBaseEarn;
    uint16 apr;
    uint256 lockTime;
  }
  // tokenId => Stake
  mapping(uint256 => Stake) public stakes;
  // tokenId => amount
  mapping(uint256 => uint256) public yieldClaimed;
  // tokenId => timestamp
  mapping(uint256 => uint256) public lastClaim;
  // tokenId => boolean
  mapping(uint256 => bool) public isBlacklisted;

  Counters.Counter internal _ids;
  string private baseTokenURI; // baseTokenURI can point to IPFS folder like https://ipfs.io/ipfs/{cid}/ while
  address public paymentAddress;
  address public royaltyAddress;

  // Royalties basis points (percentage using 2 decimals - 1000 = 100, 500 = 50, 0 = 0)
  uint256 private royaltyBasisPoints = 50; // 5%

  // array of all the NFT token IDs owned by a user
  mapping(address => uint256[]) public allUserOwned;
  // the index in the token ID array at allUserOwned to save gas on operations
  mapping(uint256 => uint256) public ownedIndex;

  mapping(uint256 => uint256) public tokenMintedAt;
  mapping(uint256 => uint256) public tokenLastTransferred;

  event StakeTokens(
    address indexed user,
    uint256 indexed tokenId,
    uint256 amountStaked,
    uint256 lockOptionIndex
  );
  event UnstakeTokens(address indexed user, uint256 indexed tokenId);
  event SetAnnualApr(uint256 indexed newApr);
  event SetPaymentAddress(address indexed user);
  event SetRoyaltyAddress(address indexed user);
  event SetRoyaltyBasisPoints(uint256 indexed _royaltyBasisPoints);
  event SetBaseTokenURI(string indexed newUri);
  event AddAprLockOption(uint16 indexed apr, uint256 lockTime);
  event RemoveAprLockOption(
    uint256 indexed index,
    uint16 indexed apr,
    uint256 lockTime
  );
  event UpdateAprLockOption(
    uint256 indexed index,
    uint16 indexed oldApr,
    uint256 oldLockTime,
    uint16 newApr,
    uint256 newLockTime
  );
  event SetTokenBlacklist(uint256 indexed tokenId, bool isBlacklisted);

  constructor(
    string memory _name,
    string memory _symbol,
    address _stakeToken,
    address _ydf,
    address _vester,
    address _rewards,
    string memory _baseTokenURI
  ) ERC721(_name, _symbol) {
    stakeToken = IERC20(_stakeToken);
    ydf = IYDF(_ydf);
    vester = IYDFVester(_vester);
    rewards = IStakeRewards(_rewards);
    baseTokenURI = _baseTokenURI;
  }

  function stake(uint256 _amount, uint256 _lockOptIndex) external virtual {
    _stake(msg.sender, _amount, _amount, _lockOptIndex, true);
  }

  function _stake(
    address _user,
    uint256 _amountStaked,
    uint256 _amountYDFBaseEarn,
    uint256 _lockOptIndex,
    bool _transferStakeToken
  ) internal {
    require(_lockOptIndex < _aprLockOptions.length, 'invalid lock option');
    _amountStaked = _amountStaked == 0
      ? stakeToken.balanceOf(_user)
      : _amountStaked;
    _amountYDFBaseEarn = _amountYDFBaseEarn == 0
      ? _amountStaked
      : _amountYDFBaseEarn;
    require(
      _amountStaked > 0 && _amountYDFBaseEarn > 0,
      'must stake and be earning at least some tokens'
    );
    if (_transferStakeToken) {
      stakeToken.transferFrom(_user, address(this), _amountStaked);
    }

    _ids.increment();
    stakes[_ids.current()] = Stake({
      created: block.timestamp,
      amountStaked: _amountStaked,
      amountYDFBaseEarn: _amountYDFBaseEarn,
      apr: _aprLockOptions[_lockOptIndex].apr,
      lockTime: _aprLockOptions[_lockOptIndex].lockTime
    });
    _safeMint(_user, _ids.current());
    tokenMintedAt[_ids.current()] = block.timestamp;

    emit StakeTokens(_user, _ids.current(), _amountStaked, _lockOptIndex);
  }

  function unstake(uint256 _tokenId) public {
    address _user = msg.sender;
    Stake memory _tokenStake = stakes[_tokenId];
    require(
      _user == ownerOf(_tokenId),
      'only the owner of the staked tokens can unstake'
    );
    bool _isUnstakingEarly = block.timestamp <
      _tokenStake.created + _tokenStake.lockTime;

    // send back original tokens staked
    // if unstaking early based on lock period, only get a portion back
    if (_isUnstakingEarly) {
      uint256 _timeStaked = block.timestamp - _tokenStake.created;
      uint256 _earnedAmount = (_tokenStake.amountStaked * _timeStaked) /
        _tokenStake.lockTime;
      stakeToken.transfer(_user, _earnedAmount);
      if (address(stakeToken) == address(ydf)) {
        ydf.burn(_tokenStake.amountStaked - _earnedAmount);
      } else {
        stakeToken.transfer(owner(), _tokenStake.amountStaked - _earnedAmount);
      }
    } else {
      stakeToken.transfer(_user, _tokenStake.amountStaked);
    }

    // check and create new vest if yield available to be claimed
    uint256 _totalEarnedAmount = getTotalEarnedAmount(_tokenId);
    if (_totalEarnedAmount > yieldClaimed[_tokenId]) {
      _createVestAndMint(_user, _totalEarnedAmount - yieldClaimed[_tokenId]);
    }

    // this NFT is useless after the user unstakes
    _burn(_tokenId);

    emit UnstakeTokens(_user, _tokenId);
  }

  function unstakeMulti(uint256[] memory _tokenIds) external {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      unstake(_tokenIds[i]);
    }
  }

  function claimAndVestRewards(uint256 _tokenId) public {
    require(!isBlacklisted[_tokenId], 'blacklisted NFT');

    // user can only claim and vest rewards up to once a week
    require(block.timestamp > lastClaim[_tokenId] + ONE_WEEK);
    lastClaim[_tokenId] = block.timestamp;

    uint256 _totalEarnedAmount = getTotalEarnedAmount(_tokenId);
    require(
      _totalEarnedAmount > yieldClaimed[_tokenId],
      'must have some yield to claim'
    );
    _createVestAndMint(
      ownerOf(_tokenId),
      _totalEarnedAmount - yieldClaimed[_tokenId]
    );
    yieldClaimed[_tokenId] = _totalEarnedAmount;
  }

  function claimAndVestRewardsMulti(uint256[] memory _tokenIds) external {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      claimAndVestRewards(_tokenIds[i]);
    }
  }

  function _createVestAndMint(address _user, uint256 _amount) internal {
    // store metadata for earned tokens in vesting contract for user who is unstaking
    vester.createVest(_user, _amount);
    // mint earned tokens to vesting contract
    ydf.stakeMintToVester(_amount);
  }

  // Support royalty info - See {EIP-2981}: https://eips.ethereum.org/EIPS/eip-2981
  function royaltyInfo(uint256, uint256 _salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    return (royaltyAddress, (_salePrice * royaltyBasisPoints) / 1000);
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(_tokenId), 'token does not exist');
    return string(abi.encodePacked(_baseURI(), _tokenId.toString(), '.json'));
  }

  // Contract metadata URI - Support for OpenSea: https://docs.opensea.io/docs/contract-level-metadata
  function contractURI() public view returns (string memory) {
    return string(abi.encodePacked(_baseURI(), 'contract.json'));
  }

  // Override supportsInterface - See {IERC165-supportsInterface}
  function supportsInterface(bytes4 _interfaceId)
    public
    view
    virtual
    override(ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(_interfaceId);
  }

  function getLastMintedTokenId() external view returns (uint256) {
    return _ids.current();
  }

  function isTokenMinted(uint256 _tokenId) external view returns (bool) {
    return _exists(_tokenId);
  }

  function setPaymentAddress(address _address) external onlyOwner {
    paymentAddress = _address;
    emit SetPaymentAddress(_address);
  }

  function setRoyaltyAddress(address _address) external onlyOwner {
    royaltyAddress = _address;
    emit SetRoyaltyAddress(_address);
  }

  function setRoyaltyBasisPoints(uint256 _points) external onlyOwner {
    royaltyBasisPoints = _points;
    emit SetRoyaltyBasisPoints(_points);
  }

  function setBaseURI(string memory _uri) external onlyOwner {
    baseTokenURI = _uri;
    emit SetBaseTokenURI(_uri);
  }

  function getAllUserOwned(address _user)
    external
    view
    returns (uint256[] memory)
  {
    return allUserOwned[_user];
  }

  function getTotalEarnedAmount(uint256 _tokenId)
    public
    view
    returns (uint256)
  {
    Stake memory _tokenStake = stakes[_tokenId];
    uint256 _secondsStaked = block.timestamp - _tokenStake.created;
    return
      (_tokenStake.amountYDFBaseEarn * _tokenStake.apr * _secondsStaked) /
      PERCENT_DENOMENATOR /
      ONE_YEAR;
  }

  function getAllLockOptions() external view returns (AprLock[] memory) {
    return _aprLockOptions;
  }

  function addAprLockOption(uint16 _apr, uint256 _lockTime) external onlyOwner {
    _addAprLockOption(_apr, _lockTime);
    emit AddAprLockOption(_apr, _lockTime);
  }

  function _addAprLockOption(uint16 _apr, uint256 _lockTime) internal {
    _aprLockOptions.push(AprLock({ apr: _apr, lockTime: _lockTime }));
  }

  function removeAprLockOption(uint256 _index) external onlyOwner {
    AprLock memory _option = _aprLockOptions[_index];
    _aprLockOptions[_index] = _aprLockOptions[_aprLockOptions.length - 1];
    _aprLockOptions.pop();
    emit RemoveAprLockOption(_index, _option.apr, _option.lockTime);
  }

  function updateAprLockOption(
    uint256 _index,
    uint16 _apr,
    uint256 _lockTime
  ) external onlyOwner {
    AprLock memory _option = _aprLockOptions[_index];
    _aprLockOptions[_index] = AprLock({ apr: _apr, lockTime: _lockTime });
    emit UpdateAprLockOption(
      _index,
      _option.apr,
      _option.lockTime,
      _apr,
      _lockTime
    );
  }

  function setIsBlacklisted(uint256 _tokenId, bool _isBlacklisted)
    external
    onlyOwner
  {
    isBlacklisted[_tokenId] = _isBlacklisted;
    emit SetTokenBlacklist(_tokenId, _isBlacklisted);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseTokenURI;
  }

  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal virtual override(ERC721Enumerable) {
    require(!isBlacklisted[_tokenId], 'blacklisted NFT');
    tokenLastTransferred[_tokenId] = block.timestamp;

    super._beforeTokenTransfer(_from, _to, _tokenId);
  }

  function _afterTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal virtual override(ERC721) {
    Stake memory _tokenStake = stakes[_tokenId];

    // if from == address(0), token is being minted
    if (_from != address(0)) {
      uint256 _currIndex = ownedIndex[_tokenId];
      uint256 _tokenIdMovingIndices = allUserOwned[_from][
        allUserOwned[_from].length - 1
      ];
      allUserOwned[_from][_currIndex] = allUserOwned[_from][
        allUserOwned[_from].length - 1
      ];
      allUserOwned[_from].pop();
      ownedIndex[_tokenIdMovingIndices] = _currIndex;
      rewards.setShare(_from, _tokenStake.amountYDFBaseEarn, true);
    }

    // if to == address(0), token is being burned
    if (_to != address(0)) {
      ownedIndex[_tokenId] = allUserOwned[_to].length;
      allUserOwned[_to].push(_tokenId);
      rewards.setShare(_to, _tokenStake.amountYDFBaseEarn, false);
    }

    super._afterTokenTransfer(_from, _to, _tokenId);
  }
}