// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.7;

import {ERC20} from "erc20/ERC20.sol";
import {RevenueDistributionToken} from "revenue-distribution-token/RevenueDistributionToken.sol";
import {LockedRevenueDistributionToken} from "./LockedRevenueDistributionToken.sol";
import {IGovernanceLockedRevenueDistributionToken} from "./interfaces/IGovernanceLockedRevenueDistributionToken.sol";
import {Math} from "./libraries/Math.sol";

/*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░██████╗░██╗░░░░░██████╗░██████╗░████████╗░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░██╔════╝░██║░░░░░██╔══██╗██╔══██╗╚══██╔══╝░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░██║░░██╗░██║░░░░░██████╔╝██║░░██║░░░██║░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░██║░░╚██╗██║░░░░░██╔══██╗██║░░██║░░░██║░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░╚██████╔╝███████╗██║░░██║██████╔╝░░░██║░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░╚═════╝░╚══════╝╚═╝░░╚═╝╚═════╝░░░░╚═╝░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░                                                                       ░░░░
░░░░            Governance Locked Revenue Distribution Token               ░░░░
░░░░                                                                       ░░░░
░░░░  Extending LockedRevenueDistributionToken with Compound governance,   ░░░░
░░░░  using OpenZeppelin's ERC20VotesComp implementation.                  ░░░░
░░░░                                                                       ░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

/**
 * @title  ERC-4626 revenue distribution vault with locking and Compound-compatible governance.
 * @notice Tokens are locked and must be subject to time-based or fee-based withdrawal conditions.
 * @dev    Voting power applies to the the total asset balance, including assets reserved for withdrawal.
 * @dev    Limited to a maximum asset supply of uint96.
 * @author GET Protocol DAO
 * @author Uses Maple's RevenueDistributionToken v1.0.1 under AGPL-3.0 (https://github.com/maple-labs/revenue-distribution-token/tree/v1.0.1)
 * @author Uses OpenZeppelin's ERC20Votes and ERC20VotesComp v4.8.0-rc.1 under MIT (https://github.com/OpenZeppelin/openzeppelin-contracts/tree/v4.8.0-rc.1/)
 */
