// contracts/Pool0.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../@openzeppelin/contracts-upgradeable/token/ERC777/ERC777Upgradeable.sol";
import '../@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../@openzeppelin/contracts/utils/math/SignedSafeMath.sol';

contract BaconCoin0 is Initializable, ERC777Upgradeable {
    using SignedSafeMath for int256;
    using SafeMath for uint256;

    address stakingContract;
    address airdropContract;

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of each accounts delegate
    mapping (address => address) public delegates;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    /*****************************************************
    *       EVENTS
    ******************************************************/
    
    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /*****************************************************
    *       BASE FUNCTIONS
    ******************************************************/

    /** 
    *   @dev Function initialize replaces constructor in upgradable contracts
    *   - Calls the init function of the inherited ERC777 contract
    *   @param name Name of this particular ERC777 token
    *   @param symbol The ticker this token will go by
    */
    function initialize(string memory name, string memory symbol, address _stakingContractAddress, address _airdropContractAddress) public initializer {
        stakingContract = _stakingContractAddress;
        airdropContract = _airdropContractAddress;
        address[] memory operators;
        ERC777Upgradeable.__ERC777_init(name, symbol, operators );
    }

    // Transfer func must be overwritten to also moveDelegates when balance is transferred
    function transfer(address dst, uint amount) public override returns (bool) {
        require(super.transfer(dst, amount));
        _moveDelegates(delegates[msg.sender], delegates[dst], amount);
        return true;
    }

    // TransferFrom func must be overwritten to also moveDelegates when balance is transferred
    function transferFrom(address src, address dst, uint256 amount) public override returns (bool) {
        require(super.transferFrom(src, dst, amount));
        _moveDelegates(delegates[src], delegates[dst], amount);
        return true;
    }

    function mint(address account, uint256 amount) public {
        require(msg.sender == stakingContract || msg.sender == airdropContract, "Invalid mint sender");
        super._mint(account, amount, "", "");
        _moveDelegates(address(0), account, amount);
    }

    /**  
    *   @dev Function version returns uint depending on what version the contract is on
    */
    function version() public pure returns (uint) {
        return 0;
    }
    
    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal view returns (uint) {
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly { chainId := chainid() }
        return chainId;
    }

    /********************************
    *     GOVERNANCE FUNCTIONS      *
    *********************************/

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "BaconCoin: invalid signature");
        require(nonce == nonces[signatory]++, "BaconCoin: invalid nonce");
        require(block.timestamp <= expiry, "BaconCoin: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
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
    function getPriorVotes(address account, uint blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "BaconCoin: not yet determined");

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
        uint256 delegatorBalance = balanceOf(delegator);
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "BaconCoin: block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[delegatee] = nCheckpoints + 1;
      }

      emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }
}