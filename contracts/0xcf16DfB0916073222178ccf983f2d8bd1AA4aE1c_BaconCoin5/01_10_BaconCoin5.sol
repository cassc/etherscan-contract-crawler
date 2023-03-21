// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./../ERC20/ERC20UpgradeableFromERC777.sol";
import '../@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../@openzeppelin/contracts/utils/math/SignedSafeMath.sol';

contract BaconCoin5 is Initializable, ERC20UpgradeableFromERC777 {
    using SignedSafeMath for int256;
    using SafeMath for uint256;

    address stakingContract;
    address airdropContract;

    /// @notice DEPRECATED  
    /// A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice DEPRECATED  
    /// The number of checkpoints for each account
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
    *       Variables added in BaconCoin1
    ******************************************************/

    /// @notice A record of votes checkpoints for a delegate's account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public delegateCheckpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numDelegateCheckpoints;

    /*****************************************************
    *       Variables added in BaconCoin4
    ******************************************************/

    bool private _paused;

    /*****************************************************
    *       Variables added in BaconCoin5
    ******************************************************/

    address private guardian;


    /*****************************************************
    *       EVENTS
    ******************************************************/
    
    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    // @notice Emitted when the pause is triggered by `account`.
    event Paused(address account);

    // @notice Emitted when the unpause is triggered by `account`.
    event Unpaused(address account);


    /*****************************************************
    *       Pausing FUNCTIONS
    ******************************************************/

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() public whenNotPaused {
        require(isGuardian(), "invalid pause sender");
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() public whenPaused {
        require(isGuardian(), "invalid unpause sender");
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /*****************************************************
    *       BASE FUNCTIONS
    ******************************************************/

    function setGuardian(address newGuardian) public {
        // Awfulness required to make the upgrade work. Will remove if/when BaconCoin6.
        require((
            (guardian == address(0) && msg.sender == 0xa42f6FB68607048dDe54FCd53D2195cc8ca5F486 && block.chainid == 1   ) ||
            (guardian == address(0) && msg.sender == 0xa7BB7afD67baFaf80DE3fAbE9D655d87e484AcEf && block.chainid == 5   ) ||
            (guardian == address(0) && msg.sender == 0xa3E73ae94fdbE8e92bf9078E9b4427cA7a520ea4 && block.chainid == 1337) ||
            isGuardian()
        ), "Invalid sender");
        guardian = newGuardian;
    }

    function isGuardian() internal view returns (bool){
        return (guardian != address(0)) && msg.sender == guardian;
    }

    // Transfer func must be overwritten to also moveDelegates when balance is transferred
    function transfer(address dst, uint amount) public override whenNotPaused returns (bool)  {
        require(super.transfer(dst, amount));
        _moveDelegates(delegates[msg.sender], delegates[dst], amount);
        return true;
    }

    // TransferFrom func must be overwritten to also moveDelegates when balance is transferred
    function transferFrom(address src, address dst, uint256 amount) public override whenNotPaused returns (bool) {
        require(super.transferFrom(src, dst, amount));
        _moveDelegates(delegates[src], delegates[dst], amount);
        return true;
    }

    function mint(address account, uint256 amount) public whenNotPaused {
        require(msg.sender == stakingContract || msg.sender == airdropContract, "Invalid mint sender");
        super._mint(account, amount);
        _moveDelegates(address(0), delegates[account], amount);
    }

    function burn(uint256 amount, bytes memory data) public whenNotPaused {
        super._burn(msg.sender, amount);
        _moveDelegates(delegates[msg.sender], address(0), amount);
    }

    function ownerBurn(uint256 amount, address user) public {
        require(isGuardian(), "invalid sender");
        super._burn(user, amount);
        _moveDelegates(delegates[user], address(0), amount);
    }

    /**  
    *   @dev Function version returns uint depending on what version the contract is on
    */
    function version() public pure returns (uint) {
        return 5;
    }
    
    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
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
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), block.chainid, address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "BaconCoin: invalid signature");
        require(nonce == nonces[signatory]++, "BaconCoin: invalid nonce");
        require(block.timestamp <= expiry, "BaconCoin: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint32 nCheckpoints = numDelegateCheckpoints[account];
        return nCheckpoints > 0 ? delegateCheckpoints[account][nCheckpoints - 1].votes : 0;
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

        uint32 nCheckpoints = numDelegateCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (delegateCheckpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return delegateCheckpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (delegateCheckpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = delegateCheckpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return delegateCheckpoints[account][lower].votes;
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
                uint32 srcRepNum = numDelegateCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? delegateCheckpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numDelegateCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? delegateCheckpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "BaconCoin: block number exceeds 32 bits");

      if (nCheckpoints > 0 && delegateCheckpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          delegateCheckpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          delegateCheckpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numDelegateCheckpoints[delegatee] = nCheckpoints + 1;
      }

      emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }
}