contract GovernanceLockedRevenueDistributionToken is
    IGovernanceLockedRevenueDistributionToken,
    LockedRevenueDistributionToken
{
    // DELEGATE_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");
    bytes32 private constant DELEGATE_TYPEHASH = 0xe48329057bfd03d55e49b547132e39cffd9c1820ad7b9d4c5307691425d15adf;

    mapping(address => address) public delegates;
    mapping(address => Checkpoint[]) public override userCheckpoints;
    Checkpoint[] private totalSupplyCheckpoints;

    constructor(
        string memory name_,
        string memory symbol_,
        address owner_,
        address asset_,
        uint256 precision_,
        uint256 instantWithdrawalFee_,
        uint256 lockTime_,
        uint256 initialSeed_
    )
        LockedRevenueDistributionToken(
            name_,
            symbol_,
            owner_,
            asset_,
            precision_,
            instantWithdrawalFee_,
            lockTime_,
            initialSeed_
        )
    {}

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                         Public Functions                          ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @inheritdoc IGovernanceLockedRevenueDistributionToken
     */
    function delegate(address delegatee_) external virtual override {
        _delegate(msg.sender, delegatee_);
    }

    /**
     * @inheritdoc IGovernanceLockedRevenueDistributionToken
     * @dev Equivalent to the OpenZeppelin implementation but written in style of ERC20.permit.
     */
    function delegateBySig(address delegatee_, uint256 nonce_, uint256 deadline_, uint8 v_, bytes32 r_, bytes32 s_)
        public
        virtual
        override
    {
        require(deadline_ >= block.timestamp, "GLRDT:DBS:EXPIRED");

        // Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}.
        require(
            uint256(s_) <= uint256(0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0)
                && (v_ == 27 || v_ == 28),
            "GLRDT:DBS:MALLEABLE"
        );

        bytes32 digest_ = keccak256(
            abi.encodePacked(
                "\x19\x01", DOMAIN_SEPARATOR(), keccak256(abi.encode(DELEGATE_TYPEHASH, delegatee_, nonce_, deadline_))
            )
        );

        address recoveredAddress_ = ecrecover(digest_, v_, r_, s_);

        require(recoveredAddress_ != address(0), "GLRDT:DBS:INVALID_SIGNATURE");

        // Nonce realistically cannot overflow.
        unchecked {
            require(nonce_ == nonces[recoveredAddress_]++, "GLRDT:DBS:INVALID_NONCE");
        }

        _delegate(recoveredAddress_, delegatee_);
    }

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                          View Functions                           ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @inheritdoc IGovernanceLockedRevenueDistributionToken
     */
    function convertToAssets(uint256 shares_, uint256 blockNumber_)
        public
        view
        virtual
        override
        returns (uint256 assets_)
    {
        (uint256 totalSupply_, uint256 totalAssets_) = _checkpointsLookup(totalSupplyCheckpoints, blockNumber_);
        assets_ = totalSupply_ == 0 ? shares_ : (shares_ * totalAssets_) / totalSupply_;
    }

    /**
     * @inheritdoc IGovernanceLockedRevenueDistributionToken
     */
    function checkpoints(address account_, uint32 pos_)
        external
        view
        virtual
        override
        returns (uint32 fromBlock_, uint96 votes_)
    {
        Checkpoint memory checkpoint_ = userCheckpoints[account_][pos_];
        fromBlock_ = checkpoint_.fromBlock;
        votes_ = checkpoint_.assets;
    }

    /**
     * @inheritdoc IGovernanceLockedRevenueDistributionToken
     */
    function numCheckpoints(address account_) public view virtual override returns (uint32 numCheckpoints_) {
        numCheckpoints_ = _toUint32(userCheckpoints[account_].length);
    }

    /**
     * @inheritdoc IGovernanceLockedRevenueDistributionToken
     */
    function getVotes(address account_) public view virtual override returns (uint256 votes_) {
        uint256 pos_ = userCheckpoints[account_].length;
        if (pos_ == 0) {
            return 0;
        }
        uint256 shares_ = userCheckpoints[account_][pos_ - 1].shares;
        votes_ = convertToAssets(shares_, block.number);
    }

    /**
     * @inheritdoc IGovernanceLockedRevenueDistributionToken
     */
    function getCurrentVotes(address account_) external view virtual override returns (uint96 votes_) {
        votes_ = _toUint96(getVotes(account_));
    }

    /**
     * @inheritdoc IGovernanceLockedRevenueDistributionToken
     */
    function getPastVotes(address account_, uint256 blockNumber_)
        public
        view
        virtual
        override
        returns (uint256 votes_)
    {
        require(blockNumber_ < block.number, "GLRDT:BLOCK_NOT_MINED");
        (uint256 shares_,) = _checkpointsLookup(userCheckpoints[account_], blockNumber_);
        votes_ = convertToAssets(shares_, blockNumber_);
    }

    /**
     * @inheritdoc IGovernanceLockedRevenueDistributionToken
     */

    function getPriorVotes(address account_, uint256 blockNumber_)
        external
        view
        virtual
        override
        returns (uint96 votes_)
    {
        votes_ = _toUint96(getPastVotes(account_, blockNumber_));
    }

    /**
     * @inheritdoc IGovernanceLockedRevenueDistributionToken
     */
    function getPastTotalSupply(uint256 blockNumber_) external view virtual override returns (uint256 totalSupply_) {
        require(blockNumber_ < block.number, "GLRDT:BLOCK_NOT_MINED");
        (totalSupply_,) = _checkpointsLookup(totalSupplyCheckpoints, blockNumber_);
    }

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                        Internal Functions                         ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @inheritdoc RevenueDistributionToken
     * @dev Snapshots the totalSupply after it has been increased.
     */
    function _mint(uint256 shares_, uint256 assets_, address receiver_, address caller_) internal virtual override {
        super._mint(shares_, assets_, receiver_, caller_);
        _moveVotingPower(address(0), delegates[receiver_], shares_);
        _writeCheckpoint(totalSupplyCheckpoints, _add, shares_);
    }

    /**
     * @inheritdoc RevenueDistributionToken
     * @dev Snapshots the totalSupply after it has been decreased.
     */
    function _burn(uint256 shares_, uint256 assets_, address receiver_, address owner_, address caller_)
        internal
        virtual
        override
    {
        super._burn(shares_, assets_, receiver_, owner_, caller_);
        _moveVotingPower(delegates[owner_], address(0), shares_);
        _writeCheckpoint(totalSupplyCheckpoints, _subtract, shares_);
    }

    /**
     * @inheritdoc ERC20
     * @dev Move voting power on transfer.
     */
    function _transfer(address owner_, address recipient_, uint256 amount_) internal virtual override {
        super._transfer(owner_, recipient_, amount_);
        _moveVotingPower(delegates[owner_], delegates[recipient_], amount_);
    }

    /**
     * @notice Change delegation for delegator to delegatee.
     * @param  delegator_ Account to transfer delegate balance from.
     * @param  delegatee_ Account to transfer delegate balance to.
     */
    function _delegate(address delegator_, address delegatee_) internal virtual {
        address currentDelegate_ = delegates[delegator_];
        uint256 delegatorBalance_ = balanceOf[delegator_];
        delegates[delegator_] = delegatee_;

        emit DelegateChanged(delegator_, currentDelegate_, delegatee_);

        _moveVotingPower(currentDelegate_, delegatee_, delegatorBalance_);
    }

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                         Private Functions                         ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @notice Lookup a value in a list of (sorted) checkpoints.
     * @param  ckpts        List of checkpoints to find within.
     * @param  blockNumber_ Block number of latest checkpoint.
     * @param  shares_      Amount of shares at checkpoint.
     * @param  assets_      Amount of assets at checkpoint.
     */
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber_)
        private
        view
        returns (uint96 shares_, uint96 assets_)
    {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber_`.
        //
        // Initially we check if the block is recent to narrow the search range.
        // During the loop, the index of the wanted checkpoint remains in the range [low_-1, high_).
        // With each iteration, either `low_` or `high_` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber_`, we look in [low_, mid_)
        // - If the middle checkpoint is before or equal to `blockNumber_`, we look in [mid_+1, high_)
        // Once we reach a single value (when low_ == high_), we've found the right checkpoint at the index high_-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber_`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber_`, but it works out
        // the same.
        uint256 length_ = ckpts.length;

        uint256 low_ = 0;
        uint256 high_ = length_;

        if (length_ > 5) {
            uint256 mid_ = length_ - Math.sqrt(length_);
            if (_unsafeAccess(ckpts, mid_).fromBlock > blockNumber_) {
                high_ = mid_;
            } else {
                low_ = mid_ + 1;
            }
        }

        while (low_ < high_) {
            uint256 mid_ = Math.average(low_, high_);
            if (_unsafeAccess(ckpts, mid_).fromBlock > blockNumber_) {
                high_ = mid_;
            } else {
                low_ = mid_ + 1;
            }
        }

        if (high_ == 0) {
            return (0, 0);
        }

        Checkpoint memory checkpoint_ = _unsafeAccess(ckpts, high_ - 1);
        return (checkpoint_.shares, checkpoint_.assets);
    }

    /**
     * @notice Move voting power from one account to another.
     * @param  src_    Source account to withdraw voting power from.
     * @param  dst_    Destination account to deposit voting power to.
     * @param  amount_ Ammont of voring power to move, measured in shares.
     */
    function _moveVotingPower(address src_, address dst_, uint256 amount_) private {
        if (src_ != dst_ && amount_ > 0) {
            if (src_ != address(0)) {
                (uint256 oldWeight_, uint256 newWeight_) = _writeCheckpoint(userCheckpoints[src_], _subtract, amount_);
                emit DelegateVotesChanged(src_, oldWeight_, newWeight_);
            }

            if (dst_ != address(0)) {
                (uint256 oldWeight_, uint256 newWeight_) = _writeCheckpoint(userCheckpoints[dst_], _add, amount_);
                emit DelegateVotesChanged(dst_, oldWeight_, newWeight_);
            }
        }
    }

    /**
     * @notice Compute and store a checkpoint within a Checkpoints array. Delta applied to share balance.
     * @param  ckpts      List of checkpoints to add to.
     * @param  op_        Function reference of mathematical operation to apply to delta. Either add or subtract.
     * @param  delta_     Delta between previous checkpoint's shares and new checkpoint's shares.
     * @return oldWeight_ Previous share balance.
     * @return newWeight_ New share balance.
     */
    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op_,
        uint256 delta_
    ) private returns (uint256 oldWeight_, uint256 newWeight_) {
        uint256 pos_ = ckpts.length;

        Checkpoint memory oldCkpt_ = pos_ == 0 ? Checkpoint(0, 0, 0) : _unsafeAccess(ckpts, pos_ - 1);

        oldWeight_ = oldCkpt_.shares;
        newWeight_ = op_(oldWeight_, delta_);

        if (pos_ > 0 && oldCkpt_.fromBlock == block.number) {
            _unsafeAccess(ckpts, pos_ - 1).shares = _toUint96(newWeight_);
            _unsafeAccess(ckpts, pos_ - 1).assets = _toUint96(convertToAssets(newWeight_));
        } else {
            ckpts.push(
                Checkpoint({
                    fromBlock: _toUint32(block.number),
                    shares: _toUint96(newWeight_),
                    assets: _toUint96(convertToAssets(newWeight_))
                })
            );
        }
    }

    /**
     * @notice Computes the sum of two numbers.
     * @param  a_      First number.
     * @param  b_      Second number.
     * @return result_ Sum of first and second numbers.
     */
    function _add(uint256 a_, uint256 b_) private pure returns (uint256 result_) {
        return a_ + b_;
    }

    /**
     * @notice Subtracts the second number from the first.
     * @param  a_      First number.
     * @param  b_      Second number.
     * @return result_ Result of first number minus second number.
     */
    function _subtract(uint256 a_, uint256 b_) private pure returns (uint256 result_) {
        return a_ - b_;
    }
    /**
     * @notice Returns the downcasted uint32 from uint256, reverting on overflow (when the input is greater than
     * largest uint32). Counterpart to Solidity's `uint32` operator.
     * @param  value_ Input value to cast.
     */

    function _toUint32(uint256 value_) private pure returns (uint32) {
        require(value_ <= type(uint32).max, "GLRDT:CAST_EXCEEDS_32_BITS");
        return uint32(value_);
    }

    /**
     * @notice Returns the downcasted uint96 from uint256, reverting on overflow (when the input is greater than
     * largest uint96). Counterpart to Solidity's `uint96` operator.
     * @param  value_ Input value to cast.
     */
    function _toUint96(uint256 value_) private pure returns (uint96) {
        require(value_ <= type(uint96).max, "GLRDT:CAST_EXCEEDS_96_BITS");
        return uint96(value_);
    }

    /**
     * @notice Optimize accessing checkpoints from storage.
     * @dev    Added to OpenZeppelin v4.8.0-rc.0 (https://github.com/OpenZeppelin/openzeppelin-contracts/pull/3673)
     * @param  ckpts  Checkpoints array in storage to access.
     * @param  pos_   Index/position of the checkpoint.
     * @return result Checkpoint found at position in array.
     */
    function _unsafeAccess(Checkpoint[] storage ckpts, uint256 pos_) private pure returns (Checkpoint storage result) {
        assembly {
            mstore(0, ckpts.slot)
            result.slot := add(keccak256(0, 0x20), pos_)
        }
    }
}