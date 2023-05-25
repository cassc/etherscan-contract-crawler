// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Psyop is Ownable, Pausable, ERC20, ERC20Burnable {

  /** Total amount of tokens */
  uint256 private constant  TOTAL_SUPPLY    = 550_000_000_000 ether;
  /** Reserve amount of tokens for future development */
  uint256 private constant  RESERVE         = 522_500_000_000 ether;
  /** Allocation for presale buyers and LP */
  uint256 private constant  DISTRIBUTION    = 27_500_000_000 ether;
  /** Max buy amount per tx */
  uint256 public constant   MAX_BUY         = 137_500_000 ether;
  /** Number of blocks to count as dead land */
  uint256 public constant   DEADBLOCK_COUNT = 3;

  /** Developer wallet map with super access */
  mapping(address => bool) private whitelist;
  /** List of available pools */
  mapping(address => bool) private poolList;
  /** Used to watch for sandwiches */
  mapping(address => uint) private _lastBlockTransfer;

  /** Deadblock start blocknum */
  uint256 public deadblockStart;
  /** Block contracts? */
  bool private _blockContracts;
  /** Limit buys? */
  bool private _limitBuys;
  /** Crowd control measures? */
  bool private _unrestricted;

  /** Emit on LP address set */
  event LiquidityPoolSet(address);

  /** Amount must be greater than zero */
  error NoZeroTransfers();
  /** Amount exceeds max transaction */
  error LimitExceeded();
  /** Not allowed */
  error NotAllowed();
  /** Paused */
  error ContractPaused();
  /** Reserve + Distribution must equal Total Supply (sanity check) */
  error IncorrectSum();

  constructor(address _ben) ERC20("Psyop", "PSYOP") Ownable() {
    whitelist[msg.sender] = true;
    whitelist[_ben] = true;

    if (RESERVE + DISTRIBUTION != TOTAL_SUPPLY) { revert IncorrectSum(); }

    _mint(_ben, RESERVE);
    _mint(msg.sender, DISTRIBUTION);

    _blockContracts = true;
    _limitBuys = true;

    _pause();
  }

  /**
   * Sets pool addresseses for reference
   * @param _val Uniswap V3 Pool address
   * @dev Set this after initializing LP
   */
  function setPools(address[] calldata _val) external onlyOwner {
    for (uint256 i = 0; i < _val.length; i++) {
      address _pool = _val[i];
      poolList[_pool] = true;
      emit LiquidityPoolSet(address(_pool));
    }
  }

  /**
   * Sets a supplied address as whitelisted or not
   * @param _address Address to whitelist
   * @param _allow Allow?
   * @dev Revoke after setup completed
   */
  function setAddressToWhiteList(address _address, bool _allow) external onlyOwner {
    whitelist[_address] = _allow;
  }

 /**
   * Sets contract blocker
   * @param _val Should we block contracts?
   */
  function setBlockContracts(bool _val) external onlyOwner {
    _blockContracts = _val;
  }

  /**
   * Sets buy limiter
   * @param _val Limited?
   */
  function setLimitBuys(bool _val) external onlyOwner {
    _limitBuys = _val;
  }

  /**
   * Unleash Psyop
   */
  function unleashPsyop() external onlyOwner {
    _unrestricted = true;
    renounceOwnership();
  }

  /**
   * Pause activity
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * Unpause activity
   */
  function unpause() external onlyOwner {
    deadblockStart = block.number;
    _unpause();
  }

  /**
   * Checks if address is contract
   * @param _address Address in question
   * @dev Contract will have codesize
   */
  function _isContract(address _address) internal view returns (bool) {
    uint32 size;
    assembly {
        size := extcodesize(_address)
    }
    return (size > 0);
  }

  /**
   * Checks if address has inhuman reflexes or if it's a contract
   * @param _address Address in question
   */
  function _checkIfBot(address _address) internal view returns (bool) {
    return (block.number < DEADBLOCK_COUNT + deadblockStart || _isContract(_address)) && !whitelist[_address];
  }

  /**
   * @dev Hook that is called before any transfer of tokens.  This includes
   * minting and burning.
   *
   * Checks:
   * - transfer amount is non-zero
   * - contract is not paused.
   * - whitelisted addresses allowed during pause to setup LP etc.
   * - buy/sell are not executed during the same block to help alleviate sandwiches
   * - buy amount does not exceed max buy during limited period
   * - check for bots to alleviate snipes
   */
  function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal override {
    if (amount == 0) { revert NoZeroTransfers(); }
    super._beforeTokenTransfer(sender, recipient, amount);

    if (_unrestricted) { return; }
    if (paused() && !whitelist[sender]) { revert ContractPaused(); }

    // Watch for sandwich
    if (block.number == _lastBlockTransfer[sender] || block.number == _lastBlockTransfer[recipient]) {
      revert NotAllowed();
    }

    bool isBuy = poolList[sender];
    bool isSell = poolList[recipient];

    if (isBuy) {
      // Watch for bots
      if (_blockContracts && _checkIfBot(recipient)) { revert NotAllowed(); }
      // Watch for buys exceeding max during limited period
      if (_limitBuys && amount > MAX_BUY) { revert LimitExceeded(); }
      _lastBlockTransfer[recipient] = block.number;
    } else if (isSell) {
      _lastBlockTransfer[sender] = block.number;
    }
  }
}