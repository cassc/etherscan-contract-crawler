// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IOracle {
  function randomNumber(uint256 max, uint256 seed) external view returns (uint256);
}

interface INFT {
  function balanceOf(address owner) external view returns (uint256 balance);
  function ownerOf(uint256 tokenId) external view returns (address);
}

interface IRobotikz is INFT {
  function mintFromMetaRage(address recipient) external returns (bool);
}

interface IToken {
  function balanceOf(address account) external view returns (uint256);
  function mint(address to, uint256 amount) external;
  function burn(address _from, uint256 _amount) external;
}

error GamePaused();
error CollectionAlreadyExists();
error CollectionNotFound();
error WrongOwner();
error AlreadyClaimed();
error ClaimsDepleted();
error AttackerCollectionNotFound();
error InsufficientBalance();
error OpponentCollectionNotFound();
error RewardsDepleted();

contract MetaRage is Ownable, ReentrancyGuard {
  uint256 public totalFighters = 0;
  uint256 public totalClaims = 0 ether;
  uint256 public totalRewards = 0 ether;

  bool public paused = true;

  mapping(uint256 => bool) public claims;
  mapping(address => Collection) public collections;

  IOracle public oracleContract;
  IRobotikz public robotikzContract;
  IToken public metapondContract;

  struct Config {
    uint256 entryFee;
    uint256 chance;
    uint256 perfectOutcome;
    uint256 perfectReward;
    uint256 executionOutcome;
    uint256 executionReward;
    uint256 victoryOutcome;
    uint256 victoryReward;
    uint256 maxClaims;
    uint256 maxRewards;
  }
  
  Config public config = Config(
    100 ether, 
    100, 
    98, 
    12000 ether,
    80, 
    6000 ether,
    50,
    3000 ether,
    200_000_000 ether,
    300_000_000 ether
  );

  struct Collection {
    bool active;
    string symbol;
    address contractAddress;
    address currency;
    uint256 supply;
    uint256 startIndex;
    uint256 allocation;
  }

  struct Fighter {
    address collection;
    uint256 tokenId;
  }

  event Fight(
    address indexed attacker, 
    address indexed opponent,
    uint256 indexed outcome
  );

  event Claim(
    address indexed wallet,
    uint256 indexed amount
  );

  modifier unlessPaused {
    if (paused) {
      revert GamePaused();
    }
    _;
  }

  constructor(
    address oracleContractAddress,
    address cryptoPolzContractAddress,
    address polzillaContractAddress,
    address eggzillaContractAddress,
    address kongzillaContractAddress,
    address robotikzContractAddress,
    address eggzContractAddress,
    address rageContractAddress,
    address metapondContractAddress
  ) {
    setOracleContract(oracleContractAddress);
    setRobotikzContract(robotikzContractAddress);
    setMetapondContract(metapondContractAddress);
    
    addCollection(true, "CRYPTOPOLZ", cryptoPolzContractAddress, eggzContractAddress, 9696, 5000 ether);
    addCollection(true, "POLZILLA", polzillaContractAddress, eggzContractAddress, 9696, 3000 ether);
    addCollection(true, "EGGZILLA", eggzillaContractAddress, eggzContractAddress, 15555, 1000 ether);
    addCollection(true, "KONGZILLA", kongzillaContractAddress, rageContractAddress, 6969, 10000 ether);
    addCollection(true, "ROBOTIKZ", robotikzContractAddress, metapondContractAddress, 4242, 0 ether);
  }

  function flipPause() external onlyOwner {
    paused = !paused;
  }
  
  function setConfig(
    uint256 entryFee,
    uint256 chance,
    uint256 perfectOutcome,
    uint256 perfectReward,
    uint256 executionOutcome,
    uint256 executionReward,
    uint256 victoryOutcome,
    uint256 victoryReward,
    uint256 maxClaims,
    uint256 maxRewards
  ) public onlyOwner nonReentrant {
    require (chance > 0);
    require (perfectOutcome > executionOutcome);
    require (perfectReward > 0);
    require (executionOutcome > victoryOutcome);
    require (executionReward > 0);
    require (victoryOutcome > 0);
    require (victoryReward > 0);

    config = Config(
      entryFee,
      chance,
      perfectOutcome,
      perfectReward,
      executionOutcome,
      executionReward,
      victoryOutcome,
      victoryReward,
      maxClaims,
      maxRewards
    );
  }

  function addCollection(
    bool active,
    string memory symbol,
    address contractAddress,
    address currency,
    uint256 supply,
    uint256 allocationAmount
  ) public onlyOwner nonReentrant {
    if (collectionExists(contractAddress)) {
      revert CollectionAlreadyExists();
    }

    Collection memory collection = Collection(
      active,
      symbol,
      contractAddress,
      currency,
      supply,
      0,
      allocationAmount
    );

    collection.startIndex = totalFighters;
    collections[collection.contractAddress] = collection;
    totalFighters += collection.supply;
  }

  function deactivateCollection(address contractAddress) public onlyOwner nonReentrant {
    Collection memory collection = collections[contractAddress];
    collection.active = false;
    collections[contractAddress] = collection;
  }

  function collectionExists(address contractAddress) public view returns (bool) {
    return collections[contractAddress].supply > 0;
  }

  function setOracleContract(address contractAddress) public onlyOwner {
    oracleContract = IOracle(contractAddress);
  }

  function setRobotikzContract(address contractAddress) public onlyOwner {
    robotikzContract = IRobotikz(contractAddress);
  }

  function setMetapondContract(address contractAddress) public onlyOwner {
    metapondContract = IToken(contractAddress);
  }

  function getFighterId(address collection, uint256 tokenId) public view returns (uint256) {
    unchecked {
      return collections[collection].startIndex + tokenId;
    }
  }

  function claimable(Fighter[] memory fighters) public view returns (uint256) {
    uint256 f = fighters.length;
    uint256 amount = 0 ether;

    for (uint256 i; i < f; i++) {
      unchecked {
        amount += _claimable(fighters[i]);
      }
    }

    if ((totalClaims + amount) > config.maxClaims) {
      return 0 ether;
    }

    return amount;
  }

  function _claimable(Fighter memory fighter) internal view returns (uint256) {
    if (!collections[fighter.collection].active) {
      return 0 ether;
    }

    uint256 fighterId = getFighterId(fighter.collection, fighter.tokenId);

    if (claims[fighterId] == true) {
      return 0 ether;
    }

    return collections[fighter.collection].allocation;
  }

  function claim(Fighter[] memory fighters) public unlessPaused nonReentrant returns (uint256) {
    uint256 f = fighters.length;
    uint256 amount = 0 ether;

    unchecked {
      for (uint256 i; i < f; i++) {
        amount += _claim(fighters[i]);
      }
    }

    uint256 nextTotalClaimed = totalClaims + amount;

    if (nextTotalClaimed > config.maxClaims) {
      revert ClaimsDepleted();
    }

    totalClaims = nextTotalClaimed;

    metapondContract.mint(msg.sender, amount);

    emit Claim(msg.sender, amount);

    return amount;
  }

  function _claim(Fighter memory fighter) internal returns (uint256) {
    if (!collections[fighter.collection].active) {
      return 0 ether;
    }
    
    if (INFT(fighter.collection).ownerOf(fighter.tokenId) != msg.sender) {
      return 0 ether;
    }

    uint256 fighterId = getFighterId(fighter.collection, fighter.tokenId);

    if (claims[fighterId]) {
      return 0 ether;
    }
    
    claims[fighterId] = true;

    return collections[fighter.collection].allocation;
  }

  function fight(Fighter memory attacker, Fighter[] memory opponents) public unlessPaused nonReentrant {
    if (!collections[attacker.collection].active) {
      revert AttackerCollectionNotFound();
    }

    if (INFT(attacker.collection).ownerOf(attacker.tokenId) != msg.sender) {
      revert WrongOwner();
    }
    
    uint256 entryFee = config.entryFee * opponents.length;

    if (entryFee > IToken(collections[attacker.collection].currency).balanceOf(msg.sender)) {
      revert InsufficientBalance();
    }

    uint256 fights = opponents.length;
    uint256 rewards = 0 ether;

    while (fights > 0) {
      unchecked {
        --fights;
      }

      if (!collections[opponents[fights].collection].active) {
        revert OpponentCollectionNotFound();
      }
      
      unchecked {
        rewards += _fight(opponents[fights]);
      }
    }

    unchecked {
      if (rewards > 0) {
        uint256 nextTotalRewards = totalRewards + rewards;

        if (nextTotalRewards > config.maxRewards) {
          revert RewardsDepleted();
        }

        totalRewards = nextTotalRewards;

        metapondContract.mint(msg.sender, rewards);
      }
    }

    IToken(collections[attacker.collection].currency)
      .burn(msg.sender, entryFee);
  }

  function _fight(Fighter memory opponent) internal returns (uint256) {
    address otherPlayer = INFT(opponent.collection).ownerOf(opponent.tokenId); 
    address winner = msg.sender;
    uint256 reward = 0 ether;
    uint256 outcome = oracleContract.randomNumber(
      config.chance, 
      getFighterId(opponent.collection, opponent.tokenId)
    );
    
    if (outcome >= config.perfectOutcome) {
      robotikzContract.mintFromMetaRage(winner);
      reward = config.perfectReward;
    } else if (outcome >= config.executionOutcome && outcome < config.perfectOutcome) {
      reward = config.executionReward;
    } else if (outcome >= config.victoryOutcome && outcome < config.executionOutcome) {
      reward = config.victoryReward;
    } else {
      winner = otherPlayer;
    }

    emit Fight(msg.sender, otherPlayer, outcome);

    return reward;
  }
}