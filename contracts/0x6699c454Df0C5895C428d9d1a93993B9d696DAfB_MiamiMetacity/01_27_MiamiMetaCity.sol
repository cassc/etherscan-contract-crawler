// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./utils/Helpers.sol";
import "./utils/Security.sol";
import "./Metacity.sol";
import "./CITY.sol";

contract MiamiMetacity is Ownable, IERC721Receiver, Pausable, ReentrancyGuard, Security {

  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    address owner;
    uint80 resetTime;
    uint256 earned;
  }

  event NFTStaked(address indexed owner, uint256 indexed tokenId);
  event NFTClaimed(uint256 indexed tokenId, uint256 earned, uint256 cityTax, uint256 ratTax);
  event RatAttacked(uint256 indexed tokenId, uint256 indexed zenTokenId, uint256 attackAmount, bool success);

  // reference to the Metacity NFT contract
  Metacity metacity;
  // reference to the $CITY contract for minting $CITY earnings
  CITY city;
  // city owner address
  address public cityOwnerAddress;
  // rats claim address
  address public ratsClaimAddress;
  // city zens
  uint16[] public cityZens;
  // num of city rats
  uint256 public numOfRats;
  // maps tokenId to a stake
  mapping(uint256 => Stake) private stakes;
  // tracks location of each tokenId in City
  mapping(uint256 => uint256) private cityIndexes;
  // maps tokenId to vacation until
  mapping(uint256 => uint256) public vacations;
  // maps tokenId to last action made
  mapping(uint256 => uint256) public ratActions;
  // counter
  uint256 private actionCounter = 0;
  // daily rate
  uint256 public DAILY_EARN_RATE = 100; // percentage
  // power gain rate
  uint256 public POWER_GAIN_RATE = 300; // percentage
  // power starting point
  uint256 public POWER_STARTING_POINT = 20; // percentage
  // vacation time
  uint256 public ZEN_VACATION_TIME = 48 hours; // hours
  // rat freeze time
  uint256 public RAT_FREEZE_TIME = 1 hours; // hours
  // city tax
  uint256 public CITY_TAX = 10; // percentage
  // rats tax
  uint256 public RATS_TAX = 30; // percentage
  // there will only ever be (roughly) 100 million $CITY earned through staking
  uint256 public MAXIMUM_CITY = 100_000_000 ether;

  // amount of $CITY earned so far
  uint256 public totalCityEarned;

  // emergency rescue to allow unstaking without any checks but without $CITY
  bool public rescueEnabled = false;

  /// @param _metacity reference to the Metacity NFT contract
  /// @param _city reference to the $CITY token
  constructor(address _metacity, address _city) { 
    metacity = Metacity(_metacity);
    city = CITY(_city);
  }

  // STAKING

  /// @dev adds zens and rets to the MetaCity
  /// @param tokenIds the IDs of the zens to stake
  function addCityZensAndRats(uint16[] calldata tokenIds) external whenNotPaused nonReentrant isEOA {
    for (uint i = 0; i < tokenIds.length; i++) {
      // counter for randoms
      actionCounter++;
      require(metacity.ownerOf(tokenIds[i]) == _msgSender(), "Not the owner");
      require(vacations[tokenIds[i]] < block.timestamp, "On vacation");
      require(ratActions[tokenIds[i]] < block.timestamp, "Too soon");
      metacity.transferFrom(_msgSender(), address(this), tokenIds[i]);
      stakes[tokenIds[i]] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenIds[i]),
        resetTime: uint80(block.timestamp),
        earned: 0
      });
      if (metacity.isZen(tokenIds[i])) {
        cityZens.push(uint16(tokenIds[i]));
        cityIndexes[tokenIds[i]] = cityZens.length - 1;
      } else {
        ratActions[tokenIds[i]] = block.timestamp + RAT_FREEZE_TIME;
        numOfRats++;
      }
      emit NFTStaked(_msgSender(), tokenIds[i]);
    }
  }

  // ATTACK

  /// @dev Rat attacks the MetaCity
  /// @param tokenId the ID of the Rat on the MetaCity
  function ratAttack(uint256 tokenId) external whenNotPaused nonReentrant isEOA {
    require(stakes[tokenId].owner == _msgSender(), "Not the owner");
    require(ratActions[tokenId] < block.timestamp, "Too soon");
    require(!metacity.isZen(tokenId), "Only rats can attack");
    // counter for randoms
    actionCounter++;
    // get rat info
    uint256 _ratPower = ratPower(tokenId);
    // generate random number
    uint256 seed = Helpers.random(actionCounter);
    // check rat attack
    bool successfullyAttacked = (seed % 100) <= _ratPower;
    // anyway choose the zen to attack
    seed >>= 16;
    uint256 zenIndex = seed % cityZens.length;
    uint16 zenTokenId = cityZens[zenIndex];
    uint256 _zenEarned = earned(zenTokenId);
    // update rat next action
    ratActions[tokenId] = block.timestamp + RAT_FREEZE_TIME;
    // reset the rat reset time to now (rat power back to starting point)
    stakes[tokenId].resetTime = uint80(block.timestamp);
    // update zen and rat earnings
    if (successfullyAttacked) {
      // remove zen earnings
      stakes[zenTokenId].resetTime = uint80(block.timestamp);
      // pay the rat
      stakes[tokenId].earned += _zenEarned;
    } else { // just to keep the same gas cost
      // remove zen earnings (not really)
      stakes[zenTokenId].resetTime = stakes[zenTokenId].resetTime;
      // pay the rat (not really)
      stakes[tokenId].earned += 0;
    }
    emit RatAttacked(tokenId, zenTokenId, _zenEarned, successfullyAttacked);
  }

  // CLAIMING / UNSTAKING

  /// @dev unstake zens and rets to the MetaCity
  /// @param tokenIds the IDs of the zens to unstake
  function vacationCityZensAndRats(uint16[] calldata tokenIds) external whenNotPaused nonReentrant isEOA {
    // total for all tokens
    uint256 _earned = 0;
    uint256 _cityTax = 0;
    uint256 _ratTax = 0;
    // loop tokens
    for (uint i = 0; i < tokenIds.length; i++) {
      // counter for randoms
      actionCounter++;
      Stake memory stake = stakes[tokenIds[i]];
      require(stake.owner == _msgSender(), "Metacity was not staked by user");
      // token stake values
      uint256 tokenEarned = 0;
      uint256 tokenCityTax = 0;
      uint256 tokenRatTax = 0;
      // check CITY left
      if (totalCityEarned < MAXIMUM_CITY) {
        tokenEarned = earned(tokenIds[i]);
        if (tokenEarned > MAXIMUM_CITY - totalCityEarned) {
          // not enough $CITY
          tokenEarned = MAXIMUM_CITY - totalCityEarned;
        }
        totalCityEarned += tokenEarned;
      }
      if (metacity.isZen(tokenIds[i])) {
        vacations[tokenIds[i]] = block.timestamp + ZEN_VACATION_TIME;
        _removeZenFromCity(stake);
        // pay taxes
        tokenCityTax = tokenEarned * CITY_TAX / 100;
        tokenRatTax = tokenEarned * RATS_TAX / 100;
        tokenEarned = tokenEarned - tokenCityTax - tokenRatTax;
      } else {
        require(ratActions[tokenIds[i]] < block.timestamp, "Too soon");
        ratActions[tokenIds[i]] = block.timestamp + RAT_FREEZE_TIME;
        numOfRats--;
      }
      
      delete stakes[tokenIds[i]];

      metacity.safeTransferFrom(address(this), _msgSender(), tokenIds[i]);

      _earned += tokenEarned;
      _cityTax += tokenCityTax;
      _ratTax += tokenRatTax;

      emit NFTClaimed(tokenIds[i], tokenEarned, tokenCityTax, tokenRatTax);
    }
    if (_earned > 0) {
      city.mint(_msgSender(), _earned);
    }
    // TAX AND RAT TAX
    if (_cityTax > 0) {
      city.mint(cityOwnerAddress, _cityTax);
    }
    if (_ratTax > 0) {
      city.mint(ratsClaimAddress, _ratTax);
    }
  }

  /// @dev earnings
  /// @param tokenId the ID of the nft on the MetaCity
  /// @return earned amount earned so far
  function earned(uint256 tokenId) public view returns(uint256) {
    Stake memory _stake = stakes[tokenId];
    require(block.timestamp > _stake.resetTime, "Can't get earnings on the attacking / staking block");
    if (_stake.tokenId != tokenId) {
      return 0;
    }
    return metacity.isZen(tokenId) ? metacity.level(tokenId) * DAILY_EARN_RATE * 1e18 * (block.timestamp - _stake.resetTime) / 86400 / 100 : stakes[tokenId].earned;
  }

  /// @dev rat power
  /// @param tokenId the ID of the rat on the MetaCity
  /// @return power amount of power gained so far
  function ratPower(uint256 tokenId) public view returns(uint256) {
    require(!metacity.isZen(tokenId), "Only rats have power");
    Stake memory _stake = stakes[tokenId];
    if (_stake.tokenId != tokenId) {
      return 0;
    }
    uint256 power = POWER_STARTING_POINT + metacity.level(tokenId) * POWER_GAIN_RATE * (block.timestamp - _stake.resetTime) / 86400 / 100;
    return power > 100 ? 100 : power;
  }

  /// @dev Unstake without earnings
  /// @param tokenIds the IDs of the zens to unstake
  function rescue(uint16[] calldata tokenIds) external whenPaused nonReentrant isEOA {
    require(rescueEnabled, "rescue is not enabled");
    for (uint i = 0; i < tokenIds.length; i++) {
      Stake memory stake = stakes[tokenIds[i]];
      require(stake.owner == _msgSender(), "Metacity was not staked by user");
      delete stakes[tokenIds[i]];
      delete cityIndexes[tokenIds[i]];

      metacity.safeTransferFrom(address(this), _msgSender(), tokenIds[i]);
    }
  }

  /// @dev remove from stakes array
  /// @param stake current tokenId stake
  function _removeZenFromCity(Stake memory stake) internal {
    uint256 lastTokenId = cityZens[cityZens.length - 1];
    cityZens[cityIndexes[stake.tokenId]] = uint16(lastTokenId); // Shuffle last tokenId to current position
    cityIndexes[lastTokenId] = cityIndexes[stake.tokenId];
    delete cityIndexes[stake.tokenId];
    cityZens.pop(); // Remove duplicate
  }

  /** ADMIN */

  /// @dev sets the city owner address
  /// @param _cityOwnerAddress address if the city owner
  function setCityOwnerAddress(address _cityOwnerAddress) external onlyOwner {
    cityOwnerAddress = _cityOwnerAddress;
  }

  /// @dev sets the rats claim address
  /// @param _ratsClaimAddress address if the city owner
  function setRatsClaimAddress(address _ratsClaimAddress) external onlyOwner {
    ratsClaimAddress = _ratsClaimAddress;
  }

  /// @dev allows owner to enable "rescue mode"
  /// @param _enabled boolean
  function setRescueEnabled(bool _enabled) external onlyOwner {
    rescueEnabled = _enabled;
  }

  /// @dev enables owner to pause / unpause minting
  /// @param _paused boolean
  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  function setCityParams(
    uint256 dailyEarnRate,
    uint256 powerGainRate,
    uint256 powerStartingPoint,
    uint256 zenVacationTime,
    uint256 ratFreezeTime,
    uint256 cityTax,
    uint256 ratsTax,
    uint256 maximumCity
  ) external onlyOwner {
    DAILY_EARN_RATE = dailyEarnRate;
    POWER_GAIN_RATE = powerGainRate;
    POWER_STARTING_POINT = powerStartingPoint;
    ZEN_VACATION_TIME = zenVacationTime;
    RAT_FREEZE_TIME = ratFreezeTime; // hours
    CITY_TAX = cityTax;
    RATS_TAX = ratsTax; // percentage
    MAXIMUM_CITY = maximumCity;
  }

  function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send tokens to MetaCity directly");
      return IERC721Receiver.onERC721Received.selector;
    }

  
}