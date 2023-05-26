// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


// SushiToken with Governance.
contract SigToken is ERC20, Ownable, ERC20Burnable {
    using SafeMath for uint256;
    //  Bitcoin-like supply system:
    //      50 tokens per block (however it's Ethereum ~15 seconds block vs Bitcoin 10 minutes)
    //      every 210,000 blocks is halving ~ 36 days 11 hours
    //      32 eras ~  3 years 71 days 16 hours until complete mint
    //      21,000,000 is total supply
    //
    //  i,e. if each block is about 15 seconds on average:
    //      40,320 blocks/week
    //      2,016,000 tokens/week before first halving
    //      10,500,000 total before first halving
    //
    uint256 constant MAX_MAIN_SUPPLY = 21_000_000 * 1e18;

    // the first week mint has x2 bonus     = +2,016,000
    // the second week mint has x1.5 bonus  = +1,008,000
    //
    uint256 constant BONUS_SUPPLY = 3_024_000 * 1e18;

    // so total max supply is 24,024,000 + 24 to init the uniswap pool
    uint256 constant MAX_TOTAL_SUPPLY = MAX_MAIN_SUPPLY + BONUS_SUPPLY;

    // The block number when SIG mining starts.
    uint256 public startBlock;

    uint256 constant DECIMALS_MUL = 1e18;
    uint256 constant BLOCKS_PER_WEEK = 40_320;
    uint256 constant HALVING_BLOCKS = 210_000;
    // uint265 constant INITIAL_BLOCK_REWARD = 50;

    function maxRewardMintAfterBlocks(uint256 t) public pure returns (uint256) {
        // the first week x2 mint
        if (t < BLOCKS_PER_WEEK) {
            return DECIMALS_MUL * 100 * t;
        }
        // second week x1.5 mint
        if (t < BLOCKS_PER_WEEK * 2) {
            return  DECIMALS_MUL * (100 * BLOCKS_PER_WEEK + 75 * (t - BLOCKS_PER_WEEK));
        }
        // after two weeks standard bitcoin issuance model https://en.bitcoin.it/wiki/Controlled_supply
        uint256 totalBonus = DECIMALS_MUL * (BLOCKS_PER_WEEK * 50 + BLOCKS_PER_WEEK * 25);
        assert(totalBonus >= 0);
        // how many halvings so far?
        uint256 era = t / HALVING_BLOCKS;
        assert(0 <= era);
        if (32 <= era) return MAX_TOTAL_SUPPLY;
        // total reward before current era (mul base reward 50)
        // sum : 1 + 1/2 + 1/4 … 1/2^n == 2 - 1/2^n == 1 - 1/1<<n == 1 - 1>>n
        // era reward per block (*1e18 *50)
        if (era == 0) {
            return totalBonus + DECIMALS_MUL* 50 * (t % HALVING_BLOCKS);
        }
        uint256 eraRewardPerBlock = (DECIMALS_MUL >> era);
        //        assert(0 <= eraRewardPerBlock);
        uint256 bcReward = (DECIMALS_MUL + DECIMALS_MUL - (eraRewardPerBlock<<1) ) * 50 * HALVING_BLOCKS;
        //        assert(0 <= bcReward);
        // reward in the last era which isn't over
        uint256 eraReward = eraRewardPerBlock * 50 * (t % HALVING_BLOCKS);
        //        assert(0 <= eraReward);
        uint256 result = totalBonus + bcReward + eraReward;
        assert(0 <= result);
        return result;
    }

    constructor(
        uint256 _tinyMint
    ) public ERC20("xSigma", "SIG") {
        // dev needs a little of  SIG tokens for uniswap SIG/ETH initialization
        _mint(msg.sender, _tinyMint);
    }



    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }

    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    /// @dev A record of each accounts delegate
    mapping (address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator) external view returns (address) {
        return _delegates[delegator];
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) external {
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
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "SIG::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "SIG::delegateBySig: invalid nonce");
        require(now <= expiry, "SIG::delegateBySig: signature expired");
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
    function getPriorVotes(address account, uint blockNumber) external view returns (uint256) {
        require(blockNumber < block.number, "SIG::getPriorVotes: not yet determined");

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
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying SIGs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
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

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
        uint32 blockNumber = safe32(block.number, "SIG::_writeCheckpoint: block number exceeds 32 bits");

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

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}