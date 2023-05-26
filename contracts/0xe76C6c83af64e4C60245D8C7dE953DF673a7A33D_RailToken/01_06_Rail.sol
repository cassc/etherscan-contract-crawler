// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

// OpenZeppelin v4
import { Ownable } from  "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title RailToken
 * @author Railgun Contributors
 * @notice ERC20 Railgun Governance Token
 */

contract RailToken is Ownable, ERC20 {
  // Time of deployment
  // solhint-disable-next-line var-name-mixedcase
  uint256 public DEPLOY_TIME = block.timestamp;
  
  // Time for anti-bot protections to be active
  uint256 private constant ANTI_BOT_LOCKTIME = 3 days;

  // Gwei
  uint256 private constant GWEI = 1e9;

  // Soft gas limit
  uint256 private constant ANTI_BOT_SOFT_GASLIMIT = 18 * GWEI;

  // Hard gas limit
  uint256 private constant ANTI_BOT_HARD_GASLIMIT = 100 * GWEI;

  // Anti-bot amount cap
  uint256 private constant ANTI_BOT_AMOUNT_CAP = 10000 * 10**18; // 10k

  // Minting cap
  uint256 public cap;

  // LPs
  mapping(address => bool) private lps;

  // Gardener
  address private constant GARDENER = 0x897BD7Ffae52BFB0F841Fab69ce97a50F6a74BbB;
  // Gardener might do some weeding, ask nicely :)

  /**
   * @notice Mints initial token supply
   */

  constructor(address _initialHolder, uint256 _initialSupply, uint256 _cap, address _owner, address[] memory _lps) ERC20("Rail", "RAIL") {
    // Save cap
    cap = _cap;

    // Mint initial tokens
    _mint(_initialHolder, _initialSupply);

    // Transfer ownership
    Ownable.transferOwnership(_owner);

    // Set LPs
    for (uint i = 0; i < _lps.length; i++) {
      lps[_lps[i]] = true;
    }
  }

  /**
   * @notice See ERC20._mint
   * @dev Overrides ERC20 mint to add hard cap check
   * @param _account - account to mint to
   * @param _amount - amount to mint
   */

  function _mint(address _account, uint256 _amount) internal override {
    require(ERC20.totalSupply() + _amount <= cap, "RailToken: Can't mint more than hard cap");
    super._mint(_account, _amount);
  }

  /**
   * @notice Mints new coins if governance contract requests
   * @dev ONLY MINTABLE IF GOVERNANCE PROCESS PASSES, CANNOT MINT MORE THAN HARD CAP (cap())
   * @param _account - account to mint to
   * @param _amount - amount to mint
   * @return success
   */

  function governanceMint(address _account, uint256 _amount) external onlyOwner returns (bool success) {
    _mint(_account, _amount);
    return true;
  }

  /**
   * @notice No bots
   * @dev OpenZeppelin ERC20 transfer override
   */

  function transfer(address _recipient, uint256 _amount) public virtual override returns (bool) {
    if (
      block.timestamp >= DEPLOY_TIME + ANTI_BOT_LOCKTIME
      // solhint-disable-next-line avoid-tx-origin
      || tx.origin == msg.sender
      // solhint-disable-next-line avoid-tx-origin
      || lps[tx.origin]
      || tx.gasprice <= ANTI_BOT_SOFT_GASLIMIT
    ) {
      _transfer(_msgSender(), _recipient, _amount);
    } else {
      // This one isn't too bad
      require(
        tx.gasprice < ANTI_BOT_HARD_GASLIMIT || _amount < ANTI_BOT_AMOUNT_CAP,
        "true"
      );
      // This bot gets a retry

      // Send bots to gardener
      _transfer(_msgSender(), GARDENER, _amount);
      // To the garden with you
    }

    return true;
  }
}