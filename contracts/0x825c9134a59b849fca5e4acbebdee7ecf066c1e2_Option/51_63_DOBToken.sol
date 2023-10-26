// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title The DOB Token
 * @author DeOrderBook
 * @custom:license Copyright (c) DeOrderBook, 2023 — All Rights Reserved
 * @notice This is the contract for $DOB, the main token of the DeOrderBook protocol
 * @dev This contract defines the $DOB token, which is the governance token for the DeOrderBook system. It is an ERC20 token with added governance features like voting and delegation.
 */
contract DOB is ERC20Upgradeable {
    using SafeMath for uint256;
    using Arrays for uint256[];
    using Counters for Counters.Counter;

    /**
     * @notice Maximum supply of tokens that can ever exist (1 billion tokens with 18 decimals)
     * @dev Change this value if you want a different maximum supply
     */
    uint256 public MAX_SUPPLY;

    /**
     * @notice Address of the current administrator
     * @dev The admin has elevated permissions to perform certain operations
     */
    address public admin;

    /**
     * @notice Address of the pending administrator
     * @dev The pending admin is a proposed new admin that will become the admin when they accept the role
     */
    address public pendingAdmin;

    /**
     * @notice Mapping of an account's address to its delegate's address
     * @dev This delegate will vote on behalf of the account in governance matters
     */
    mapping(address => address) public delegates;

    /**
     * @notice Struct for marking number of votes from a given block
     * @dev The struct contains two properties: fromBlock (block number when the checkpoint was recorded)
     * and votes (voting power)
     */
    struct Checkpoint {
        uint256 fromBlock;
        uint256 votes;
    }

    /**
     * @notice Mapping to record votes checkpoints for each account
     * @dev This nested mapping records the checkpoints for each account.
     * The outer mapping is keyed by an address, and the inner mapping is keyed by a checkpoint index.
     */
    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;

    /**
     * @notice Mapping to record the number of checkpoints for each account
     * @dev This mapping keeps track of the count of checkpoints for each address
     */
    mapping(address => uint256) public numCheckpoints;

    /**
     * @notice The EIP-712 typehash for the contract's domain
     * @dev This constant is used for generating and verifying EIP-712 typed signatures
     */
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /**
     * @notice The EIP-712 typehash for the delegation struct used by the contract
     * @dev This constant is also used for EIP-712 signatures, specifically for delegation operations
     */
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /**
     * @notice Mapping to record states for signing/validating signatures
     * @dev This mapping records a nonce for each address. A nonce is a number that is used only once
     */
    mapping(address => uint) public nonces;

    /**
     * @notice Struct to store snapshots of account balances and the total token supply at various points in time
     * @dev Each snapshot has an ID and a value (the account balance or the total supply)
     */
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    /**
     * @notice Mapping to record snapshots of account balances
     * @dev This mapping records the snapshots of account balances at various points in time
     */
    mapping(address => Snapshots) private _accountBalanceSnapshots;

    /**
     * @notice Snapshots of the total token supply
     * @dev This variable records the snapshots of total token supply at various points in time
     */
    Snapshots private _totalSupplySnapshots;

    /**
     * @notice Counter for unique IDs to snapshots
     * @dev This counter is used to assign unique IDs to snapshots
     */
    Counters.Counter private _currentSnapshotId;

    /**
     * @notice Triggered when a new snapshot is created.
     * @dev A new snapshot is created with a unique ID.
     * @param id The unique ID of the created snapshot.
     */
    event Snapshot(uint256 id);

    /**
     * @notice Logs when the delegate of a certain address changes.
     * @dev Triggered when an address changes its delegate. This can be used for off-chain tracking of delegate changes.
     * @param delegator The address which had its delegate changed.
     * @param fromDelegate The address of the previous delegate.
     * @param toDelegate The address of the new delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @notice Triggered when a delegate's vote balance changes.
     * @dev This event is emitted when a delegate's vote balance changes. It's useful for tracking the voting power of delegates.
     * @param delegate The address of the delegate.
     * @param previousBalance The delegate's previous voting balance.
     * @param newBalance The delegate's new voting balance.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @notice Triggered when the pending admin is changed.
     * @dev This event is emitted when the contract's pending admin is updated. The new pending admin must call `acceptAdmin` to take over.
     * @param oldPendingAdmin The address of the previous pending admin.
     * @param newPendingAdmin The address of the new pending admin.
     */
    event NewPendingAdmin(address indexed oldPendingAdmin, address indexed newPendingAdmin);

    /**
     * @notice Triggered when the admin of the contract is changed.
     * @dev This event is emitted when a new admin takes over the contract. This is the finalization of an admin change.
     * @param oldAdmin The address of the previous admin.
     * @param newAdmin The address of the new admin.
     */
    event NewAdmin(address indexed oldAdmin, address indexed newAdmin);

    /**
     * @notice Only the admin can call the function it is attached to
     * @dev This function modifier ensures that only the admin can call the function it is attached to
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "DOB: Caller is not a admin");
        _;
    }

    function __DOB_init(address _admin) external initializer {
        __ERC20_init("DeOrderBook", "DOB");
        admin = _admin;
        MAX_SUPPLY = 1e27;
        _mint(_admin, MAX_SUPPLY);
    }

    /**
     * @notice This function allows the current admin to set a new pending admin.
     * @dev The new pending admin will not have admin rights until they accept the role.
     * @param newPendingAdmin The address of the new pending admin.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function setPendingAdmin(address newPendingAdmin) external onlyAdmin returns (bool) {
        address oldPendingAdmin = pendingAdmin;
        pendingAdmin = newPendingAdmin;

        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

        return true;
    }

    /**
     * @notice This function allows the pending admin to accept their role and become the admin.
     * @dev If the caller of this function is not the pending admin or the zero address, it reverts.
     *      On success, it changes the admin to the pending admin and sets the pending admin to the zero address.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function acceptAdmin() external returns (bool) {
        if (msg.sender != pendingAdmin || msg.sender == address(0)) {
            revert("DOB: acceptAdmin: illegal address");
        }
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;
        admin = pendingAdmin;
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

        return true;
    }

    /**
     * @notice This function allows the admin to take a snapshot of token balances and the total supply.
     * @dev This will increment the current snapshot ID and emit a Snapshot event.
     * @return The ID of the new snapshot.
     */
    function snapshot() external virtual onlyAdmin returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _currentSnapshotId.current();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @notice This function returns the balance of an account at the time of a specific snapshot.
     * @dev If the account balance wasn't snapshotted at the given ID, this function will return the current balance of the account.
     * @param account The address of the account.
     * @param snapshotId The ID of the snapshot.
     * @return The balance of the account at the time of the snapshot.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @notice This function returns the total supply of tokens at the time of a specific snapshot.
     * @dev If the total supply wasn't snapshotted at the given ID, this function will return the current total supply.
     * @param snapshotId The ID of the snapshot.
     * @return The total supply at the time of the snapshot.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }

    /**
     * @notice This function gets called before any transfer of tokens. It updates the snapshots accordingly.
     * @dev This function overrides the _beforeTokenTransfer() function of the ERC20 contract.
     * @param from The address of the sender.
     * @param to The address of the recipient.
     * @param amount The amount of tokens being transferred.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    /**
     * @notice Retrieves the balance or total supply at a particular snapshot.
     * @dev This function finds the value of an account or total supply at a given snapshot ID.
     * - It will revert if the snapshot ID is 0 or if the snapshot ID is greater than the current snapshot ID.
     * - It first finds the upper bound of the snapshot ID in the array of snapshot IDs.
     * - If the index equals the length of the array, the function returns false and 0; otherwise, it returns true and the value of the snapshot at that index.
     * @param snapshotId The ID of the snapshot.
     * @param snapshots The snapshots structure to use for finding the value.
     * @return A boolean indicating whether the snapshot exists, and the value at the snapshot.
     */
    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _currentSnapshotId.current(), "ERC20Snapshot: nonexistent id");

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    /**
     * @notice Updates the account balance snapshot for a given account.
     * @dev Called when a change to an account's balance is made and a snapshot is required.
     * @param account The address of the account for which the snapshot will be updated.
     */
    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    /**
     * @notice Updates the total supply snapshot.
     * @dev Called when a change to the total supply is made and a snapshot is required.
     */
    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    /**
     * @notice Updates a given snapshot with the current value.
     * @dev Pushes a new snapshot id and current value to the snapshots if the last snapshot id is less than the current snapshot id.
     * @param snapshots The snapshots structure to update.
     * @param currentValue The current value to record in the snapshot.
     */
    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _currentSnapshotId.current();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    /**
     * @notice Gets the last snapshot id from an array of ids.
     * @dev If the array is empty, the function returns 0.
     * @param ids An array of snapshot ids.
     * @return The last snapshot id.
     */
    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }

    /**
     * @notice Delegates voting rights to another address.
     * @dev Assigns voting rights of the msg.sender to the `delegatee`.
     * @param delegatee The address that will receive the voter's voting rights.
     */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates voting rights to another address using a signature.
     * @dev Assigns voting rights to the `delegatee` using an EIP-712 signature.
     * @param delegatee The address that will receive the voter's voting rights.
     * @param nonce The nonce used to prevent replay attacks.
     * @param expiry The time when the signature expires.
     * @param v The recovery byte of the signature.
     * @param r Half of the ECDSA signature pair.
     * @param s Half of the ECDSA signature pair.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), getChainId(), address(this))
        );
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "DOB: delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "DOB: delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "DOB: delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes of an account.
     * @dev Returns the number of votes the account currently has.
     * @param account The account to retrieve the votes from.
     * @return The number of votes the account has.
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint256 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Retrieves the prior number of votes for an account as of a block number.
     * @dev Retrieves the checkpoint for an account at a given block number and returns the number of votes the account had at that time.
     * @param account The account to retrieve the votes from.
     * @param blockNumber The block number to retrieve the votes at.
     * @return The number of votes the account had as of the given block.
     */
    function getPriorVotes(address account, uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "DOB: getPriorVotes: not yet determined");

        uint256 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint256 lower = 0;
        uint256 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2;
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
     * @notice Internal function to delegate an account's voting rights to another address.
     * @dev Delegates voting rights from one account to another. This updates the delegation mapping and vote counts.
     * @param delegator The account that is delegating their votes.
     * @param delegatee The account that is receiving the votes.
     */
    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator);
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    /**
     * @notice Overrides the _transfer function in the ERC20 contract to also move delegated votes.
     * @dev Transfers tokens from one account to another and moves delegated votes if the delegatees are different.
     * @param sender The account sending the tokens.
     * @param recipient The account receiving the tokens.
     * @param amount The amount of tokens to send.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        super._transfer(sender, recipient, amount);
        _moveDelegates(delegates[sender], delegates[recipient], amount);
    }

    /**
     * @notice Moves votes from one delegate to another.
     * @dev If the source address and the destination address are different and the amount of tokens to transfer is greater than zero,
     *      subtract the amount of tokens from the source address's votes and add the amount of tokens to the destination address's votes.
     * @param srcRep Source address of the delegate.
     * @param dstRep Destination address of the delegate.
     * @param amount The amount of tokens to move.
     */
    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint256 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint256 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint256 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    /**
     * @notice Records a new checkpoint for an account's votes.
     * @dev Writes a new checkpoint for the delegatee's number of votes.
     * @param delegatee The account for which to record a new vote checkpoint.
     * @param nCheckpoints The current number of checkpoints for this account.
     * @param oldVotes The previous number of votes for this account.
     * @param newVotes The new number of votes for this account.
     */
    function _writeCheckpoint(
        address delegatee,
        uint256 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        uint256 blockNumber = safe32(block.number, "DOB:: _writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    /**
     * @notice Makes sure a given number can fit into 32 bits.
     * @dev Throws an error message if the given number is greater than 2^32 - 1.
     * @param n The number to check.
     * @param errorMessage The error message to use if the check fails.
     * @return The original number, if it's less than 2^32.
     */
    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint256) {
        require(n < 2**32, errorMessage);
        return uint256(n);
    }

    /**
     * @notice Returns the current chain ID.
     * @dev Fetches and returns the current chain ID using assembly code.
     * @return The current chain ID.
     */
    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}