// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {IVoteToken} from '../interfaces/IVoteToken.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {LowGasSafeMath} from '../lib/LowGasSafeMath.sol';
import {Context} from '@openzeppelin/contracts/utils/Context.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';

/**
 * @title VoteToken
 * @notice Custom token which tracks voting power for governance
 * @dev This is an abstraction of a fork of the Compound governance contract
 * VoteToken is used by BABL to allow tracking voting power
 * Checkpoints are created every time state is changed which record voting power
 * Inherits standard ERC20 behavior
 */

abstract contract VoteToken is Context, ERC20, Ownable, IVoteToken, ReentrancyGuard {
    using LowGasSafeMath for uint256;
    using Address for address;

    /* ============ Events ============ */

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /* ============ Modifiers ============ */

    /* ============ State Variables ============ */

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256('EIP712Domain(string name,uint256 chainId,address verifyingContract)');

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256('Delegation(address delegatee,uint256 nonce,uint256 expiry)');

    /// @dev A record of votes checkpoints for each account, by index
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

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /* ============ Functions ============ */

    /* ============ Constructor ============ */

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    /* ============ External Functions ============ */

    /* ===========  Token related Gov Functions ====== */

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Delegating votes from msg.sender to delegatee
     *
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */

    function delegate(address delegatee) external override {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Delegate votes using signature to 'delegatee'
     *
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
        bytes32 s,
        bool prefix
    ) external override {
        address signatory;
        bytes32 domainSeparator =
            keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, structHash));
        if (prefix) {
            bytes32 digestHash = keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', digest));
            signatory = ecrecover(digestHash, v, r, s);
        } else {
            signatory = ecrecover(digest, v, r, s);
        }

        require(balanceOf(signatory) > 0, 'VoteToken::delegateBySig: invalid delegator');
        require(signatory != address(0), 'VoteToken::delegateBySig: invalid signature');
        require(nonce == nonces[signatory], 'VoteToken::delegateBySig: invalid nonce');
        nonces[signatory]++;
        require(block.timestamp <= expiry, 'VoteToken::delegateBySig: signature expired');
        return _delegate(signatory, delegatee);
    }

    /**
     * GOVERNANCE FUNCTION. Check Delegate votes using signature to 'delegatee'
     *
     * @notice Get current voting power for an account
     * @param account Account to get voting power for
     * @return Voting power for an account
     */
    function getCurrentVotes(address account) external view virtual override returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * GOVERNANCE FUNCTION. Get voting power at a specific block for an account
     *
     * @param account Account to get voting power for
     * @param blockNumber Block to get voting power at
     * @return Voting power for an account at specific block
     */
    function getPriorVotes(address account, uint256 blockNumber) external view virtual override returns (uint96) {
        require(blockNumber < block.number, 'BABLToken::getPriorVotes: not yet determined');
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

    function getMyDelegatee() external view override returns (address) {
        return delegates[msg.sender];
    }

    function getDelegatee(address account) external view override returns (address) {
        return delegates[account];
    }

    function getCheckpoints(address account, uint32 id)
        external
        view
        override
        returns (uint32 fromBlock, uint96 votes)
    {
        Checkpoint storage getCheckpoint = checkpoints[account][id];
        return (getCheckpoint.fromBlock, getCheckpoint.votes);
    }

    function getNumberOfCheckpoints(address account) external view override returns (uint32) {
        return numCheckpoints[account];
    }

    /* ============ Internal Only Function ============ */

    /**
     * GOVERNANCE FUNCTION. Make a delegation
     *
     * @dev Internal function to delegate voting power to an account
     * @param delegator The address of the account delegating votes from
     * @param delegatee The address to delegate votes to
     */

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = safe96(_balanceOf(delegator), 'VoteToken::_delegate: uint96 overflow');
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _balanceOf(address account) internal view virtual returns (uint256) {
        return balanceOf(account);
    }

    /**
     * GOVERNANCE FUNCTION. Move the delegates
     *
     * @dev Internal function to move delegates between accounts
     * @param srcRep The address of the account delegating votes from
     * @param dstRep The address of the account delegating votes to
     * @param amount The voting power to move
     */
    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint96 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            // It must not revert but do nothing in cases of address(0) being part of the move
            // Sub voting amount to source in case it is not the zero address (e.g. transfers)
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, 'VoteToken::_moveDelegates: vote amount underflows');
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }
            if (dstRep != address(0)) {
                // Add it to destination in case it is not the zero address (e.g. any transfer of tokens or delegations except a first mint to a specific address)
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, 'VoteToken::_moveDelegates: vote amount overflows');
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    /**
     * GOVERNANCE FUNCTION. Internal function to write a checkpoint for voting power
     *
     * @dev internal function to write a checkpoint for voting power
     * @param delegatee The address of the account delegating votes to
     * @param nCheckpoints The num checkpoint
     * @param oldVotes The previous voting power
     * @param newVotes The new voting power
     */
    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint96 oldVotes,
        uint96 newVotes
    ) internal {
        uint32 blockNumber = safe32(block.number, 'VoteToken::_writeCheckpoint: block number exceeds 32 bits');

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    /**
     * INTERNAL FUNCTION. Internal function to convert from uint256 to uint32
     *
     * @dev internal function to convert from uint256 to uint32
     */
    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    /**
     * INTERNAL FUNCTION. Internal function to convert from uint256 to uint96
     *
     * @dev internal function to convert from uint256 to uint96
     */
    function safe96(uint256 n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    /**
     * INTERNAL FUNCTION. Internal function to add two uint96 numbers
     *
     * @dev internal safe math function to add two uint96 numbers
     */
    function add96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    /**
     * INTERNAL FUNCTION. Internal function to subtract two uint96 numbers
     *
     * @dev internal safe math function to subtract two uint96 numbers
     */
    function sub96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * INTERNAL FUNCTION. Internal function to get chain ID
     *
     * @dev internal function to get chain ID
     */
    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}