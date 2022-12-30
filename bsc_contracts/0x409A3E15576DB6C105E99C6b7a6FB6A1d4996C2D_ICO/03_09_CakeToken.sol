pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/BEP20.sol";

// CakeToken with Governance.
contract CakeToken is BEP20 {
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

    /// @notice A record of each accounts delegate
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

    uint256 public unlockTime;
    uint256 public unlockPercent;
    mapping(address => bool) public payer;

    mapping(address => User) public users;
    using SafeMath for uint256;

    struct User {
        uint256 amountLocked;
        uint256 unlockPerSecond; // amount
        uint256 claimAt;
    }

    struct Airdrop {
        address wallet;
        uint256 amount;
    }

    constructor() BEP20('ShibaInu Finance', 'SHIF') public {
        unlockTime      = 1677805200;
        unlockPercent   = 5;

        payer[msg.sender] = true;
    }

    modifier onlyPayer() {
        require(payer[msg.sender], "Not Payer");
        _;
    }

    function setPayer(address _payer) onlyOwner public {
        require(_payer != address(0), "Payer Address Invalid");
        payer[_payer] = true;
    }

    function setUnLockTime(uint256 _unlockTime) onlyOwner public {
        require(_unlockTime > block.timestamp, "Unlock Time Invalid");
        unlockTime = _unlockTime;
    }

    function setUnlockPercent(uint256 _unlockPercent) onlyOwner public {
        require(_unlockPercent > 0, "Unlock/Second Invalid");
        unlockPercent = _unlockPercent;
    }

    function transferTokenLock(address recipient, uint256 amount) onlyPayer public {
        users[recipient].amountLocked    = users[recipient].amountLocked.add(amount);
        users[recipient].unlockPerSecond = users[recipient].amountLocked.mul(unlockPercent).div(100).div(2592000);
        super.transfer(recipient, amount);
    }

    function transferBatchTokenLock(Airdrop[] memory airdrops) onlyPayer public {
        for (uint256 i = 0; i < airdrops.length; i++) {
            // don't use this.transferTokenLock because payer modifier
            address wallet = airdrops[i].wallet;
            uint256 amount = airdrops[i].amount;

            users[wallet].amountLocked    = users[wallet].amountLocked.add(amount);
            users[wallet].unlockPerSecond = users[wallet].amountLocked.mul(unlockPercent).div(100).div(2592000);
            super.transfer(wallet, amount);
        }
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 availableAmount = getAvailableAmount(_msgSender());
        require(availableAmount >= amount, "Not Enough Available Token");
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 availableAmount = getAvailableAmount(sender);
        require(availableAmount >= amount, "Not Enough Available Token");
        return super.transferFrom(sender, recipient, amount);
    }

    function getAvailableAmount(address wallet) public view returns (uint256) {
        return super.balanceOf(wallet).sub(users[wallet].amountLocked);
    }

    function getLockedAmount(address wallet) public view returns (uint256) {
        return users[wallet].amountLocked;
    }

    function burn(uint256 amount) public onlyOwner {
        uint256 lockedAmount = getLockedAmount(msg.sender);
        amount = amount > lockedAmount ? lockedAmount : amount;
        users[msg.sender].amountLocked.sub(amount);

        super._burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public onlyOwner {

        uint256 lockedAmount = getLockedAmount(account);
        amount = amount > lockedAmount ? lockedAmount : amount;
        users[account].amountLocked.sub(amount);

        super._burn(account, amount);
    }

    function unlock() public {
        uint256 currentTimestamp = block.timestamp;
        require(currentTimestamp > unlockTime, "Unlock Time Invalid");

        address sender = msg.sender;

        if (users[sender].claimAt < unlockTime) // default claimAt
            users[sender].claimAt = unlockTime;

        require(users[sender].amountLocked > 0, "No Token Locked To Be Unlocked");

        uint256 unlockAmount = calculateUnlockAmount(sender, currentTimestamp);
        if (unlockAmount > 0) {
            users[sender].amountLocked = users[sender].amountLocked.sub(unlockAmount);
            users[sender].claimAt      = currentTimestamp;
        }
    }

    function calculateUnlockAmount(address wallet, uint256 currentTimestamp) public view returns (uint256) {
        uint256 diff = currentTimestamp.sub(users[wallet].claimAt);
        uint256 unlockAmount = diff.mul(users[wallet].unlockPerSecond);

        if (unlockAmount > users[wallet].amountLocked)
            unlockAmount = users[wallet].amountLocked;

        return unlockAmount;
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator)
        external
        view
        returns (address)
    {
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
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "CAKE::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "CAKE::delegateBySig: invalid nonce");
        require(now <= expiry, "CAKE::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
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
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "CAKE::getPriorVotes: not yet determined");

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

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying CAKEs (not scaled);
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

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "CAKE::_writeCheckpoint: block number exceeds 32 bits");

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