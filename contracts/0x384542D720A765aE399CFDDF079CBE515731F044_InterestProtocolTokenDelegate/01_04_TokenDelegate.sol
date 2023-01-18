// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "./IToken.sol";
import "./TokenStorage.sol";

contract InterestProtocolTokenDelegate is TokenDelegateStorageV1, TokenEvents, ITokenDelegate {
  /// @notice The EIP-712 typehash for the contract's domain
  bytes32 public constant DOMAIN_TYPEHASH =
    keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

  /// @notice The EIP-712 typehash for the delegation struct used by the contract
  bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

  /// @notice The EIP-712 typehash for the permit struct used by the contract
  bytes32 public constant PERMIT_TYPEHASH =
    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

  uint96 public constant UINT96_MAX = 2 ** 96 - 1;

  uint256 public constant UINT256_MAX = 2 ** 256 - 1;

  /**
   * @notice Used to initialize the contract during delegator constructor
   * @param account_ The address to recieve initial suppply   * @param initialSupply_ set initial supply
   */
  function initialize(address account_, uint256 initialSupply_) public override {
    require(totalSupply == 0, "initialize: can only do once");
    require(account_ != address(0), "initialize: invalid address");
    require(initialSupply_ > 0, "invalid initial supply");

    totalSupply = initialSupply_;

    require(initialSupply_ < 2 ** 96, "initialSupply_ overflow uint96");

    balances[account_] = uint96(totalSupply);
    emit Transfer(address(0), account_, totalSupply);
  }

  /**
   * @notice Change token name
   * @param name_ New token name
   */
  function changeName(string calldata name_) external override onlyOwner {
    require(bytes(name_).length > 0, "changeName: length invaild");

    emit ChangedName(name, name_);

    name = name_;
  }

  /**
   * @notice Change token symbol
   * @param symbol_ New token symbol
   */
  function changeSymbol(string calldata symbol_) external override onlyOwner {
    require(bytes(symbol_).length > 0, "changeSymbol: length invaild");

    emit ChangedSymbol(symbol, symbol_);

    symbol = symbol_;
  }

  /**
   * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
   * @param account The address of the account holding the funds
   * @param spender The address of the account spending the funds
   * @return The number of tokens approved
   */
  function allowance(address account, address spender) external view override returns (uint256) {
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
  function approve(address spender, uint256 rawAmount) external override returns (bool) {
    uint96 amount;
    if (rawAmount == UINT256_MAX) {
      amount = UINT96_MAX;
    } else {
      amount = safe96(rawAmount, "approve: amount exceeds 96 bits");
    }

    allowances[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);
    return true;
  }

  /**
   * @notice Triggers an approval from owner to spends
   * @param owner The address to approve from
   * @param spender The address to be approved
   * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
   * @param deadline The time at which to expire the signature
   * @param v The recovery byte of the signature
   * @param r Half of the ECDSA signature pair
   * @param s Half of the ECDSA signature pair
   */
  function permit(
    address owner,
    address spender,
    uint256 rawAmount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override {
    uint96 amount;
    if (rawAmount == UINT256_MAX) {
      amount = UINT96_MAX;
    } else {
      amount = safe96(rawAmount, "permit: amount exceeds 96 bits");
    }

    bytes32 domainSeparator = keccak256(
      abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainid(), address(this))
    );
    bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, rawAmount, nonces[owner]++, deadline));
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    require(
      uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
      "permit: invalid signature"
    );
    address signatory = ecrecover(digest, v, r, s);
    require(signatory != address(0x0), "permit: invalid signature");

    require(block.timestamp <= deadline, "permit: signature expired");

    allowances[owner][spender] = amount;

    emit Approval(owner, spender, amount);
  }

  /**
   * @notice Get the number of tokens held by the `account`
   * @param account The address of the account to get the balance of
   * @return The number of tokens held
   */
  function balanceOf(address account) external view override returns (uint256) {
    return balances[account];
  }

  /**
   * @notice Transfer `amount` tokens from `msg.sender` to `dst`
   * @param dst The address of the destination account
   * @param rawAmount The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transfer(address dst, uint256 rawAmount) external override returns (bool) {
    uint96 amount = safe96(rawAmount, "transfer: amount exceeds 96 bits");
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
  function transferFrom(address src, address dst, uint256 rawAmount) external override returns (bool) {
    address spender = msg.sender;
    uint96 spenderAllowance = allowances[src][spender];
    uint96 amount = safe96(rawAmount, "transferFrom: amount exceeds 96 bits");

    if (spender != src && spenderAllowance != UINT96_MAX) {
      uint96 newAllowance = sub96(spenderAllowance, amount, "transferFrom: transfer amount exceeds spender allowance");
      allowances[src][spender] = newAllowance;

      emit Approval(src, spender, newAllowance);
    }

    _transferTokens(src, dst, amount);
    return true;
  }

  /**
   * @notice Mint new tokens
   * @param dst The address of the destination account
   * @param rawAmount The number of tokens to be minted
   */
  /**
   * Removed mint for compliance
   function mint(address dst, uint256 rawAmount) external override onlyOwner {
    require(dst != address(0), "mint: cant transfer to 0 address");
    uint96 amount = safe96(rawAmount, "mint: amount exceeds 96 bits");
    totalSupply = safe96(totalSupply + amount, "mint: totalSupply exceeds 96 bits");

    // transfer the amount to the recipient
    balances[dst] = add96(balances[dst], amount, "mint: transfer amount overflows");
    emit Transfer(address(0), dst, amount);

    // move delegates
    _moveDelegates(address(0), delegates[dst], amount);
  }
   */

  /**
   * @notice Delegate votes from `msg.sender` to `delegatee`
   * @param delegatee The address to delegate votes to
   */
  function delegate(address delegatee) public override {
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
  ) public override {
    bytes32 domainSeparator = keccak256(
      abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainid(), address(this))
    );
    bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    require(
      uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
      "delegateBySig: invalid signature"
    );
    address signatory = ecrecover(digest, v, r, s);
    require(signatory != address(0x0), "delegateBySig: invalid signature");

    require(nonce == nonces[signatory]++, "delegateBySig: invalid nonce");
    require(block.timestamp <= expiry, "delegateBySig: signature expired");
    return _delegate(signatory, delegatee);
  }

  /**
   * @notice Gets the current votes balance for `account`
   * @param account The address to get votes balance
   * @return The number of current votes for `account`
   */
  function getCurrentVotes(address account) external view override returns (uint96) {
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
  function getPriorVotes(address account, uint256 blockNumber) public view override returns (uint96) {
    require(blockNumber < block.number, "getPriorVotes: not determined");
    bool ok = false;
    uint96 votes = 0;
    // check naive cases
    (ok, votes) = _naivePriorVotes(account, blockNumber);
    if (ok == true) {
      return votes;
    }
    uint32 lower = 0;
    uint32 upper = numCheckpoints[account] - 1;
    while (upper > lower) {
      uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
      Checkpoint memory cp = checkpoints[account][center];
      (ok, lower, upper) = _binarySearch(cp.fromBlock, blockNumber, lower, upper);
      if (ok == true) {
        return cp.votes;
      }
    }
    return checkpoints[account][lower].votes;
  }

  function _naivePriorVotes(address account, uint256 blockNumber) internal view returns (bool ok, uint96 ans) {
    uint32 nCheckpoints = numCheckpoints[account];
    // if no checkpoints, must be 0
    if (nCheckpoints == 0) {
      return (true, 0);
    }
    // First check most recent balance
    if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
      return (true, checkpoints[account][nCheckpoints - 1].votes);
    }
    // Next check implicit zero balance
    if (checkpoints[account][0].fromBlock > blockNumber) {
      return (true, 0);
    }
    return (false, 0);
  }

  function _binarySearch(
    uint32 from,
    uint256 blk,
    uint32 lower,
    uint32 upper
  ) internal pure returns (bool ok, uint32 newLower, uint32 newUpper) {
    uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
    if (from == blk) {
      return (true, 0, 0);
    }
    if (from < blk) {
      return (false, center, upper);
    }
    return (false, lower, center - 1);
  }

  function _delegate(address delegator, address delegatee) internal {
    address currentDelegate = delegates[delegator];
    uint96 delegatorBalance = balances[delegator];
    delegates[delegator] = delegatee;

    emit DelegateChanged(delegator, currentDelegate, delegatee);

    _moveDelegates(currentDelegate, delegatee, delegatorBalance);
  }

  function _transferTokens(address src, address dst, uint96 amount) internal {
    require(src != address(0), "_transferTokens: cant 0addr");
    require(dst != address(0), "_transferTokens: cant 0addr");

    balances[src] = sub96(balances[src], amount, "_transferTokens: transfer amount exceeds balance");
    balances[dst] = add96(balances[dst], amount, "_transferTokens: transfer amount overflows");
    emit Transfer(src, dst, amount);

    _moveDelegates(delegates[src], delegates[dst], amount);
  }

  function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
    if (srcRep != dstRep && amount > 0) {
      if (srcRep != address(0)) {
        uint32 srcRepNum = numCheckpoints[srcRep];
        uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
        uint96 srcRepNew = sub96(srcRepOld, amount, "_moveVotes: vote amt underflows");
        _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
      }

      if (dstRep != address(0)) {
        uint32 dstRepNum = numCheckpoints[dstRep];
        uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
        uint96 dstRepNew = add96(dstRepOld, amount, "_moveVotes: vote amt overflows");
        _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
      }
    }
  }

  function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
    uint32 blockNumber = safe32(block.number, "_writeCheckpoint: blocknum exceeds 32 bits");

    if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
      checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
    } else {
      checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
      numCheckpoints[delegatee] = nCheckpoints + 1;
    }

    emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
  }

  function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
    require(n < 2 ** 32, errorMessage);
    return uint32(n);
  }

  function safe96(uint256 n, string memory errorMessage) internal pure returns (uint96) {
    require(n < 2 ** 96, errorMessage);
    return uint96(n);
  }

  function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
    uint96 c = a + b;
    require(c >= a, errorMessage);
    return c;
  }

  function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
    require(b <= a, errorMessage);
    return a - b;
  }

  function getChainid() internal view returns (uint256) {
    uint256 chainId;
    //solhint-disable-next-line no-inline-assembly
    assembly {
      chainId := chainid()
    }
    return chainId;
  }
}