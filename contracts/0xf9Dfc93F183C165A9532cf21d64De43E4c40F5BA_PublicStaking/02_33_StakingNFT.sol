// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "contracts/libraries/governance/GovernanceMaxLock.sol";
import "contracts/libraries/StakingNFT/StakingNFTStorage.sol";
import "contracts/utils/ImmutableAuth.sol";
import "contracts/utils/EthSafeTransfer.sol";
import "contracts/utils/ERC20SafeTransfer.sol";
import "contracts/utils/MagicValue.sol";
import "contracts/utils/CircuitBreaker.sol";
import "contracts/utils/AtomicCounter.sol";
import "contracts/interfaces/ICBOpener.sol";
import "contracts/interfaces/IStakingNFT.sol";
import "contracts/interfaces/IStakingNFTDescriptor.sol";
import "contracts/libraries/errors/StakingNFTErrors.sol";
import "contracts/libraries/errors/CircuitBreakerErrors.sol";

abstract contract StakingNFT is
    Initializable,
    ERC721EnumerableUpgradeable,
    CircuitBreaker,
    AtomicCounter,
    StakingNFTStorage,
    MagicValue,
    EthSafeTransfer,
    ERC20SafeTransfer,
    GovernanceMaxLock,
    ICBOpener,
    IStakingNFT,
    ImmutableFactory,
    ImmutableValidatorPool,
    ImmutableAToken,
    ImmutableGovernance,
    ImmutableStakingPositionDescriptor
{
    modifier onlyIfTokenExists(uint256 tokenID_) {
        if (!_exists(tokenID_)) {
            revert StakingNFTErrors.InvalidTokenId(tokenID_);
        }
        _;
    }

    constructor()
        ImmutableFactory(msg.sender)
        ImmutableAToken()
        ImmutableGovernance()
        ImmutableValidatorPool()
        ImmutableStakingPositionDescriptor()
    {}

    /// @dev tripCB opens the circuit breaker may only be called by _factory owner
    function tripCB() public override onlyFactory {
        _tripCB();
    }

    /// skimExcessEth will send to the address passed as to_ any amount of Eth
    /// held by this contract that is not tracked by the Accumulator system. This
    /// function allows the Admin role to refund any Eth sent to this contract in
    /// error by a user. This method can not return any funds sent to the contract
    /// via the depositEth method. This function should only be necessary if a
    /// user somehow manages to accidentally selfDestruct a contract with this
    /// contract as the recipient.
    function skimExcessEth(address to_) public onlyFactory returns (uint256 excess) {
        excess = _estimateExcessEth();
        _safeTransferEth(to_, excess);
        return excess;
    }

    /// skimExcessToken will send to the address passed as to_ any amount of
    /// AToken held by this contract that is not tracked by the Accumulator
    /// system. This function allows the Admin role to refund any AToken sent to
    /// this contract in error by a user. This method can not return any funds
    /// sent to the contract via the depositToken method.
    function skimExcessToken(address to_) public onlyFactory returns (uint256 excess) {
        IERC20Transferable aToken;
        (aToken, excess) = _estimateExcessToken();
        _safeTransferERC20(aToken, to_, excess);
        return excess;
    }

    /// lockPosition is called by governance system when a governance
    /// vote is cast. This function will lock the specified Position for up to
    /// _MAX_GOVERNANCE_LOCK. This method may only be called by the governance
    /// contract. This function will fail if the circuit breaker is tripped
    function lockPosition(
        address caller_,
        uint256 tokenID_,
        uint256 lockDuration_
    ) public override withCircuitBreaker onlyGovernance returns (uint256) {
        if (caller_ != ownerOf(tokenID_)) {
            revert StakingNFTErrors.CallerNotTokenOwner(msg.sender);
        }
        if (lockDuration_ > _MAX_GOVERNANCE_LOCK) {
            revert StakingNFTErrors.LockDurationGreaterThanGovernanceLock();
        }
        return _lockPosition(tokenID_, lockDuration_);
    }

    /// This function will lock an owned Position for up to _MAX_GOVERNANCE_LOCK. This method may
    /// only be called by the owner of the Position. This function will fail if the circuit breaker
    /// is tripped
    function lockOwnPosition(uint256 tokenID_, uint256 lockDuration_)
        public
        withCircuitBreaker
        returns (uint256)
    {
        if (msg.sender != ownerOf(tokenID_)) {
            revert StakingNFTErrors.CallerNotTokenOwner(msg.sender);
        }
        if (lockDuration_ > _MAX_GOVERNANCE_LOCK) {
            revert StakingNFTErrors.LockDurationGreaterThanGovernanceLock();
        }
        return _lockPosition(tokenID_, lockDuration_);
    }

    /// This function will lock withdraws on the specified Position for up to
    /// _MAX_GOVERNANCE_LOCK. This function will fail if the circuit breaker is tripped
    function lockWithdraw(uint256 tokenID_, uint256 lockDuration_)
        public
        withCircuitBreaker
        returns (uint256)
    {
        if (msg.sender != ownerOf(tokenID_)) {
            revert StakingNFTErrors.CallerNotTokenOwner(msg.sender);
        }
        if (lockDuration_ > _MAX_GOVERNANCE_LOCK) {
            revert StakingNFTErrors.LockDurationGreaterThanGovernanceLock();
        }
        return _lockWithdraw(tokenID_, lockDuration_);
    }

    /// DO NOT CALL THIS METHOD UNLESS YOU ARE MAKING A DISTRIBUTION AS ALL VALUE
    /// WILL BE DISTRIBUTED TO STAKERS EVENLY. depositToken distributes AToken
    /// to all stakers evenly should only be called during a slashing event. Any
    /// AToken sent to this method in error will be lost. This function will
    /// fail if the circuit breaker is tripped. The magic_ parameter is intended
    /// to stop some one from successfully interacting with this method without
    /// first reading the source code and hopefully this comment
    function depositToken(uint8 magic_, uint256 amount_)
        public
        withCircuitBreaker
        checkMagic(magic_)
    {
        // collect tokens
        _safeTransferFromERC20(IERC20Transferable(_aTokenAddress()), msg.sender, amount_);
        // update state
        _tokenState = _deposit(amount_, _tokenState);
        _reserveToken += amount_;
    }

    /// DO NOT CALL THIS METHOD UNLESS YOU ARE MAKING A DISTRIBUTION ALL VALUE
    /// WILL BE DISTRIBUTED TO STAKERS EVENLY depositEth distributes Eth to all
    /// stakers evenly should only be called by BTokens contract any Eth sent to
    /// this method in error will be lost this function will fail if the circuit
    /// breaker is tripped the magic_ parameter is intended to stop some one from
    /// successfully interacting with this method without first reading the
    /// source code and hopefully this comment
    function depositEth(uint8 magic_) public payable withCircuitBreaker checkMagic(magic_) {
        _ethState = _deposit(msg.value, _ethState);
        _reserveEth += msg.value;
    }

    /// mint allows a staking position to be opened. This function
    /// requires the caller to have performed an approve invocation against
    /// AToken into this contract. This function will fail if the circuit
    /// breaker is tripped.
    function mint(uint256 amount_) public virtual withCircuitBreaker returns (uint256 tokenID) {
        return _mintNFT(msg.sender, amount_);
    }

    /// mintTo allows a staking position to be opened in the name of an
    /// account other than the caller. This method also allows a lock to be
    /// placed on the position up to _MAX_MINT_LOCK . This function requires the
    /// caller to have performed an approve invocation against AToken into
    /// this contract. This function will fail if the circuit breaker is
    /// tripped.
    function mintTo(
        address to_,
        uint256 amount_,
        uint256 lockDuration_
    ) public virtual withCircuitBreaker returns (uint256 tokenID) {
        if (lockDuration_ > _MAX_MINT_LOCK) {
            revert StakingNFTErrors.LockDurationGreaterThanMintLock();
        }
        tokenID = _mintNFT(to_, amount_);
        if (lockDuration_ > 0) {
            _lockPosition(tokenID, lockDuration_);
        }
        return tokenID;
    }

    /// burn exits a staking position such that all accumulated value is
    /// transferred to the owner on burn.
    function burn(uint256 tokenID_)
        public
        virtual
        returns (uint256 payoutEth, uint256 payoutAToken)
    {
        return _burn(msg.sender, msg.sender, tokenID_);
    }

    /// burnTo exits a staking position such that all accumulated value
    /// is transferred to a specified account on burn
    function burnTo(address to_, uint256 tokenID_)
        public
        virtual
        returns (uint256 payoutEth, uint256 payoutAToken)
    {
        return _burn(msg.sender, to_, tokenID_);
    }

    /// collects the ether yield of a given position. The caller of this function
    /// must be the owner of the tokenID.
    function collectEth(uint256 tokenID_) public returns (uint256 payout) {
        payout = _collectEthTo(msg.sender, tokenID_);
    }

    /// collects the ALCa tokens yield of a given position. The caller of
    /// this function must be the owner of the tokenID.
    function collectToken(uint256 tokenID_) public returns (uint256 payout) {
        payout = _collectTokenTo(msg.sender, tokenID_);
    }

    /// collects the ether and ALCa tokens yields of a given position. The caller of
    /// this function must be the owner of the tokenID.
    function collectAllProfits(uint256 tokenID_)
        public
        returns (uint256 payoutToken, uint256 payoutEth)
    {
        payoutToken = _collectTokenTo(msg.sender, tokenID_);
        payoutEth = _collectEthTo(msg.sender, tokenID_);
    }

    /// collects the ether yield of a given position and send to the `to_` address.
    /// The caller of this function must be the owner of the tokenID.
    function collectEthTo(address to_, uint256 tokenID_) public returns (uint256 payout) {
        payout = _collectEthTo(to_, tokenID_);
    }

    /// collects the ALCa tokens yield of a given position and send to the `to_`
    /// address. The caller of this function must be the owner of the tokenID.
    function collectTokenTo(address to_, uint256 tokenID_) public returns (uint256 payout) {
        payout = _collectTokenTo(to_, tokenID_);
    }

    /// collects the ether and ALCa tokens yields of a given position and send to the
    /// `to_` address. The caller of this function must be the owner of the tokenID.
    function collectAllProfitsTo(address to_, uint256 tokenID_)
        public
        returns (uint256 payoutToken, uint256 payoutEth)
    {
        payoutToken = _collectTokenTo(to_, tokenID_);
        payoutEth = _collectEthTo(to_, tokenID_);
    }

    /// gets the total amount of AToken staked in contract
    function getTotalShares() public view returns (uint256) {
        return _shares;
    }

    /// gets the total amount of Ether staked in contract
    function getTotalReserveEth() public view returns (uint256) {
        return _reserveEth;
    }

    /// gets the total amount of AToken staked in contract
    function getTotalReserveAToken() public view returns (uint256) {
        return _reserveToken;
    }

    /// estimateEthCollection returns the amount of eth a tokenID may withdraw
    function estimateEthCollection(uint256 tokenID_)
        public
        view
        onlyIfTokenExists(tokenID_)
        returns (uint256 payout)
    {
        Position memory p = _positions[tokenID_];
        Accumulator memory ethState = _ethState;
        uint256 shares = _shares;
        (, , , payout) = _collect(shares, ethState, p, p.accumulatorEth);
        return payout;
    }

    /// estimateTokenCollection returns the amount of AToken a tokenID may withdraw
    function estimateTokenCollection(uint256 tokenID_)
        public
        view
        onlyIfTokenExists(tokenID_)
        returns (uint256 payout)
    {
        Position memory p = _positions[tokenID_];
        uint256 shares = _shares;
        Accumulator memory tokenState = _tokenState;
        (, , , payout) = _collect(shares, tokenState, p, p.accumulatorToken);
        return payout;
    }

    /// estimateExcessToken returns the amount of AToken that is held in the
    /// name of this contract. The value returned is the value that would be
    /// returned by a call to skimExcessToken.
    function estimateExcessToken() public view returns (uint256 excess) {
        (, excess) = _estimateExcessToken();
        return excess;
    }

    /// estimateExcessEth returns the amount of Eth that is held in the name of
    /// this contract. The value returned is the value that would be returned by
    /// a call to skimExcessEth.
    function estimateExcessEth() public view returns (uint256 excess) {
        return _estimateExcessEth();
    }

    /// gets the position struct given a tokenID. The tokenId must
    /// exist.
    function getPosition(uint256 tokenID_)
        public
        view
        onlyIfTokenExists(tokenID_)
        returns (
            uint256 shares,
            uint256 freeAfter,
            uint256 withdrawFreeAfter,
            uint256 accumulatorEth,
            uint256 accumulatorToken
        )
    {
        Position memory p = _positions[tokenID_];
        shares = uint256(p.shares);
        freeAfter = uint256(p.freeAfter);
        withdrawFreeAfter = uint256(p.withdrawFreeAfter);
        accumulatorEth = p.accumulatorEth;
        accumulatorToken = p.accumulatorToken;
    }

    /// Gets token URI
    function tokenURI(uint256 tokenID_)
        public
        view
        override(ERC721Upgradeable)
        onlyIfTokenExists(tokenID_)
        returns (string memory)
    {
        return IStakingNFTDescriptor(_stakingPositionDescriptorAddress()).tokenURI(this, tokenID_);
    }

    /// gets the current value for the Eth accumulator
    function getEthAccumulator() public view returns (uint256 accumulator, uint256 slush) {
        accumulator = _ethState.accumulator;
        slush = _ethState.slush;
    }

    /// gets the current value for the Token accumulator
    function getTokenAccumulator() public view returns (uint256 accumulator, uint256 slush) {
        accumulator = _tokenState.accumulator;
        slush = _tokenState.slush;
    }

    /// gets the ID of the latest minted position
    function getLatestMintedPositionID() public view returns (uint256) {
        return _getCount();
    }

    /// gets the _ACCUMULATOR_SCALE_FACTOR used to scale the ether and tokens
    /// deposited on this contract to reduce the integer division errors.
    function getAccumulatorScaleFactor() public pure returns (uint256) {
        return _ACCUMULATOR_SCALE_FACTOR;
    }

    /// gets the _MAX_MINT_LOCK value. This value is the maximum duration of blocks that we allow a
    /// position to be locked when minted
    function getMaxMintLock() public pure returns (uint256) {
        return _MAX_MINT_LOCK;
    }

    /// gets the _MAX_MINT_LOCK value. This value is the maximum duration of blocks that we allow a
    /// position to be locked
    function getMaxGovernanceLock() public pure returns (uint256) {
        return _MAX_GOVERNANCE_LOCK;
    }

    function __stakingNFTInit(string memory name_, string memory symbol_)
        internal
        onlyInitializing
    {
        __ERC721_init(name_, symbol_);
    }

    // _lockPosition prevents a position from being burned for duration_ number
    // of blocks by setting the freeAfter field on the Position struct returns
    // the number of shares in the locked Position so that governance vote
    // counting may be performed when setting a lock
    //
    // Note well: This function *assumes* that tokenID position exists.
    //            This is because the existance check is performed
    //            at the higher level.
    function _lockPosition(uint256 tokenID_, uint256 duration_)
        internal
        onlyIfTokenExists(tokenID_)
        returns (uint256 shares)
    {
        Position memory p = _positions[tokenID_];
        uint32 freeDur = uint32(block.number) + uint32(duration_);
        p.freeAfter = freeDur > p.freeAfter ? freeDur : p.freeAfter;
        _positions[tokenID_] = p;
        return p.shares;
    }

    // _lockWithdraw prevents a position from being collected and burned for duration_ number of blocks
    // by setting the withdrawFreeAfter field on the Position struct.
    // returns the number of shares in the locked Position so that
    //
    // Note well: This function *assumes* that tokenID position exists.
    //            This is because the existance check is performed
    //            at the higher level.
    function _lockWithdraw(uint256 tokenID_, uint256 duration_)
        internal
        onlyIfTokenExists(tokenID_)
        returns (uint256 shares)
    {
        Position memory p = _positions[tokenID_];
        uint256 freeDur = block.number + duration_;
        p.withdrawFreeAfter = freeDur > p.withdrawFreeAfter ? freeDur : p.withdrawFreeAfter;
        _positions[tokenID_] = p;
        return p.shares;
    }

    // _mintNFT performs the mint operation and invokes the inherited _mint method
    function _mintNFT(address to_, uint256 amount_) internal returns (uint256 tokenID) {
        // this is to allow struct packing and is safe due to AToken having a
        // total distribution of 220M
        if (amount_ == 0) {
            revert StakingNFTErrors.MintAmountZero();
        }
        if (amount_ > 2**224 - 1) {
            revert StakingNFTErrors.MintAmountExceedsMaximumSupply();
        }
        // transfer the number of tokens specified by amount_ into contract
        // from the callers account
        _safeTransferFromERC20(IERC20Transferable(_aTokenAddress()), msg.sender, amount_);

        // get local copy of storage vars to save gas
        uint256 shares = _shares;
        Accumulator memory ethState = _ethState;
        Accumulator memory tokenState = _tokenState;

        // get new tokenID from counter
        tokenID = _increment();

        // Call _slushSkim on Eth and Token accumulator before minting staked position.
        // This ensures that all stakers receive their appropriate rewards.
        if (shares > 0) {
            (ethState.accumulator, ethState.slush) = _slushSkim(
                shares,
                ethState.accumulator,
                ethState.slush
            );
            _ethState = ethState;
            (tokenState.accumulator, tokenState.slush) = _slushSkim(
                shares,
                tokenState.accumulator,
                tokenState.slush
            );
            _tokenState = tokenState;
        }

        // update storage
        shares += amount_;
        _shares = shares;
        _positions[tokenID] = Position(
            uint224(amount_),
            uint32(block.number) + 1,
            uint32(block.number) + 1,
            ethState.accumulator,
            tokenState.accumulator
        );
        _reserveToken += amount_;
        // invoke inherited method and return
        ERC721Upgradeable._mint(to_, tokenID);
        return tokenID;
    }

    // _burn performs the burn operation and invokes the inherited _burn method
    function _burn(
        address from_,
        address to_,
        uint256 tokenID_
    ) internal returns (uint256 payoutEth, uint256 payoutToken) {
        if (from_ != ownerOf(tokenID_)) {
            revert StakingNFTErrors.CallerNotTokenOwner(msg.sender);
        }

        // collect state
        Position memory p = _positions[tokenID_];
        // enforce freeAfter to prevent burn during lock
        if (p.freeAfter >= block.number || p.withdrawFreeAfter >= block.number) {
            revert StakingNFTErrors.FreeAfterTimeNotReached();
        }

        // get copy of storage to save gas
        uint256 shares = _shares;

        // calc Eth amounts due
        (p, payoutEth) = _collectEth(shares, p);

        // calc token amounts due
        (p, payoutToken) = _collectToken(shares, p);

        // add back to token payout the original stake position
        payoutToken += p.shares;

        // debit global shares counter and delete from mapping
        _shares -= p.shares;
        _reserveToken -= payoutToken;
        _reserveEth -= payoutEth;
        delete _positions[tokenID_];

        // invoke inherited burn method
        ERC721Upgradeable._burn(tokenID_);

        // transfer out all eth and tokens owed
        _safeTransferERC20(IERC20Transferable(_aTokenAddress()), to_, payoutToken);
        _safeTransferEth(to_, payoutEth);
        return (payoutEth, payoutToken);
    }

    /// collectEth returns all due Eth allocations to the to_ address. The caller
    /// of this function must be the owner of the tokenID
    function _collectEthTo(address to_, uint256 tokenID_) internal returns (uint256 payout) {
        Position memory position = _getPositionToCollect(tokenID_);
        // get values and update state
        (_positions[tokenID_], payout) = _collectEth(_shares, position);
        _reserveEth -= payout;
        // perform transfer and return amount paid out
        _safeTransferEth(to_, payout);
        return payout;
    }

    function _collectTokenTo(address to_, uint256 tokenID_) internal returns (uint256 payout) {
        Position memory position = _getPositionToCollect(tokenID_);
        // get values and update state
        (_positions[tokenID_], payout) = _collectToken(_shares, position);
        _reserveToken -= payout;
        // perform transfer and return amount paid out
        _safeTransferERC20(IERC20Transferable(_aTokenAddress()), to_, payout);
        return payout;
    }

    function _collectToken(uint256 shares_, Position memory p_)
        internal
        returns (Position memory p, uint256 payout)
    {
        uint256 acc;
        Accumulator memory tokenState = _tokenState;
        (tokenState, p, acc, payout) = _collect(shares_, tokenState, p_, p_.accumulatorToken);
        _tokenState = tokenState;
        p.accumulatorToken = acc;
        return (p, payout);
    }

    // _collectEth performs call to _collect and updates state during a request
    // for an eth distribution
    function _collectEth(uint256 shares_, Position memory p_)
        internal
        returns (Position memory p, uint256 payout)
    {
        uint256 acc;
        Accumulator memory ethState = _ethState;
        (ethState, p, acc, payout) = _collect(shares_, ethState, p_, p_.accumulatorEth);
        _ethState = ethState;
        p.accumulatorEth = acc;
        return (p, payout);
    }

    // _estimateExcessEth returns the amount of Eth that is held in the name of
    // this contract
    function _estimateExcessEth() internal view returns (uint256 excess) {
        uint256 reserve = _reserveEth;
        uint256 balance = address(this).balance;
        if (balance < reserve) {
            revert StakingNFTErrors.BalanceLessThanReserve(balance, reserve);
        }
        excess = balance - reserve;
    }

    // _estimateExcessToken returns the amount of AToken that is held in the
    // name of this contract
    function _estimateExcessToken()
        internal
        view
        returns (IERC20Transferable aToken, uint256 excess)
    {
        uint256 reserve = _reserveToken;
        aToken = IERC20Transferable(_aTokenAddress());
        uint256 balance = aToken.balanceOf(address(this));
        if (balance < reserve) {
            revert StakingNFTErrors.BalanceLessThanReserve(balance, reserve);
        }
        excess = balance - reserve;
        return (aToken, excess);
    }

    function _getPositionToCollect(uint256 tokenID_)
        internal
        view
        returns (Position memory position)
    {
        address owner = ownerOf(tokenID_);
        if (msg.sender != owner) {
            revert StakingNFTErrors.CallerNotTokenOwner(msg.sender);
        }
        position = _positions[tokenID_];
        if (_positions[tokenID_].withdrawFreeAfter >= block.number) {
            revert StakingNFTErrors.LockDurationWithdrawTimeNotReached();
        }
    }

    // _collect performs calculations necessary to determine any distributions
    // due to an account such that it may be used for both token and eth
    // distributions this prevents the need to keep redundant logic
    function _collect(
        uint256 shares_,
        Accumulator memory state_,
        Position memory p_,
        uint256 positionAccumulatorValue_
    )
        internal
        pure
        returns (
            Accumulator memory,
            Position memory,
            uint256,
            uint256
        )
    {
        (state_.accumulator, state_.slush) = _slushSkim(shares_, state_.accumulator, state_.slush);
        // determine number of accumulator steps this Position needs distributions from
        uint256 accumulatorDelta;
        if (positionAccumulatorValue_ > state_.accumulator) {
            accumulatorDelta = 2**168 - positionAccumulatorValue_;
            accumulatorDelta += state_.accumulator;
            positionAccumulatorValue_ = state_.accumulator;
        } else {
            accumulatorDelta = state_.accumulator - positionAccumulatorValue_;
            // update accumulator value for calling method
            positionAccumulatorValue_ += accumulatorDelta;
        }
        // calculate payout based on shares held in position
        uint256 payout = accumulatorDelta * p_.shares;
        // if there are no shares other than this position, flush the slush fund
        // into the payout and update the in memory state object
        if (shares_ == p_.shares) {
            payout += state_.slush;
            state_.slush = 0;
        }

        uint256 payoutRemainder = payout;
        // reduce payout by scale factor
        payout /= _ACCUMULATOR_SCALE_FACTOR;
        // Computing and saving the numeric error from the floor division in the
        // slush.
        payoutRemainder -= payout * _ACCUMULATOR_SCALE_FACTOR;
        state_.slush += payoutRemainder;

        return (state_, p_, positionAccumulatorValue_, payout);
    }

    // _deposit allows an Accumulator to be updated with new value if there are
    // no currently staked positions, all value is stored in the slush
    function _deposit(uint256 delta_, Accumulator memory state_)
        internal
        pure
        returns (Accumulator memory)
    {
        state_.slush += (delta_ * _ACCUMULATOR_SCALE_FACTOR);

        // Slush should be never be above 2**167 to protect against overflow in
        // the later code.
        if (state_.slush >= 2**167) {
            revert StakingNFTErrors.SlushTooLarge(state_.slush);
        }
        return state_;
    }

    // _slushSkim flushes value from the slush into the accumulator if there are
    // no currently staked positions, all value is stored in the slush
    function _slushSkim(
        uint256 shares_,
        uint256 accumulator_,
        uint256 slush_
    ) internal pure returns (uint256, uint256) {
        if (shares_ > 0) {
            uint256 deltaAccumulator = slush_ / shares_;
            slush_ -= deltaAccumulator * shares_;
            accumulator_ += deltaAccumulator;
            // avoiding accumulator_ overflow.
            if (accumulator_ > type(uint168).max) {
                // The maximum allowed value for the accumulator is 2**168-1.
                // This hard limit was set to not overflow the operation
                // `accumulator * shares` that happens later in the code.
                accumulator_ = accumulator_ % (2**168);
            }
        }
        return (accumulator_, slush_);
    }
}