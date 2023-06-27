// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "./ERC1155B.sol";
import "@rari-capital/solmate/src/utils/SafeCastLib.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

abstract contract ERC1155BCheckpointable is ERC1155B {
    using SafeCastLib for uint256;
    /// @notice Defines decimals as per ERC-20 convention to make integrations with 3rd party governance platforms easier
    uint8 public constant decimals = 0;
    uint96 public totalSupply;
    uint96 public constant maxSupply = type(uint96).max;

    /// delegator -> delegatee
    mapping(address => address) private _delegates;
    /// delegator -> #votes
    mapping(address => uint96) public _ballots;
    /// delegatee -> #checkpoints
    mapping(address => uint32) public numCheckpoints;
    /// delegatee -> checkpoint# -> checkpoint(fromBlock,#votes)
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @dev Event log for changing of delegate by user
    /// @param _delegator Address of delegator
    /// @param _fromDelegate Address of previous delegate
    /// @param _toDelegate Address of new delegate
    event DelegateChanged(
        address indexed _delegator,
        address indexed _fromDelegate,
        address indexed _toDelegate
    );

    /// @dev Event log for moving of delegates
    /// @param _delegate Address of the delegate
    /// @param _previousBalance Previous balance of votes
    /// @param _newBalance Updated balance of votes
    event DelegateVotesChanged(
        address indexed _delegate,
        uint256 _previousBalance,
        uint256 _newBalance
    );

    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 pos = numCheckpoints[account];
        return pos != 0 ? checkpoints[account][pos - 1].votes : 0;
    }

    function getPriorVotes(address account, uint256 blockNumber)
        public
        view
        virtual
        returns (uint256)
    {
        require(block.number > blockNumber, "UNDETERMINED");

        uint32 pos = numCheckpoints[account];
        if (pos == 0) return 0;

        if (checkpoints[account][pos - 1].fromBlock <= blockNumber)
            return checkpoints[account][pos - 1].votes;

        if (checkpoints[account][0].fromBlock > blockNumber) return 0;

        uint32 lower;
        uint32 upper = pos - 1;

        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2;
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) return cp.votes;
            cp.fromBlock < blockNumber ? lower = center : upper = center - 1;
        }

        return checkpoints[account][lower].votes;
    }

    function votesToDelegate(address delegator) public view returns (uint96) {
        return _ballots[delegator];
    }

    /**
     * @notice Overrides the standard `Comp.sol` delegates mapping to return
     * the delegator's own address if they haven't delegated.
     * This avoids having to delegate to oneself.
     */
    function delegates(address delegator) public view returns (address) {
        address current = _delegates[delegator];
        return current == address(0) ? delegator : current;
    }

    function safeTransferFrom(
        address src,
        address dst,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual override {
        _ballots[src]--;
        _ballots[dst]++;
        _moveDelegates(delegates(src), delegates(dst), amount.safeCastTo96());
        super.safeTransferFrom(src, dst, id, amount, data);
    }

    function safeBatchTransferFrom(
        address src,
        address dst,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual override {
        uint96 amount = ids.length.safeCastTo96();
        _ballots[src] -= amount;
        _ballots[dst] += amount;
        _moveDelegates(delegates(src), delegates(dst), amount);
        super.safeBatchTransferFrom(src, dst, ids, amounts, data);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual override {
        _ballots[src]--;
        _ballots[dst]++;
        _moveDelegates(delegates(src), delegates(dst), amount.safeCastTo96());
        super.transferFrom(src, dst, id, amount, data);
    }

    function batchTransferFrom(
        address src,
        address dst,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual override {
        uint96 amount = ids.length.safeCastTo96();
        _ballots[src] -= amount;
        _ballots[dst] += amount;
        _moveDelegates(delegates(src), delegates(dst), amount);
        super.batchTransferFrom(src, dst, ids, amounts, data);
    }

    function _mint(
        address dst,
        uint256 id,
        bytes memory data
    ) internal virtual override {
        totalSupply++;
        _ballots[dst]++;
        _moveDelegates(address(0), delegates(dst), 1);
        super._mint(dst, id, data);
    }

    function _batchMint(
        address dst,
        uint256[] memory ids,
        bytes memory data
    ) internal virtual override {
        uint96 amount = ids.length.safeCastTo96();
        totalSupply += amount;
        _ballots[dst] += amount;
        _moveDelegates(address(0), delegates(dst), amount);
        super._batchMint(dst, ids, data);
    }

    function _burn(uint256 id) internal virtual override {
        totalSupply--;
        _ballots[msg.sender]--;
        _moveDelegates(delegates(msg.sender), address(0), 1);
        super._burn(id);
    }

    function _batchBurn(address src, uint256[] memory ids) internal virtual override {
        uint96 amount = ids.length.safeCastTo96();
        totalSupply -= amount;
        _ballots[src] -= amount;
        _moveDelegates(delegates(src), address(0), amount);
        super._batchBurn(src, ids);
    }

    function _delegate(address delegator, address delegatee) internal {
        /// @notice differs from `_delegate()` in `Comp.sol` to use `delegates` override method to simulate auto-delegation
        address currentDelegate = delegates(delegator);
        _delegates[delegator] = delegatee;
        uint96 amount = votesToDelegate(delegator);
        _moveDelegates(currentDelegate, delegatee, amount);
        emit DelegateChanged(delegator, currentDelegate, delegatee);
    }

    function _moveDelegates(
        address src,
        address dst,
        uint96 amount
    ) internal {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                uint96 srcOld;
                uint32 srcPos = numCheckpoints[src];

                srcOld = srcPos != 0 ? checkpoints[src][srcPos - 1].votes : 0;

                uint96 srcNew = srcOld - amount;

                _writeCheckpoint(src, srcPos, srcOld, srcNew);
            }

            if (dst != address(0)) {
                uint32 dstPos = numCheckpoints[dst];
                uint96 dstOld;

                dstOld = dstPos != 0 ? checkpoints[dst][dstPos - 1].votes : 0;

                uint96 dstNew = dstOld + amount;

                _writeCheckpoint(dst, dstPos, dstOld, dstNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 pos,
        uint96 oldVotes,
        uint96 newVotes
    ) internal {
        uint32 blockNumber = block.number.safeCastTo32();
        if (pos > 0 && checkpoints[delegatee][pos - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][pos - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][pos] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = pos + 1;
        }
        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }
}