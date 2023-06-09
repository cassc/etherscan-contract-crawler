// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./ERC721Tradable.sol";
import "./AddressArray.sol";
import "./Uint256Array.sol";
import "./BattleRoyaleArena.sol";

contract BattleRoyale is ERC721Tradable {
  using AddressArray for AddressArray.Addresses;
  using Uint256Array for Uint256Array.Uint256s;

  enum BATTLE_STATE {
    STANDBY,
    RUNNING,
    ENDED
  }

  BATTLE_STATE public battleState;

  event Eliminated(uint256 _tokenID);
  event BattleState(uint256 _state);

  bool public autoStart;         // set to true when wanting the game to start automatically once sales hit max supply
  bool public autoPayout;        // set to true when wanting the game to start automatically once sales hit max supply

  string public prizeTokenURI;   // prize token URI to be set to winner
  string public defaultTokenURI; // prize token URI to be set to winner

  uint256 public maxSupply = 1; // maximum number of mintable tokens
  uint256 public intervalTime;  // time in minutes
  uint256 public timestamp;     // timestamp of last elimination
  uint256 public price;         // initial price per token
  uint256 public unitsPerTransaction; // current purchasable units per transaction

  address payable public delegate;

  AddressArray.Addresses purchasers; // array of purchaser addresses
  Uint256Array.Uint256s inPlay; // look into elimination logic and how to maintain state of all NFTs in and out of play
  Uint256Array.Uint256s outOfPlay;

  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _price,
    uint256 _units,
    uint256 _supply,
    bool _autoStart,
    bool _autoPayout,
    address payable _delegate
  )
  public ERC721Tradable(
    _name,
    _symbol,
    'https://ipfs.io/ipfs/'
  ) {
    battleState = BATTLE_STATE.STANDBY;
    intervalTime = 30;
    price = _price;
    unitsPerTransaction = _units;
    maxSupply = _supply;
    autoStart = _autoStart;
    autoPayout = _autoPayout;
    delegate = _delegate;
  }

  modifier onlyAdmin {
    require(msg.sender == delegate || msg.sender == owner());
    _;
  }

  function burn(uint256 _tokenId) public virtual {
    require(msg.sender == ownerOf(_tokenId) || msg.sender == delegate || msg.sender == owner());
    inPlay.remove(_tokenId);
    _burn(_tokenId);
  }

  function purchase(uint256 units) external payable {
    require(price > 0);
    require(battleState == BATTLE_STATE.STANDBY);

    if (msg.sender != delegate && msg.sender != owner()) {
      require(maxSupply > 0 && totalSupply() < maxSupply);
      require(units <= maxSupply - totalSupply());
      require(units > 0 && units <= unitsPerTransaction);
      require(bytes(defaultTokenURI).length > 0);
      require(msg.value >= (price * units));
    }

    // require(purchasers.getIndex(msg.sender) < 0, "Only 1 purchase per account.");
    // // add buyer address to list
    // purchasers.push(msg.sender);

    for (uint256 i = 0; i < units; i++) {
      uint256 tokenId = mintTo(msg.sender);
      _setTokenURI(tokenId, defaultTokenURI);

      if (msg.sender == delegate || msg.sender == owner()) {
        outOfPlay.push(tokenId);
      } else {
        inPlay.push(tokenId);
      }
    }

    // Begin battle if max supply has been reached
    if (maxSupply == totalSupply() && autoStart) {
      startBattle();
    }
  }

  function withdraw(uint256 amount) external override virtual onlyAdmin {
    uint256 balance = address(this).balance;
    require(amount <= balance);
    if (delegate != address(0)) {
      payable(delegate).transfer(amount);
    } else {
      msg.sender.transfer(amount);
    }
  }

  // GET contract data
  function getBattleState() external view returns (string memory) {
    if (battleState == BATTLE_STATE.STANDBY) {
      return 'STANDBY';
    }
    if (battleState == BATTLE_STATE.RUNNING) {
      return 'RUNNING';
    }
    if (battleState == BATTLE_STATE.ENDED) {
      return 'ENDED';
    }
    return '';
  }

  function getBattleStateInt() external view returns (uint256) {
    return uint256(battleState);
  }

  function getInPlay() external view returns (uint256[] memory) {
    return inPlay.getAll();
  }

  function getOutOfPlay() external view returns (uint256[] memory) {
    return outOfPlay.getAll();
  }

  function getCurrentBalance() external override onlyAdmin returns (uint256) {
    uint256 balance = address(this).balance;
    return balance;
  }

  // SET contract data
  function autoStartOn(bool _autoStart) external payable onlyAdmin {
    autoStart = _autoStart;
  }

  function autoPayoutOn(bool _autoPayout) external payable onlyAdmin {
    autoPayout = _autoPayout;
  }

  function setDefaultTokenURI(string memory _tokenUri) external payable onlyAdmin {
    defaultTokenURI = _tokenUri;
  }

  function setPrizeTokenURI(string memory _tokenUri) external payable onlyAdmin {
    prizeTokenURI = _tokenUri;
  }

  function setIntervalTime(uint256 _intervalTime) external payable onlyAdmin {
    intervalTime = _intervalTime;
  }

  function setPrice(uint256 _price) external payable onlyAdmin {
    price = _price;
  }

  function setUnitsPerTransaction(uint256 _units) external payable onlyAdmin {
    unitsPerTransaction = _units;
  }

  function setMaxSupply(uint256 supply) external payable onlyAdmin {
    maxSupply = supply;
  }

  function beginBattle() external payable onlyAdmin {
    startBattle();
  }

  function executePayout() external payable onlyAdmin {
    executeAutoPayout();
  }

  function executeRandomElimination(uint256 _randomNumber) external payable onlyAdmin {
    require(battleState == BATTLE_STATE.RUNNING);
    require(inPlay.size() > 1);

    uint256 i = _randomNumber % inPlay.size();
    uint256 tokenId = inPlay.atIndex(i);
    outOfPlay.push(tokenId);
    inPlay.remove(tokenId);
    timestamp = block.timestamp;
    Eliminated(tokenId);

    if (inPlay.size() == 1) {
      battleState = BATTLE_STATE.ENDED;
      BattleState(uint256(battleState));
      tokenId = inPlay.atIndex(0);
      _setTokenURI(tokenId, prizeTokenURI);
      notifyGameEnded();

      if (autoPayout) {
        executeAutoPayout();
      }
    }
  }

  // Internal contract functions
  function notifyGameEnded() internal {
    BattleRoyaleArena arena = BattleRoyaleArena(payable(delegate));
    arena.gameDidEnd(address(this));
  }

  function startBattle() internal {
    require(bytes(prizeTokenURI).length > 0 && inPlay.size() > 1);
    battleState = BATTLE_STATE.RUNNING;
    BattleState(uint256(battleState));
    timestamp = block.timestamp; // Set to current clock
  }

  function executeAutoPayout() internal {
    uint256 balance = address(this).balance;
    payable(delegate).transfer(balance);
  }
}