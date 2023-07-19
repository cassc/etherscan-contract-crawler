// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.4;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "./DetfReflect.sol";


/// @title Detf smart contract
/// @author D-ETF.com
/// @notice DETF ERC20 token contract
/// @dev Deployable smart contract, which includes the governance logic (voting, delegating and etc).
contract Detf is DetfReflect {
    using SafeMath for uint256;

    /// @notice A record of each accounts delegate
    mapping(address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint256 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint256) public numCheckpoints;

    mapping(address => uint256) public delegatorVotes;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);


    //  --------------------
    //  CONSTRUCTOR
    //  --------------------


    constructor (address uniswapV2Router_, address usdc_) DetfReflect(uniswapV2Router_, usdc_) {
        // Silence
    }

    fallback () external payable {
        // Empty fallback
    }

    receive () external payable {
        // Empty receive
    }


    //  --------------------
    //  SETTERS
    //  --------------------


    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        _moveDelegates(delegates[sender], delegates[recipient], amount, sender, true);
        super._transfer(sender, recipient, amount);
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
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), block.chainid, address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "delegateBySig: Invalid signature!");
        require(nonce == nonces[signatory]++, "delegateBySig: Invalid nonce!");
        require(block.timestamp <= expiry, "delegateBySig: Signature expired!");
        return _delegate(signatory, delegatee);
    }


    //  --------------------
    //  GETTERS
    //  --------------------


    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint256 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "getPriorVotes: Not yet determined!");

        uint256 nCheckpoints = numCheckpoints[account];
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

        uint256 lower = 0;
        uint256 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
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


    //  --------------------
    //  INTERNAL
    //  --------------------


    /// @dev Delegate votes from the sender to the delegatee.
    /// Users can delegate to 1 address at a time, and the number of votes added to the delegatee’s vote count is equivalent to the balance of DETF in the user’s account.
    /// Votes are delegated from the current block and onward, until the sender delegates again, or transfers their DETF.
    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator);
        delegates[delegator] = delegatee;
        
        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance, delegator, false);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount, address senderVotes, bool isTransfer) internal {
        uint256 delegateVotes = delegatorVotes[senderVotes];
        uint256 delegatorBalance = balanceOf(senderVotes);

        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint256 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew;
                if (isTransfer) {
                    if (amount > delegateVotes) {
                        delegatorVotes[senderVotes] = delegatorBalance.sub(amount);
                        srcRepNew = srcRepOld.add(delegatorVotes[senderVotes]).sub(delegateVotes);
                    } else {
                        delegatorVotes[senderVotes] = delegateVotes - amount;
                        srcRepNew = srcRepOld.sub(amount);
                    }
                } else {
                    if (delegateVotes != amount) {
                        delegatorVotes[senderVotes] = amount;
                        srcRepNew = srcRepOld.sub(delegateVotes);
                    } else {
                        srcRepNew = srcRepOld.sub(amount);
                    }
                }
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            } else {
                delegatorVotes[senderVotes] = amount;
            }

            if (dstRep != address(0)) {
                uint256 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                if (isTransfer) delegatorVotes[dstRep] += amount;
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        } else if (!isTransfer && srcRep == dstRep && amount != delegateVotes) {
            uint256 dstRepNum = numCheckpoints[dstRep];
            uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
            uint256 dstRepNew = dstRepOld.sub(delegateVotes).add(amount);
            delegatorVotes[senderVotes] = amount;
            _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
        }
    }

    function _writeCheckpoint(address delegatee, uint256 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
      uint256 blockNumber = block.number;

      if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[delegatee] = nCheckpoints + 1;
      }

      emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }
}