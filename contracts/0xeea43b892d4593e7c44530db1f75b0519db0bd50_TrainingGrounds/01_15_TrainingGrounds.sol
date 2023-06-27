// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IWnD.sol";
import "./interfaces/IGP.sol";
import "./interfaces/ITrainingGrounds.sol";
import "./interfaces/ISacrificialAlter.sol";
import "hardhat/console.sol";

contract TrainingGrounds is ITrainingGrounds, Ownable, ReentrancyGuard, IERC721Receiver, Pausable {
  using EnumerableSet for EnumerableSet.UintSet; 
  
  //magic rune tokenId 
  uint256 public constant magicRune = 7;
  //whip tokenId
  uint256 public constant whip = 6;
  // maximum rank for a Wizard/Dragon
  uint8 public constant MAX_RANK = 8;
  //time to stake for reward 
  uint80 public constant timeToStakeForReward = 2 days;
  uint16 public constant MAX_WHIP_EMISSION = 16000;
  uint16 public constant MAX_MAGIC_RUNE_EMISSION = 1600;
  uint16 public curWhipsEmitted;
  uint16 public curMagicRunesEmitted;

  struct StakeWizard {
    uint16 tokenId;
    uint80 lastClaimTime;
    address owner;
  }

  // dragons are in both pools at the same time
  struct StakeDragon {
    uint16 tokenId;
    uint80 lastClaimTime;
    address owner;
    uint256 value; // uint256 because the previous variables pack an entire 32bits
  }

  struct Deposits {
      EnumerableSet.UintSet towerWizards;
      EnumerableSet.UintSet trainingWizards;
      EnumerableSet.UintSet dragons;
  }

  // address => allowedToCallFunctions
  mapping(address => bool) private admins;

  uint256 private totalRankStaked;
  uint256 private numWizardsStaked;

  event TokenStaked(address indexed owner, uint256 indexed tokenId, bool indexed isWizard, bool isTraining);
  event WizardClaimed(address indexed owner, uint256 indexed tokenId, bool indexed unstaked);
  event DragonClaimed(address indexed owner, uint256 indexed tokenId, bool indexed unstaked);

  // reference to the WnD NFT contract
  IWnD public wndNFT;
  // reference to the $GP contract for minting $GP earnings
  IGP public gpToken;
  // reference to sacrificial alter 
  ISacrificialAlter public alter;

  // maps tokenId to stake
  mapping(uint256 => StakeWizard) private tower;
  // maps tokenId to stake
  mapping(uint256 => StakeWizard) private training;
  // maps rank to all Dragon staked with that rank
  mapping(uint256 => StakeDragon[]) private flight;
  // tracks location of each Dragon in Flight
  mapping(uint256 => uint256) private flightIndices;
  mapping(address => Deposits) private _deposits;
  // any rewards distributed when no dragons are staked
  uint256 private unaccountedRewards = 0; 
  // amount of $GP due for each rank point staked
  uint256 private gpPerRank = 0; 
  // wizards earn 12000 $GP per day
  uint256 public constant DAILY_GP_RATE = 2000 ether;
  // dragons take a 20% tax on all $GP claimed
  uint256 public constant GP_CLAIM_TAX_PERCENTAGE_UNTRAINED = 50;
  // dragons take a 20% tax on all $GP claimed
  uint256 public constant GP_CLAIM_TAX_PERCENTAGE = 20;
  // Max earn from staking is 500 million $GP for the training ground
  uint256 public constant MAXIMUM_GLOBAL_GP = 500000000 ether;
  // wizards must have 2 days worth of emissions to unstake or else they're still guarding the tower
  uint256 public constant MINIMUM_TO_EXIT = 2 days;
  // amount of $GP earned so far
  uint256 public totalGPEarned;
  // the last time $GP was claimed
  uint256 private lastClaimTimestamp;

  // emergency rescue to allow unstaking without any checks but without $GP
  bool public rescueEnabled = false;

  /**
   */
  constructor() {
    _pause();
  }

  /** CRITICAL TO SETUP */

  modifier requireContractsSet() {
      require(address(wndNFT) != address(0) && address(gpToken) != address(0) 
        && address(alter) != address(0), "Contracts not set");
      _;
  }

  function setContracts(address _wndNFT, address _gp, address _alter) external onlyOwner {
    wndNFT = IWnD(_wndNFT);
    gpToken = IGP(_gp);
    alter = ISacrificialAlter(_alter);
  }

  function depositsOf(address account) external view returns (uint256[] memory) {
    Deposits storage depositSet = _deposits[account];
    uint256[] memory tokenIds = new uint256[] (depositSet.towerWizards.length() + depositSet.trainingWizards.length() + depositSet.dragons.length());

    for (uint256 i; i < depositSet.towerWizards.length(); i++) {
      tokenIds[i] = depositSet.towerWizards.at(i);
    }
    for (uint256 i; i < depositSet.trainingWizards.length(); i++) {
      tokenIds[i + depositSet.towerWizards.length()] = depositSet.trainingWizards.at(i);
    }
    for (uint256 i; i < depositSet.dragons.length(); i++) {
      tokenIds[i + depositSet.towerWizards.length() + depositSet.trainingWizards.length()] = depositSet.dragons.at(i);
    }

    return tokenIds;
  }

  /** Used to determine if a staked token is owned. Used to allow game logic to occur outside this contract.
    * This might not be necessary if the training mechanic is in this contract instead */
  function ownsToken(uint256 tokenId) external view returns (bool) {
    uint64 lastTokenWrite = wndNFT.getTokenWriteBlock(tokenId);
    // Must check this, as getTokenTraits will be allowed since this contract is an admin
    require(lastTokenWrite < block.number, "hmmmm what doing?");
    IWnD.WizardDragon memory s = wndNFT.getTokenTraits(tokenId);
    if(s.isWizard) {
        return tower[tokenId].owner == tx.origin || training[tokenId].owner == tx.origin;
    }
    uint8 rank = _rankForDragon(tokenId);
    return flight[rank][flightIndices[tokenId]].owner == tx.origin;
  }

  function isTokenStaked(uint256 tokenId, bool isTraining) external view override returns (bool) {
    uint64 lastTokenWrite = wndNFT.getTokenWriteBlock(tokenId);
    // Must check this, as getTokenTraits will be allowed since this contract is an admin
    require(lastTokenWrite < block.number, "hmmmm what doing?");
    IWnD.WizardDragon memory s = wndNFT.getTokenTraits(tokenId);
    if(s.isWizard) {
        return isTraining ? training[tokenId].owner != address(0) : tower[tokenId].owner != address(0);
    }
    // dragons are staked in both pool, so you can ignore the isTraining bool
    uint8 rank = _rankForDragon(tokenId);
    return flight[rank][flightIndices[tokenId]].owner != address(0);
  }

  function calculateGpRewards(uint256 tokenId) external view returns (uint256 owed) {
    uint64 lastTokenWrite = wndNFT.getTokenWriteBlock(tokenId);
    // Must check this, as getTokenTraits will be allowed since this contract is an admin
    require(lastTokenWrite < block.number, "hmmmm what doing?");
    if(wndNFT.isWizard(tokenId)) {
        StakeWizard memory stake = tower[tokenId];
        require(stake.owner != address(0), "Token not guarding");
        if (totalGPEarned < MAXIMUM_GLOBAL_GP) {
            owed = (block.timestamp - stake.lastClaimTime) * DAILY_GP_RATE / 1 days;
        } else if (stake.lastClaimTime > lastClaimTimestamp) {
            owed = 0; // $GP production stopped already
        } else {
            owed = (lastClaimTimestamp - stake.lastClaimTime) * DAILY_GP_RATE / 1 days; // stop earning additional $GP if it's all been earned
        }
    }
    else {
        uint8 rank = _rankForDragon(tokenId);
        StakeDragon memory stake = flight[rank][flightIndices[tokenId]];
        require(stake.owner != address(0), "Token not in flight");
        owed = (rank) * (gpPerRank - stake.value); // Calculate portion of tokens based on Rank
    }
  }

  function calculateErcEmissionRewards(uint256 tokenId) external view returns (uint256 owed) {
    uint64 lastTokenWrite = wndNFT.getTokenWriteBlock(tokenId);
    // Must check this, as getTokenTraits will be allowed since this contract is an admin
    require(lastTokenWrite < block.number, "hmmmm what doing?");
    if(wndNFT.isWizard(tokenId)) {
        if(curWhipsEmitted >= MAX_WHIP_EMISSION) {
            return 0;
        }
        StakeWizard memory stake = training[tokenId];
        require(stake.owner != address(0), "Token not training");
        while(stake.lastClaimTime > 0 && block.timestamp >= stake.lastClaimTime + timeToStakeForReward) {
            owed += 1;
            stake.lastClaimTime += timeToStakeForReward;
        }
    }
    else {
        if(curMagicRunesEmitted >= MAX_MAGIC_RUNE_EMISSION) {
            return 0;
        }
        uint8 rank = _rankForDragon(tokenId);
        StakeDragon memory stake = flight[rank][flightIndices[tokenId]];
        require(stake.owner != address(0), "Token not in flight");
        while(stake.lastClaimTime > 0 && block.timestamp >= stake.lastClaimTime + timeToStakeForReward) {
            owed += 1;
            stake.lastClaimTime += timeToStakeForReward;
        }
    }
  }

  /** STAKING */

  /**
   * adds Wizards and Dragons to the Tower and Flight
   * @param tokenIds the IDs of the Wizards and Dragons to stake
   */
  function addManyToTowerAndFlight(address tokenOwner, uint16[] calldata tokenIds) external override nonReentrant {
    require(admins[_msgSender()], "Only admins can stake");
    for (uint i = 0; i < tokenIds.length; i++) {
      if (wndNFT.ownerOf(tokenIds[i]) != address(this)) { // a mint + stake will send directly to the staking contract
        require(wndNFT.ownerOf(tokenIds[i]) == tokenOwner, "You don't own this token");
        wndNFT.transferFrom(tokenOwner, address(this), tokenIds[i]);
      } else if (tokenIds[i] == 0) {
        continue; // there may be gaps in the array for stolen tokens
      }

      if (wndNFT.isWizard(tokenIds[i])) 
        _addWizardToTower(tokenOwner, tokenIds[i]);
      else 
        _addDragonToFlight(tokenOwner, tokenIds[i]);
    }
  }

  /**
   * adds Wizards and Dragons to the Tower and Flight
   * @param seed the seed for random logic
   * @param tokenIds the IDs of the Wizards and Dragons to stake
   */
  function addManyToTrainingAndFlight(uint256 seed, address tokenOwner, uint16[] calldata tokenIds) external override nonReentrant {
    require(admins[_msgSender()], "Only admins can stake");
    for (uint i = 0; i < tokenIds.length; i++) {
        require(wndNFT.ownerOf(tokenIds[i]) == tokenOwner, "You don't own this token");
        seed = uint256(keccak256(abi.encodePacked(
            tx.origin,
            seed
        )));
        address recipient = selectRecipient(seed, tokenOwner);
        if(tokenIds[i] <= 15000) {
            // Don't allow gen0 tokens from being stolen
            recipient = tokenOwner;
        }
        if(recipient != tokenOwner) { // stolen
            wndNFT.transferFrom(tokenOwner, recipient, tokenIds[i]);
            continue;
        }
        wndNFT.transferFrom(tokenOwner, address(this), tokenIds[i]);
        if (wndNFT.isWizard(tokenIds[i])) {
            _addWizardToTraining(recipient, tokenIds[i]);
        }
        else {
            _addDragonToFlight(recipient, tokenIds[i]);
        }
    }
  }

  /**
   * adds a single Wizard to the Tower
   * @param account the address of the staker
   * @param tokenId the ID of the Wizard to add to the Tower
   */
  function _addWizardToTower(address account, uint256 tokenId) internal whenNotPaused {
    tower[tokenId] = StakeWizard({
      owner: account,
      tokenId: uint16(tokenId),
      lastClaimTime: uint80(block.timestamp)
    });
    numWizardsStaked += 1;
    _deposits[account].towerWizards.add(tokenId);
    emit TokenStaked(account, tokenId, true, false);
  }

  function _addWizardToTraining(address account, uint256 tokenId) internal whenNotPaused {
    training[tokenId] = StakeWizard({
      owner: account,
      tokenId: uint16(tokenId),
      lastClaimTime: uint80(block.timestamp)
    });
    numWizardsStaked += 1;
    _deposits[account].trainingWizards.add(tokenId);
    emit TokenStaked(account, tokenId, true, true);
  }

  /**
   * adds a single Dragon to the Flight
   * @param account the address of the staker
   * @param tokenId the ID of the Dragon to add to the Flight
   */
  function _addDragonToFlight(address account, uint256 tokenId) internal {
    uint8 rank = _rankForDragon(tokenId);
    totalRankStaked += rank; // Portion of earnings ranges from 8 to 5
    flightIndices[tokenId] = flight[rank].length; // Store the location of the dragon in the Flight
    flight[rank].push(StakeDragon({
      owner: account,
      tokenId: uint16(tokenId),
      lastClaimTime: uint80(block.timestamp),
      value: gpPerRank
    })); // Add the dragon to the Flight
    _deposits[account].dragons.add(tokenId);
    emit TokenStaked(account, tokenId, false, true);
  }

  /** CLAIMING / UNSTAKING */

  /**
   * realize $GP earnings and optionally unstake tokens from the Tower / Flight
   * to unstake a Wizard it will require it has 2 days worth of $GP unclaimed
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
  function claimManyFromTowerAndFlight(address tokenOwner, uint16[] calldata tokenIds, bool unstake) external override whenNotPaused _updateEarnings nonReentrant {
    require(admins[_msgSender()], "Only admins can stake");
    uint256 owed = 0;
    uint16 owedRunes = 0;
    for (uint i = 0; i < tokenIds.length; i++) {
      if (wndNFT.isWizard(tokenIds[i])) {
        owed += _claimWizardFromTower(tokenIds[i], unstake, tokenOwner);
      }
      else {
        (uint256 gpOwed, uint16 runes) = _claimDragonFromFlight(tokenIds[i], unstake, tokenOwner);
        owed += gpOwed;
        owedRunes += runes;
      }
    }
    gpToken.updateOriginAccess();
    if(owed > 0) {
        gpToken.mint(tokenOwner, owed);
    }
    if(owedRunes > 0 && curMagicRunesEmitted + owedRunes <= MAX_MAGIC_RUNE_EMISSION) {
        curMagicRunesEmitted += owedRunes;
        alter.mint(magicRune, owedRunes, tokenOwner);
    }
  }

  /**
   * realize $GP earnings and optionally unstake tokens from the Tower / Flight
   * to unstake a Wizard it will require it has 2 days worth of $GP unclaimed
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
  function claimManyFromTrainingAndFlight(uint256 seed, address tokenOwner, uint16[] calldata tokenIds, bool unstake) external override whenNotPaused nonReentrant {
    require(admins[_msgSender()], "Only admins can stake");
    uint256 owedGp = 0;
    uint16 owedWhips = 0;
    uint16 runes = 0;
    for (uint i = 0; i < tokenIds.length; i++) {
      if (wndNFT.isWizard(tokenIds[i])) {
        owedWhips += _claimWizardFromTraining(seed, tokenIds[i], unstake, tokenOwner);
      }
      else {
        (uint256 gpOwed, uint16 owedRunes) = _claimDragonFromFlight(tokenIds[i], unstake, tokenOwner);
        owedGp += gpOwed;
        runes += owedRunes;
      }
    }
    gpToken.updateOriginAccess();
    if(owedGp > 0) {
        gpToken.mint(tokenOwner, owedGp);
    }
    if(owedWhips > 0 && curWhipsEmitted + owedWhips <= MAX_WHIP_EMISSION) {
        curWhipsEmitted += owedWhips;
        alter.mint(whip, owedWhips, tokenOwner);
    }
    if(runes > 0 && curMagicRunesEmitted + runes <= MAX_MAGIC_RUNE_EMISSION) {
        curMagicRunesEmitted += runes;
        alter.mint(magicRune, runes, tokenOwner);
    }
  }

  /**
   * @param seed a random value to select a recipient from
   * @return the address of the recipient (either the caller or the Dragon thief's owner)
   */
  function selectRecipient(uint256 seed, address tokenOwner) internal view returns (address) {
    if (((seed >> 245) % 10) != 0) return tokenOwner;
    address thief = randomDragonOwner(seed >> 144);
    if (thief == address(0x0)) return tokenOwner;
    return thief;
  }

  /**
   * realize $GP earnings for a single Wizard and optionally unstake it
   * if not unstaking, pay a 20% tax to the staked Dragons
   * if unstaking, there is a 50% chance all $GP is stolen
   * @param tokenId the ID of the Wizards to claim earnings from
   * @param unstake whether or not to unstake the Wizards
   * @return owed - the amount of $GP earned
   */

  function _claimWizardFromTower(uint256 tokenId, bool unstake, address tokenOwner) internal returns (uint256 owed) {
    require(wndNFT.ownerOf(tokenId) == address(this), "Doesn't own token");
    StakeWizard memory stake = tower[tokenId];
    require(tokenOwner == stake.owner, "Invalid token owner");
    require(!(unstake && block.timestamp - stake.lastClaimTime < MINIMUM_TO_EXIT), "Still guarding the tower");
    if (totalGPEarned < MAXIMUM_GLOBAL_GP) {
      owed = (block.timestamp - stake.lastClaimTime) * DAILY_GP_RATE / 1 days;
    } else if (stake.lastClaimTime > lastClaimTimestamp) {
      owed = 0; // $GP production stopped already
    } else {
      owed = (lastClaimTimestamp - stake.lastClaimTime) * DAILY_GP_RATE / 1 days; // stop earning additional $GP if it's all been earned
    }
    if (unstake) {
        if (random(stake.tokenId, stake.lastClaimTime, stake.owner) & 1 == 1) { // 50% chance of all $GP stolen
            _payDragonTax(owed);
            owed = 0;
        }
        delete tower[tokenId];
        numWizardsStaked -= 1;
        _deposits[stake.owner].towerWizards.remove(tokenId);
        // Always transfer last to guard against reentrance
        wndNFT.safeTransferFrom(address(this), stake.owner, tokenId, ""); // send back Wizard
    } else {
      uint256 taxPercent = getTaxPercent(stake.owner);
      _payDragonTax(owed * taxPercent / 100); // percentage tax to staked dragons
      owed = owed * (100 - taxPercent) / 100; // remainder goes to Wizard owner
      tower[tokenId] = StakeWizard({
        owner: stake.owner,
        tokenId: uint16(tokenId),
        lastClaimTime: uint80(block.timestamp)
      }); // reset stake
    }
    emit WizardClaimed(stake.owner, tokenId, unstake);
  }

  /** Get the tax percent owed to dragons. If the address doesn't contain a 1:10 ratio of whips to staked wizards,
    *  they are subject to an untrained tax */
  function getTaxPercent(address addr) internal returns (uint256) {
      if(_deposits[addr].towerWizards.length() <= 10) {
          // 
          return alter.balanceOf(addr, whip) >= 1 ? GP_CLAIM_TAX_PERCENTAGE : GP_CLAIM_TAX_PERCENTAGE_UNTRAINED;
      }
      return alter.balanceOf(addr, whip) >= _deposits[addr].towerWizards.length() / 10 ? GP_CLAIM_TAX_PERCENTAGE : GP_CLAIM_TAX_PERCENTAGE_UNTRAINED;
  }

  function _claimWizardFromTraining(uint256 seed, uint256 tokenId, bool unstake, address tokenOwner) internal returns (uint16 owed) {
    require(wndNFT.ownerOf(tokenId) == address(this), "Doesn't own token");
    StakeWizard memory stake = training[tokenId];
    require(tokenOwner == stake.owner, "Invalid token owner");
    require(!(unstake && block.timestamp - stake.lastClaimTime < MINIMUM_TO_EXIT), "Still training");
    while(stake.lastClaimTime > 0 && block.timestamp >= stake.lastClaimTime + timeToStakeForReward) {
      owed += 1;
      stake.lastClaimTime += timeToStakeForReward;
    }
    if (unstake) {
        address recipient = selectRecipient(seed, stake.owner);
        if(tokenId <= 15000) {
            // Don't allow gen0 tokens from being stolen
            recipient = stake.owner;
        }
        delete training[tokenId];
        numWizardsStaked -= 1;
        _deposits[stake.owner].trainingWizards.remove(tokenId);
        // Always transfer last to guard against reentrance
        // recipient may not be the stake.owner if it was stolen by a random dragon.
        wndNFT.safeTransferFrom(address(this), recipient, tokenId, ""); // send back Wizard
    } else {
        training[tokenId] = StakeWizard({
            owner: stake.owner,
            tokenId: uint16(tokenId),
            lastClaimTime: uint80(block.timestamp)
        }); // reset stake
    }
    emit WizardClaimed(tokenOwner, tokenId, unstake);
  }

  /**
   * realize $GP earnings for a single Dragon and optionally unstake it
   * Dragons earn $GP proportional to their rank
   * @param tokenId the ID of the Dragon to claim earnings from
   * @param unstake whether or not to unstake the Dragon
   */
  function _claimDragonFromFlight(uint256 tokenId, bool unstake, address tokenOwner) internal returns (uint256 owedGP, uint16 owedRunes) {
    require(wndNFT.ownerOf(tokenId) == address(this), "Doesn't own token");
    uint8 rank = _rankForDragon(tokenId);
    StakeDragon memory stake = flight[rank][flightIndices[tokenId]];
    require(tokenOwner == stake.owner, "Invalid token owner");
    owedGP = (rank) * (gpPerRank - stake.value); // Calculate portion of tokens based on Rank
    while(stake.lastClaimTime > 0 && block.timestamp >= stake.lastClaimTime + timeToStakeForReward) {
      owedRunes += 1;
      stake.lastClaimTime += timeToStakeForReward;
    }
    if (unstake) {
      totalRankStaked -= rank; // Remove rank from total staked
      StakeDragon memory lastStake = flight[rank][flight[rank].length - 1];
      flight[rank][flightIndices[tokenId]] = lastStake; // Shuffle last Dragon to current position
      flightIndices[lastStake.tokenId] = flightIndices[tokenId];
      flight[rank].pop(); // Remove duplicate
      delete flightIndices[tokenId]; // Delete old mapping
      _deposits[stake.owner].dragons.remove(tokenId);
      // Always remove last to guard against reentrance
      wndNFT.safeTransferFrom(address(this), stake.owner, tokenId, ""); // Send back Dragon
    } else {
      flight[rank][flightIndices[tokenId]] = StakeDragon({
        owner: stake.owner,
        tokenId: uint16(tokenId),
        lastClaimTime: uint80(block.timestamp),
        value: gpPerRank
      }); // reset stake
    }
    emit DragonClaimed(stake.owner, tokenId, unstake);
  }

  /**
   * emergency unstake tokens
   * @param tokenIds the IDs of the tokens to claim earnings from
   */
  function rescue(uint256[] calldata tokenIds) external nonReentrant {
    require(rescueEnabled, "RESCUE DISABLED");
    uint256 tokenId;
    uint8 rank;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      if (wndNFT.isWizard(tokenId)) {
        StakeWizard memory stake = tower[tokenId];
        StakeWizard memory stakeTraining = training[tokenId];
        require(stake.owner == tx.origin || stakeTraining.owner == tx.origin, "SWIPER, NO SWIPING");
        if(stake.owner == tx.origin) { // guarding the tower
            delete tower[tokenId];
            _deposits[stake.owner].towerWizards.remove(tokenId);
        }
        else { // training
            delete training[tokenId];
            _deposits[stake.owner].trainingWizards.remove(tokenId);
        }
        numWizardsStaked -= 1;
        wndNFT.safeTransferFrom(address(this), tx.origin, tokenId, ""); // send back Wizards
        emit WizardClaimed(tx.origin, tokenId, true);
      } else {
        rank = _rankForDragon(tokenId);
        StakeDragon memory stake = flight[rank][flightIndices[tokenId]];
        require(stake.owner == tx.origin, "SWIPER, NO SWIPING");
        totalRankStaked -= rank; // Remove Rank from total staked
        StakeDragon memory lastStake = flight[rank][flight[rank].length - 1];
        flight[rank][flightIndices[tokenId]] = lastStake; // Shuffle last Dragon to current position
        flightIndices[lastStake.tokenId] = flightIndices[tokenId];
        flight[rank].pop(); // Remove duplicate
        delete flightIndices[tokenId]; // Delete old mapping
        _deposits[stake.owner].dragons.remove(tokenId);
        wndNFT.safeTransferFrom(address(this), tx.origin, tokenId, ""); // Send back Dragon
        emit DragonClaimed(tx.origin, tokenId, true);
      }
    }
  }

  /** ADMIN */

  /**
   * allows owner to enable "rescue mode"
   * simplifies accounting, prioritizes tokens out in emergency
   */
  function setRescueEnabled(bool _enabled) external onlyOwner {
    rescueEnabled = _enabled;
  }

  /**
   * enables owner to pause / unpause contract
   */
  function setPaused(bool _paused) external requireContractsSet onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  /** READ ONLY */

  /**
   * gets the rank score for a Dragon
   * @param tokenId the ID of the Dragon to get the rank score for
   * @return the rank score of the Dragon (5-8)
   */
  function _rankForDragon(uint256 tokenId) internal view returns (uint8) {
    IWnD.WizardDragon memory s = wndNFT.getTokenTraits(tokenId);
    return MAX_RANK - s.rankIndex; // rank index is 0-3
  }

  /**
   * chooses a random Dragon thief when a newly minted token is stolen
   * @param seed a random value to choose a Dragon from
   * @return the owner of the randomly selected Dragon thief
   */
  function randomDragonOwner(uint256 seed) public view override returns (address) {
    if (totalRankStaked == 0) {
      return address(0x0);
    }
    uint256 bucket = (seed & 0xFFFFFFFF) % totalRankStaked; // choose a value from 0 to total rank staked
    uint256 cumulative;
    seed >>= 32;
    // loop through each bucket of Dragons with the same rank score
    for (uint i = MAX_RANK - 3; i <= MAX_RANK; i++) {
      cumulative += flight[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the address of a random Dragon with that rank score
      return flight[i][seed % flight[i].length].owner;
    }
    return address(0x0);
  }

  /** Deterministically random. This assumes the call was a part of commit+reveal design 
   * that disallowed the benefactor of this outcome to make this call */
  function random(uint16 tokenId, uint80 lastClaim, address owner) internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
      tx.origin,
      blockhash(block.number - 1),
      owner,
      tokenId,
      lastClaim
    )));
  }

  function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send to Tower directly");
      return IERC721Receiver.onERC721Received.selector;
    }

  /**
   * enables an address to mint / burn
   * @param addr the address to enable
   */
  function addAdmin(address addr) external onlyOwner {
    admins[addr] = true;
  }

  /**
   * disables an address from minting / burning
   * @param addr the address to disbale
   */
  function removeAdmin(address addr) external onlyOwner {
    admins[addr] = false;
  }

  /** 
   * add $GP to claimable pot for the Flight
   * @param amount $GP to add to the pot
   */
  function _payDragonTax(uint256 amount) internal {
    if (totalRankStaked == 0) { // if there's no staked dragons
      unaccountedRewards += amount; // keep track of $GP due to dragons
      return;
    }
    // makes sure to include any unaccounted $GP 
    gpPerRank += (amount + unaccountedRewards) / totalRankStaked;
    unaccountedRewards = 0;
  }

  modifier _updateEarnings() {
    if (totalGPEarned < MAXIMUM_GLOBAL_GP) {
    totalGPEarned += 
      (block.timestamp - lastClaimTimestamp)
      * numWizardsStaked
      * DAILY_GP_RATE / 1 days; 
    lastClaimTimestamp = block.timestamp;
    }
    _;
  }
  
}