//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./ERC20Permit.sol";

abstract contract DelegateERC20 is ERC20Permit {

  mapping (address => address) public delegates;
  
  struct Checkpoint {
    uint32 fromBlock;
    uint votes;
  }

  mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;
  mapping (address => uint32) public numCheckpoints;


  bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

  event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
  event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);


  constructor(string memory name_, string memory symbol_) ERC20Permit(name_, symbol_) {
  }

  function _mint(address dst, uint wad) internal override {
    super._mint(dst, wad); 
    _moveDelegates(address(0), delegates[dst], wad);
  }

  function _transfer(address src, address dst, uint wad) internal override returns (bool) {
    super._transfer(src, dst, wad);
    _moveDelegates(delegates[src], delegates[dst], wad);
    return true;
  }

  function _burn(address src, uint wad) internal override {
    super._burn(src, wad);
    _moveDelegates(delegates[src], address(0), wad);
  }

  function delegate(address delegatee) public {
    return _delegate(msg.sender, delegatee);
  }

  function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
    bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
    
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
    address signatory = ecrecover(digest, v, r, s);
    require(signatory != address(0), "delegateBySig: invalid signature");
    require(nonce == nonces[signatory]++, "delegateBySig: invalid nonce");
    require(block.timestamp <= expiry, "delegateBySig: signature expired");
    return _delegate(signatory, delegatee);
  }

  function getCurrentVotes(address account) external view returns (uint256) {
    uint32 nCheckpoints = numCheckpoints[account];
    return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
  }

  function getPriorVotes(address account, uint blockNumber) public view returns (uint256) {
    require(blockNumber < block.number, "getPriorVotes: not yet determined");

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

  function _delegate(address delegator, address delegatee) internal {
    address currentDelegate = delegates[delegator];
    uint delegatorBalance = balanceOf(delegator);
    delegates[delegator] = delegatee;

    emit DelegateChanged(delegator, currentDelegate, delegatee);
    _moveDelegates(currentDelegate, delegatee, delegatorBalance);
  }

  function _moveDelegates(address srcRep, address dstRep, uint amount) internal {
    if (srcRep != dstRep && amount > 0) {
      if (srcRep != address(0)) {
          uint32 srcRepNum = numCheckpoints[srcRep];
          uint srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
          uint srcRepNew = srcRepOld - amount;
          _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
      }

      if (dstRep != address(0)) {
          uint32 dstRepNum = numCheckpoints[dstRep];
          uint dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
          uint dstRepNew = dstRepOld + amount;
          _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
      }
    }
  }

  function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint oldVotes, uint newVotes) internal {
    uint32 blockNumber = safe32(block.number, "_writeCheckpoint: block number exceeds 32 bits");

    if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
        checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
    } else {
        checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
        numCheckpoints[delegatee] = nCheckpoints + 1;
    }

    emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
  }

  function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }

}