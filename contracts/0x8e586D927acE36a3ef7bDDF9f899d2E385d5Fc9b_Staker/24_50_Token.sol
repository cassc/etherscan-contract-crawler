// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
  @title A basic ERC-20 token with voting functionality.
  @author Tim Clancy

  This contract is used when deploying SuperFarm ERC-20 tokens.
  This token is created with a fixed, immutable cap and includes voting rights.
  Voting functionality is copied and modified from Sushi, and in turn from YAM:
  https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
  https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
  Which is in turn copied and modified from COMPOUND:
  https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol
*/
contract Token is ERC20Capped, Ownable {

  /// A version number for this Token contract's interface.
  uint256 public version = 1;

  /**
    Construct a new Token by providing it a name, ticker, and supply cap.

    @param _name The name of the new Token.
    @param _ticker The ticker symbol of the new Token.
    @param _cap The supply cap of the new Token.
  */
  constructor (string memory _name, string memory _ticker, uint256 _cap) public ERC20(_name, _ticker) ERC20Capped(_cap) { }

  /**
   * @dev Destroys `amount` tokens from the caller.
   *
   * See {ERC20-_burn}.
   */
  function burn(uint256 amount) public virtual {
      _burn(_msgSender(), amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, deducting from the caller's
   * allowance.
   *
   * See {ERC20-_burn} and {ERC20-allowance}.
   *
   * Requirements:
   *
   * - the caller must have allowance for ``accounts``'s tokens of at least
   * `amount`.
   */
  function burnFrom(address account, uint256 amount) public virtual {
      uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

      _approve(account, _msgSender(), decreasedAllowance);
      _burn(account, amount);
  }

  /**
    Allows Token creator to mint `_amount` of this Token to the address `_to`.
    New tokens of this Token cannot be minted if it would exceed the supply cap.
    Users are delegated votes when they are minted Token.

    @param _to the address to mint Tokens to.
    @param _amount the amount of new Token to mint.
  */
  function mint(address _to, uint256 _amount) external onlyOwner {
    _mint(_to, _amount);
    _moveDelegates(address(0), _delegates[_to], _amount);
  }

  /**
    Allows users to transfer tokens to a recipient, moving delegated votes with
    the transfer.

    @param recipient The address to transfer tokens to.
    @param amount The amount of tokens to send to `recipient`.
  */
  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    _moveDelegates(_delegates[msg.sender], _delegates[recipient], amount);
    return true;
  }

  /// @dev A mapping to record delegates for each address.
  mapping (address => address) internal _delegates;

  /// A checkpoint structure to mark some number of votes from a given block.
  struct Checkpoint {
    uint32 fromBlock;
    uint256 votes;
  }

  /// A mapping to record indexed Checkpoint votes for each address.
  mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

  /// A mapping to record the number of Checkpoints for each address.
  mapping (address => uint32) public numCheckpoints;

  /// The EIP-712 typehash for the contract's domain.
  bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

  /// The EIP-712 typehash for the delegation struct used by the contract.
  bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

  /// A mapping to record per-address states for signing / validating signatures.
  mapping (address => uint) public nonces;

  /// An event emitted when an address changes its delegate.
  event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

  /// An event emitted when the vote balance of a delegated address changes.
  event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

  /**
    Return the address delegated to by `delegator`.

    @return The address delegated to by `delegator`.
  */
  function delegates(address delegator) external view returns (address) {
    return _delegates[delegator];
  }

  /**
    Delegate votes from `msg.sender` to `delegatee`.

    @param delegatee The address to delegate votes to.
  */
  function delegate(address delegatee) external {
    return _delegate(msg.sender, delegatee);
  }

  /**
    Delegate votes from signatory to `delegatee`.

    @param delegatee The address to delegate votes to.
    @param nonce The contract state required for signature matching.
    @param expiry The time at which to expire the signature.
    @param v The recovery byte of the signature.
    @param r Half of the ECDSA signature pair.
    @param s Half of the ECDSA signature pair.
  */
  function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external {
    bytes32 domainSeparator = keccak256(
      abi.encode(
        DOMAIN_TYPEHASH,
        keccak256(bytes(name())),
        getChainId(),
        address(this)));

    bytes32 structHash = keccak256(
      abi.encode(
          DELEGATION_TYPEHASH,
          delegatee,
          nonce,
          expiry));

    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        domainSeparator,
        structHash));

    address signatory = ecrecover(digest, v, r, s);
    require(signatory != address(0), "Invalid signature.");
    require(nonce == nonces[signatory]++, "Invalid nonce.");
    require(now <= expiry, "Signature expired.");
    return _delegate(signatory, delegatee);
  }

  /**
    Get the current votes balance for the address `account`.

    @param account The address to get the votes balance of.
    @return The number of current votes for `account`.
  */
  function getCurrentVotes(address account) external view returns (uint256) {
    uint32 nCheckpoints = numCheckpoints[account];
    return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
  }

  /**
    Determine the prior number of votes for an address as of a block number.

    @dev The block number must be a finalized block or else this function will revert to prevent misinformation.
    @param account The address to check.
    @param blockNumber The block number to get the vote balance at.
    @return The number of votes the account had as of the given block.
  */
  function getPriorVotes(address account, uint blockNumber) external view returns (uint256) {
    require(blockNumber < block.number, "The specified block is not yet finalized.");

    uint32 nCheckpoints = numCheckpoints[account];
    if (nCheckpoints == 0) {
      return 0;
    }

    // First check the most recent balance.
    if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
      return checkpoints[account][nCheckpoints - 1].votes;
    }

    // Then check the implicit zero balance.
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
    An internal function to actually perform the delegation of votes.

    @param delegator The address delegating to `delegatee`.
    @param delegatee The address receiving delegated votes.
  */
  function _delegate(address delegator, address delegatee) internal {
    address currentDelegate = _delegates[delegator];
    uint256 delegatorBalance = balanceOf(delegator);
    _delegates[delegator] = delegatee;
    /* console.log('a-', currentDelegate, delegator, delegatee); */
    emit DelegateChanged(delegator, currentDelegate, delegatee);

    _moveDelegates(currentDelegate, delegatee, delegatorBalance);
  }

  /**
    An internal function to move delegated vote amounts between addresses.

    @param srcRep the previous representative who received delegated votes.
    @param dstRep the new representative to receive these delegated votes.
    @param amount the amount of delegated votes to move between representatives.
  */
  function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
    if (srcRep != dstRep && amount > 0) {

      // Decrease the number of votes delegated to the previous representative.
      if (srcRep != address(0)) {
        uint32 srcRepNum = numCheckpoints[srcRep];
        uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
        uint256 srcRepNew = srcRepOld.sub(amount);
        _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
      }

      // Increase the number of votes delegated to the new representative.
      if (dstRep != address(0)) {
        uint32 dstRepNum = numCheckpoints[dstRep];
        uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
        uint256 dstRepNew = dstRepOld.add(amount);
        _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
      }
    }
  }

  /**
    An internal function to write a checkpoint of modified vote amounts.
    This function is guaranteed to add at most one checkpoint per block.

    @param delegatee The address whose vote count is changed.
    @param nCheckpoints The number of checkpoints by address `delegatee`.
    @param oldVotes The prior vote count of address `delegatee`.
    @param newVotes The new vote count of address `delegatee`.
  */
  function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
    uint32 blockNumber = safe32(block.number, "Block number exceeds 32 bits.");

    if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
      checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
    } else {
      checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
      numCheckpoints[delegatee] = nCheckpoints + 1;
    }

    emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
  }

  /**
    A function to safely limit a number to less than 2^32.

    @param n the number to limit.
    @param errorMessage the error message to revert with should `n` be too large.
    @return The number `n` limited to 32 bits.
  */
  function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }

  /**
    A function to return the ID of the contract's particular network or chain.

    @return The ID of the contract's network or chain.
  */
  function getChainId() internal pure returns (uint) {
    uint256 chainId;
    assembly { chainId := chainid() }
    return chainId;
  }
}