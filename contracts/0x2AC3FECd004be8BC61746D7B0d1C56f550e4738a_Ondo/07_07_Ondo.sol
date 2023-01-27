/**SPDX-License-Identifier: AGPL-3.0

          ▄▄█████████▄                                                                  
       ╓██▀└ ,╓▄▄▄, '▀██▄                                                               
      ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,         
     ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,     
    ██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌    
    ██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██    
    ╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀    
     ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`     
      ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬         
       ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀                                                               
          ╙▀▀██████R⌐                                                                   

 */
pragma solidity >=0.8.3;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IOndo.sol";
import "./LinearTimelock.sol";

contract Ondo is AccessControl, LinearTimelock {
  /// @notice EIP-20 token name for this token
  string public constant name = "Test Ondo";

  /// @notice EIP-20 token symbol for this token
  string public constant symbol = "tONDO";

  /// @notice EIP-20 token decimals for this token
  uint8 public constant decimals = 18;

  // whether token transfers are allowed
  bool public transferAllowed; // false by default

  /// @notice Total number of tokens in circulation
  uint256 public totalSupply = 10_000_000_000e18; // 10 billion Ondo

  // Allowance amounts on behalf of others
  mapping(address => mapping(address => uint96)) internal allowances;

  // Official record of token balances for each account
  mapping(address => uint96) internal balances;

  /// @notice A record of each accounts delegate
  mapping(address => address) public delegates;

  /// @notice A checkpoint for marking number of votes from a given block
  struct Checkpoint {
    uint32 fromBlock;
    uint96 votes;
  }

  /// @notice A record of votes checkpoints for each account, by index
  mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

  /// @notice The number of checkpoints for each account
  mapping(address => uint32) public numCheckpoints;

  /// @notice The EIP-712 typehash for the contract's domain
  bytes32 public constant DOMAIN_TYPEHASH =
    keccak256(
      "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
    );

  /// @notice The EIP-712 typehash for the delegation struct used by the contract
  bytes32 public constant DELEGATION_TYPEHASH =
    keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

  /// @notice The identifier of the role which allows special transfer privileges.
  bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  /// @notice A record of states for signing / validating signatures
  mapping(address => uint256) public nonces;

  /// @notice An event thats emitted when an account changes its delegate
  event DelegateChanged(
    address indexed delegator,
    address indexed fromDelegate,
    address indexed toDelegate
  );

  /// @notice An event thats emitted when a delegate account's vote balance changes
  event DelegateVotesChanged(
    address indexed delegate,
    uint256 previousBalance,
    uint256 newBalance
  );

  /// @notice The standard EIP-20 transfer event
  event Transfer(address indexed from, address indexed to, uint256 amount);

  /// @notice The standard EIP-20 approval event
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 amount
  );

  event CliffTimestampUpdate(uint256 newTimestamp);

  /**
   * @dev Emitted when the transfer is enabled triggered by `account`.
   */
  event TransferEnabled(address account);

  /// @notice a modifier which checks if transfers are allowed
  modifier whenTransferAllowed() {
    require(
      transferAllowed || hasRole(TRANSFER_ROLE, msg.sender),
      "OndoToken: Transfers not allowed or not right privillege"
    );
    _;
  }

  /**
   * @notice Construct a new Ondo token
   * @param _governance The initial account to grant owner permission and all the tokens
   */
  constructor(
    address _governance,
    uint256 _cliffTimestamp,
    uint256 _tranche1VestingPeriod,
    uint256 _tranche2VestingPeriod,
    uint256 _seedVestingPeriod
  )
    LinearTimelock(
      _cliffTimestamp,
      _tranche1VestingPeriod,
      _tranche2VestingPeriod,
      _seedVestingPeriod
    )
  {
    balances[_governance] = uint96(totalSupply);
    _setupRole(DEFAULT_ADMIN_ROLE, _governance);
    _setupRole(TRANSFER_ROLE, _governance);
    _setupRole(MINTER_ROLE, _governance);
    emit Transfer(address(0), _governance, totalSupply);
  }

  /**
   * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
   * @param account The address of the account holding the funds
   * @param spender The address of the account spending the funds
   * @return The number of tokens approved
   */
  function allowance(address account, address spender)
    external
    view
    returns (uint256)
  {
    return allowances[account][spender];
  }

  /**
   * @notice Approve `spender` to transfer up to `amount` from `src`
   * @dev This will overwrite the approval amount for `spender`
   *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
   * @param spender The address of the account which may transfer tokens
   * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
   * @return Whether or not the approval succeeded
   */
  function approve(address spender, uint256 rawAmount) external returns (bool) {
    uint96 amount;
    if (rawAmount == type(uint256).max) {
      amount = type(uint96).max;
    } else {
      amount = safe96(rawAmount, "Ondo::approve: amount exceeds 96 bits");
    }

    allowances[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);
    return true;
  }

  /**
   * @notice Get the number of tokens held by the `account`
   * @param account The address of the account to get the balance of
   * @return The number of tokens held
   */
  function balanceOf(address account) external view returns (uint256) {
    return balances[account];
  }

  /**
   * @notice Get the total number of UNLOCKED tokens held by the `account`
   * @param account The address of the account to get the unlocked balance of
   * @return The number of unlocked tokens held.
   */
  function getFreedBalance(address account) external view returns (uint256) {
    if (investorBalances[account].initialBalance > 0) {
      return _getFreedBalance(account);
    } else {
      return balances[account];
    }
  }

  /**
   * @notice Transfer `amount` tokens from `msg.sender` to `dst`
   * @param dst The address of the destination account
   * @param rawAmount The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transfer(address dst, uint256 rawAmount) external returns (bool) {
    uint96 amount = safe96(rawAmount, "Ondo::transfer: amount exceeds 96 bits");
    _transferTokens(msg.sender, dst, amount);
    return true;
  }

  /**
   * @notice Transfer `amount` tokens from `src` to `dst`
   * @param src The address of the source account
   * @param dst The address of the destination account
   * @param rawAmount The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transferFrom(
    address src,
    address dst,
    uint256 rawAmount
  ) external returns (bool) {
    address spender = msg.sender;
    uint96 spenderAllowance = allowances[src][spender];
    uint96 amount = safe96(rawAmount, "Ondo::approve: amount exceeds 96 bits");

    if (spender != src && spenderAllowance != type(uint96).max) {
      uint96 newAllowance = sub96(
        spenderAllowance,
        amount,
        "Ondo::transferFrom: transfer amount exceeds spender allowance"
      );
      allowances[src][spender] = newAllowance;

      emit Approval(src, spender, newAllowance);
    }

    _transferTokens(src, dst, amount);
    return true;
  }

  /**
   * @notice Delegate votes from `msg.sender` to `delegatee`
   * @param delegatee The address to delegate votes to
   */
  function delegate(address delegatee) public {
    return _delegate(msg.sender, delegatee);
  }

  /**
   * @notice Delegates votes from signatory to `delegatee`
   * @param delegatee The address to delegate votes to
   * @param nonce The contract state required to match the signature
   * @param expiry The time at which to expire the signature
   * @param v The recovery byte of the signature
   * @param r Half of the ECDSA signature pair
   * @param s Half of the ECDSA signature pair
   */
  function delegateBySig(
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    bytes32 domainSeparator = keccak256(
      abi.encode(
        DOMAIN_TYPEHASH,
        keccak256(bytes(name)),
        getChainId(),
        address(this)
      )
    );
    bytes32 structHash = keccak256(
      abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry)
    );
    bytes32 digest = keccak256(
      abi.encodePacked("\x19\x01", domainSeparator, structHash)
    );
    address signatory = ecrecover(digest, v, r, s);
    require(signatory != address(0), "Ondo::delegateBySig: invalid signature");
    require(nonce == nonces[signatory]++, "Ondo::delegateBySig: invalid nonce");
    require(
      block.timestamp <= expiry,
      "Ondo::delegateBySig: signature expired"
    );
    return _delegate(signatory, delegatee);
  }

  /**
   * @notice Gets the current votes balance for `account`
   * @param account The address to get votes balance
   * @return The number of current votes for `account`
   */
  function getCurrentVotes(address account) external view returns (uint96) {
    uint32 nCheckpoints = numCheckpoints[account];
    return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
  }

  /**
   * @notice Determine the prior number of votes for an account as of a block number
   * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
   * @param account The address of the account to check
   * @param blockNumber The block number to get the vote balance at
   * @return The number of votes the account had as of the given block
   */
  function getPriorVotes(address account, uint256 blockNumber)
    public
    view
    returns (uint96)
  {
    require(
      blockNumber < block.number,
      "Ondo::getPriorVotes: not yet determined"
    );

    uint32 nCheckpoints = numCheckpoints[account];
    if (nCheckpoints == 0) {
      return 0;
    }

    // First check most recent balance
    if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
      return checkpoints[account][nCheckpoints - 1].votes;
    }

    // Next check implicit zero balance
    if (checkpoints[account][0].fromBlock > blockNumber) {
      return 0;
    }

    uint32 lower = 0;
    uint32 upper = nCheckpoints - 1;
    while (upper > lower) {
      uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
      Checkpoint memory cp = checkpoints[account][center];
      if (cp.fromBlock == blockNumber) {
        return cp.votes;
      } else if (cp.fromBlock < blockNumber) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    return checkpoints[account][lower].votes;
  }

  /**
   * @notice Create `rawAmount` new tokens and assign them to `account`.
   * @param account The address to give newly minted tokens to
   * @param rawAmount Number of new tokens to mint.
   * @dev Even though total token supply is uint96, we use uint256 for the amount for consistency with other external interfaces.
   */
  function mint(address account, uint256 rawAmount) external {
    require(hasRole(MINTER_ROLE, msg.sender), "Ondo::mint: not authorized");
    require(account != address(0), "cannot mint to the zero address");

    uint96 amount = safe96(rawAmount, "Ondo::mint: amount exceeds 96 bits");
    uint96 supply = safe96(
      totalSupply,
      "Ondo::mint: totalSupply exceeds 96 bits"
    );
    totalSupply = add96(supply, amount, "Ondo::mint: token supply overflow");
    balances[account] = add96(
      balances[account],
      amount,
      "Ondo::mint: balance overflow"
    );

    emit Transfer(address(0), account, amount);
  }

  function _delegate(address delegator, address delegatee) internal {
    address currentDelegate = delegates[delegator];
    uint96 delegatorBalance = balances[delegator];
    delegates[delegator] = delegatee;

    emit DelegateChanged(delegator, currentDelegate, delegatee);

    _moveDelegates(currentDelegate, delegatee, delegatorBalance);
  }

  function _transferTokens(
    address src,
    address dst,
    uint96 amount
  ) internal whenTransferAllowed {
    require(
      src != address(0),
      "Ondo::_transferTokens: cannot transfer from the zero address"
    );
    require(
      dst != address(0),
      "Ondo::_transferTokens: cannot transfer to the zero address"
    );
    if (investorBalances[src].initialBalance > 0) {
      require(
        amount <= _getFreedBalance(src),
        "Ondo::_transferTokens: not enough unlocked balance"
      );
    }

    balances[src] = sub96(
      balances[src],
      amount,
      "Ondo::_transferTokens: transfer amount exceeds balance"
    );
    balances[dst] = add96(
      balances[dst],
      amount,
      "Ondo::_transferTokens: transfer amount overflows"
    );
    emit Transfer(src, dst, amount);

    _moveDelegates(delegates[src], delegates[dst], amount);
  }

  function _moveDelegates(
    address srcRep,
    address dstRep,
    uint96 amount
  ) internal {
    if (srcRep != dstRep && amount > 0) {
      if (srcRep != address(0)) {
        uint32 srcRepNum = numCheckpoints[srcRep];
        uint96 srcRepOld = srcRepNum > 0
          ? checkpoints[srcRep][srcRepNum - 1].votes
          : 0;
        uint96 srcRepNew = sub96(
          srcRepOld,
          amount,
          "Ondo::_moveVotes: vote amount underflows"
        );
        _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
      }

      if (dstRep != address(0)) {
        uint32 dstRepNum = numCheckpoints[dstRep];
        uint96 dstRepOld = dstRepNum > 0
          ? checkpoints[dstRep][dstRepNum - 1].votes
          : 0;
        uint96 dstRepNew = add96(
          dstRepOld,
          amount,
          "Ondo::_moveVotes: vote amount overflows"
        );
        _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
      }
    }
  }

  function _writeCheckpoint(
    address delegatee,
    uint32 nCheckpoints,
    uint96 oldVotes,
    uint96 newVotes
  ) internal {
    uint32 blockNumber = safe32(
      block.number,
      "Ondo::_writeCheckpoint: block number exceeds 32 bits"
    );

    if (
      nCheckpoints > 0 &&
      checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber
    ) {
      checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
    } else {
      checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
      numCheckpoints[delegatee] = nCheckpoints + 1;
    }

    emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
  }

  function getChainId() internal view returns (uint256) {
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    return chainId;
  }

  /**
   * @notice Turn on _transferAllowed variable. Transfers are enabled
   */
  function enableTransfer() external {
    require(
      hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
      "Ondo::enableTransfer: not authorized"
    );
    transferAllowed = true;
    emit TransferEnabled(msg.sender);
  }

  /**
   * @notice Called by merkle airdrop contract to initialize locked balances
   */
  function updateTrancheBalance(
    address beneficiary,
    uint256 rawAmount,
    IOndo.InvestorType investorType
  ) external {
    require(hasRole(TIMELOCK_UPDATE_ROLE, msg.sender));
    require(rawAmount > 0, "Ondo::updateTrancheBalance: amount must be > 0");
    require(
      investorBalances[beneficiary].initialBalance == 0,
      "Ondo::updateTrancheBalance: already has timelocked Ondo"
    ); //Prevents users from being in more than 1 tranche

    uint96 amount = safe96(
      rawAmount,
      "Ondo::updateTrancheBalance: amount exceeds 96 bits"
    );
    investorBalances[beneficiary] = InvestorParam(investorType, amount);
  }

  /**
   * @notice Internal function the amount of unlocked Ondo for an account that participated in Coinlist/Seed Investments
   */
  function _getFreedBalance(address account) internal view returns (uint96) {
    if (passedAllVestingPeriods()) {
      //all vesting periods are over, just return the total balance
      return balances[account];
    } else {
      InvestorParam memory investorParam = investorBalances[account];
      if (passedCliff()) {
        //we are in between the cliff timestamp and last vesting period
        (uint256 vestingPeriod, uint256 elapsed) = _getTrancheInfo(
          investorParam.investorType
        );
        uint96 lockedBalance = sub96(
          investorParam.initialBalance,
          _proportionAvailable(elapsed, vestingPeriod, investorParam),
          "Ondo::getFreedBalance: locked balance underflow"
        );
        return
          sub96(
            balances[account],
            lockedBalance,
            "Ondo::getFreedBalance: total freed balance underflow"
          );
      } else {
        //we have not hit the cliff yet, all investor balance is locked
        return
          sub96(
            balances[account],
            investorParam.initialBalance,
            "Ondo::getFreedBalance: balance underflow"
          );
      }
    }
  }

  function updateCliffTimestamp(uint256 newTimestamp) external {
    require(
      hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
      "Ondo::updateCliffTimestamp: not authorized"
    );
    cliffTimestamp = newTimestamp;
    emit CliffTimestampUpdate(newTimestamp);
  }
}