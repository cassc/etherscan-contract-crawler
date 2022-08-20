// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {Checkpoints} from "@openzeppelin/contracts/utils/Checkpoints.sol";
import {ECDSA, EIP712} from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

import {IGaugeVoterV2} from "./interfaces/IGaugeVoterV2.sol";
import {INFTLocker} from "./interfaces/INFTLocker.sol";
import {IRegistry, INFTStaker} from "./interfaces/INFTStaker.sol";

/**
 * This contract stakes an NFT and captures it's voting power. It is an extension
 * of openzepplin's Votes contract that also allows delegration.
 *
 * All benefits such as voting, protocol fees, rewards, special access etc.. accure
 * to NFT stakers.
 *
 * When you stake your NFT, your voting power is locked in and stops decreasing over time.
 *
 * TODO: Ensure we limit the amount of delegation power a wallet can have.
 *
 * @author Steven Enamakel <[email protected]>
 */
contract MAHAXStaker is ReentrancyGuard, AccessControl, EIP712, INFTStaker {
    using Checkpoints for Checkpoints.History;
    using Counters for Counters.Counter;

    IRegistry public immutable override registry;

    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    bytes32 public constant KICK_FROM_STAKE_ROLE =
        keccak256("KICK_FROM_STAKE_ROLE");

    mapping(address => address) private _delegation;
    mapping(address => Checkpoints.History) private _delegateCheckpoints;
    Checkpoints.History private _totalCheckpoints;

    mapping(address => Counters.Counter) private _nonces;

    uint256 public totalWeight; // total voting weight
    bool public disableAttachmentCheck; // check attachments when unstaking

    mapping(uint256 => uint256) public stakedBalancesNFT; // nft => pool => votes
    mapping(address => uint256) public stakedBalances; // nft => pool => votes

    constructor(address _registry, address _governance)
        EIP712("MAHAXStaker", "1")
    {
        registry = IRegistry(_registry);
        _setupRole(DEFAULT_ADMIN_ROLE, _governance);
    }

    function stake(uint256 _tokenId) external override {
        INFTLocker locker = INFTLocker(registry.locker());
        require(
            locker.isApprovedOrOwner(msg.sender, _tokenId),
            "not token owner"
        );
        _stake(_tokenId);
    }

    function unstake(uint256 _tokenId) external override {
        INFTLocker locker = INFTLocker(registry.locker());

        // check if the nfts have been used in a gauge
        if (!disableAttachmentCheck) {
            IGaugeVoterV2 gaugeVoter = IGaugeVoterV2(registry.gaugeVoter());
            require(
                gaugeVoter.attachments(locker.ownerOf(_tokenId)) == 0,
                "attached"
            );
        }

        require(
            locker.isApprovedOrOwner(msg.sender, _tokenId),
            "not token owner"
        );
        _unstake(_tokenId);
    }

    function _stakeFromLock(uint256 _tokenId) external override {
        require(msg.sender == registry.locker(), "not locker");
        if (!_isStaked(_tokenId)) _stake(_tokenId);
        else {
            _unstake(_tokenId);
            _stake(_tokenId);
        }
    }

    function _stake(uint256 _tokenId) internal {
        registry.ensureNotPaused();

        INFTLocker locker = INFTLocker(registry.locker());
        require(stakedBalancesNFT[_tokenId] == 0, "already staked");

        address _owner = locker.ownerOf(_tokenId);

        uint256 _weight = locker.balanceOfNFT(_tokenId);
        _transferVotingUnits(address(0), _owner, _weight);

        stakedBalancesNFT[_tokenId] = _weight;
        stakedBalances[_owner] += _weight;
        totalWeight += _weight;

        emit StakeNFT(msg.sender, _owner, _tokenId, _weight);

        // if the user is staking for the first time; set the delegate to himself by default.
        if (_delegation[_owner] == address(0)) _delegate(_owner, _owner);
    }

    function _unstake(uint256 _tokenId) internal {
        INFTLocker locker = INFTLocker(registry.locker());
        address _owner = locker.ownerOf(_tokenId);

        require(stakedBalancesNFT[_tokenId] > 0, "not staked");
        IGaugeVoterV2(registry.gaugeVoter()).resetFor(_owner);

        uint256 _weight = stakedBalancesNFT[_tokenId];
        _transferVotingUnits(_owner, address(0), _weight);

        stakedBalancesNFT[_tokenId] = 0;
        stakedBalances[_owner] -= _weight;
        totalWeight -= _weight;

        emit UnstakeNFT(msg.sender, _owner, _tokenId, _weight);
    }

    /// @dev ban a NFT from stake; ideally should be used with NFTs that are staked but listed on opensea.
    /// Should be called from a smart contract
    function banFromStake(uint256 _tokenId) external {
        _checkRole(KICK_FROM_STAKE_ROLE, msg.sender);
        _unstake(_tokenId);
    }

    /// @dev in the unlikely event of some kind of issue with the gauge voter, we
    /// disable the attachment check so that NFTs can safely by unstaked.
    function toggleAttachmentCheck() external {
        _checkRole(DEFAULT_ADMIN_ROLE, msg.sender);
        disableAttachmentCheck = !disableAttachmentCheck;
    }

    function _getVotingUnits(address who)
        internal
        view
        virtual
        returns (uint256)
    {
        return stakedBalances[who];
    }

    function getStakedBalance(address who)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return stakedBalances[who];
    }

    function balanceOf(address who)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _delegateCheckpoints[who].latest();
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _getTotalSupply();
    }

    function isStaked(uint256 tokenId)
        external
        view
        virtual
        override
        returns (bool)
    {
        return _isStaked(tokenId);
    }

    function _isStaked(uint256 tokenId) internal view virtual returns (bool) {
        return stakedBalancesNFT[tokenId] > 0;
    }

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _delegateCheckpoints[account].latest();
    }

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(address account, uint256 blockNumber)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _delegateCheckpoints[account].getAtBlock(blockNumber);
    }

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(blockNumber < block.number, "Votes: block not yet mined");
        return _totalCheckpoints.getAtBlock(blockNumber);
    }

    /**
     * @dev Returns the current total supply of votes.
     */
    function _getTotalSupply() internal view virtual returns (uint256) {
        return _totalCheckpoints.latest();
    }

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account)
        public
        view
        virtual
        override
        returns (address)
    {
        return _delegation[account];
    }

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public virtual override {
        address account = _msgSender();
        _delegate(account, delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= expiry, "Votes: signature expired");
        address signer = ECDSA.recover(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry)
                )
            ),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), "Votes: invalid nonce");
        _delegate(signer, delegatee);
    }

    /**
     * @dev Delegate all of `account`'s voting units to `delegatee`.
     *
     * Emits events {DelegateChanged} and {DelegateVotesChanged}.
     */
    function _delegate(address account, address delegatee) internal virtual {
        address oldDelegate = delegates(account);
        _delegation[account] = delegatee;

        emit DelegateChanged(account, oldDelegate, delegatee);
        _moveDelegateVotes(oldDelegate, delegatee, _getVotingUnits(account));
    }

    /**
     * @dev Transfers, mints, or burns voting units. To register a mint, `from` should be zero. To register a burn, `to`
     * should be zero. Total supply of voting units will be adjusted with mints and burns.
     */
    function _transferVotingUnits(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (from == address(0)) _totalCheckpoints.push(_add, amount);
        if (to == address(0)) _totalCheckpoints.push(_subtract, amount);

        _moveDelegateVotes(delegates(from), delegates(to), amount);
    }

    /**
     * @dev Moves delegated votes from one delegate to another.
     */
    function _moveDelegateVotes(
        address from,
        address to,
        uint256 amount
    ) private {
        if (from != to && amount > 0) {
            if (from != address(0)) {
                (uint256 oldValue, uint256 newValue) = _delegateCheckpoints[
                    from
                ].push(_subtract, amount);
                emit DelegateVotesChanged(from, oldValue, newValue);
            }
            if (to != address(0)) {
                (uint256 oldValue, uint256 newValue) = _delegateCheckpoints[to]
                    .push(_add, amount);
                emit DelegateVotesChanged(to, oldValue, newValue);
            }
            emit Transfer(from, to, amount);
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Consumes a nonce.
     *
     * Returns the current value and increments nonce.
     */
    function _useNonce(address owner)
        internal
        virtual
        returns (uint256 current)
    {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }

    /**
     * @dev Returns an address nonce.
     */
    function nonces(address owner) public view virtual returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev Returns the contract's {EIP712} domain separator.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function name() external view virtual override returns (string memory) {
        return "MAHAX Staked Voting Power";
    }

    function symbol() external view virtual override returns (string memory) {
        return "MAHAXvp";
    }

    function decimals() external view virtual override returns (uint8) {
        return 18;
    }
}