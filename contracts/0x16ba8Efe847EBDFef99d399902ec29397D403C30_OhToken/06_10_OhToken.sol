// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IToken} from "./interfaces/IToken.sol";
import {OhSubscriber} from "./registry/OhSubscriber.sol";

/// @title Oh! Finance Token
/// @notice Protocol Governance and Profit-Share ERC-20 Token
contract OhToken is ERC20("Oh! Finance", "OH"), OhSubscriber, IToken {
    using SafeMath for uint256;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice The max token supply, minted on initialization. 100m tokens.
    uint256 public constant MAX_SUPPLY = 100000000e18;

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegator,address delegatee,uint256 nonce,uint256 deadline)");

    /// @notice the EIP-712 typehash for approving token transfers via signature
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash used for replay protection, set at deployment
    // solhint-disable-next-line
    bytes32 public immutable DOMAIN_SEPARATOR;

    /// @notice Delegate votes from `msg.sender` to `delegatee`
    mapping(address => address) public delegates;

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    constructor(address registry_) OhSubscriber(registry_) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), keccak256(bytes("1")), getChainId(), address(this))
        );

        _mint(msg.sender, MAX_SUPPLY);
    }

    /// @notice Delegate votes from `msg.sender` to `delegatee`
    /// @param delegatee The address to delegate votes to
    function delegate(address delegatee) external override {
        return _delegate(msg.sender, delegatee);
    }

    /// @notice Delegates votes from `delegator` to `delegatee`
    /// @param delegator the address holding tokens
    /// @param delegatee The address to delegate votes to
    /// @param deadline The time at which to expire the signature
    /// @param v The recovery byte of the signature
    /// @param r Half of the ECDSA signature pair
    /// @param s Half of the ECDSA signature pair
    function delegateBySig(
        address delegator,
        address delegatee,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        // solhint-disable-next-line
        require(block.timestamp <= deadline, "Delegate: Invalid Expiration");
        require(delegator != address(0), "Delegate: Invalid Delegator");

        uint256 currentValidNonce = nonces[delegator];
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(abi.encode(DELEGATION_TYPEHASH, delegator, delegatee, currentValidNonce, deadline))
                )
            );

        require(delegator == ecrecover(digest, v, r, s), "Delegate: Invalid Signature");
        nonces[delegator] = currentValidNonce.add(1);
        return _delegate(delegator, delegatee);
    }

    /// @dev implements the permit function per EIP-712
    /// @param owner the owner of the funds
    /// @param spender the spender
    /// @param value the amount
    /// @param deadline the deadline timestamp, type(uint256).max for max deadline
    /// @param v the recovery byte of the signature
    /// @param r half of the ECDSA signature pair
    /// @param s half of the ECDSA signature pair
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(block.timestamp <= deadline, "Permit: Invalid Deadline");
        require(owner != address(0), "Permit: Invalid Owner");

        uint256 currentValidNonce = nonces[owner];
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, currentValidNonce, deadline))
                )
            );

        require(owner == ecrecover(digest, v, r, s), "Permit: Invalid Signature");
        nonces[owner] = currentValidNonce.add(1);
        return _approve(owner, spender, value);
    }

    /// @notice Gets the current votes balance for `account`
    /// @param account The address to get votes balance
    /// @return The number of current votes for `account`
    function getCurrentVotes(address account) external view override returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /// @notice Determine the prior number of votes for an account as of a block number
    /// @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
    /// @param account The address of the account to check
    /// @param blockNumber The block number to get the vote balance at
    /// @return The number of votes the account had as of the given block
    function getPriorVotes(address account, uint256 blockNumber) external view override returns (uint256) {
        require(blockNumber < block.number, "GetPriorVotes: Invalid Block");

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

    /// @notice Destroys an amount of tokens from the caller
    /// @param amount The amount of tokens to burn
    function burn(uint256 amount) public override {
        _burn(msg.sender, amount);
    }

    /// @notice Creates an amount of tokens on a recipient address
    /// @param recipient The receiver of the tokens
    /// @param amount The amount of tokens to mint
    /// @dev callable by governance only
    function mint(address recipient, uint256 amount) public override onlyGovernance {
        _mint(recipient, amount);
    }

    function _burn(address from, uint256 amount) internal override {
        super._burn(from, amount);
        _moveDelegates(delegates[from], address(0), amount);
    }

    function _mint(address to, uint256 amount) internal override {
        require(totalSupply().add(amount) <= MAX_SUPPLY, "Token: Max Supply Exceeded");
        super._mint(to, amount);
        _moveDelegates(address(0), delegates[to], amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._transfer(from, to, amount);
        _moveDelegates(delegates[from], delegates[to], amount);
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying CAKEs (not scaled);
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    // move an amount of delegates from srcRep to dstRep
    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint256 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        uint32 blockNumber = uint32(block.number);

        // if the user has already been delegated to this block, update vote count
        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            // else write a new checkpoint with updated vote count
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function getChainId() internal pure returns (uint256 chainId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }
}