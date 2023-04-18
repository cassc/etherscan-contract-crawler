// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

// OZ Upgrades imports
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// OpenZeppelin
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// ABDK
import { ABDKMath64x64 } from "abdk-libraries-solidity/ABDKMath64x64.sol";

// Local
import { AbstractStaking } from "./AbstractStaking.sol";
import { ITholosStaking } from "../interfaces/ITholosStaking.sol";
import { IPool721 } from "../interfaces/IPool721.sol";
import { IPool } from "../interfaces/IPool.sol";
import { FixedSizeQueue } from "../utils/FixedSizeQueue.sol";

/**************************************
    
    Tholos Staking contract

    ------------------------------

    Features:
    - yield based on pool supply
    - compounding
    - NFT staking support
    - tokens lockups

**************************************/

contract TholosStaking is Initializable, AbstractStaking, ITholosStaking, UUPSUpgradeable {

    // -----------------------------------------------------------------------
    //                             Library usage
    // -----------------------------------------------------------------------

    using FixedSizeQueue for FixedSizeQueue.BytesContainer;
    using ABDKMath64x64 for int128;

    // -----------------------------------------------------------------------
    //                             Roles
    // -----------------------------------------------------------------------

    bytes32 public constant IS_NFT_OPERATOR = keccak256("IS_NFT_OPERATOR");

    // -----------------------------------------------------------------------
    //                             Constants
    // -----------------------------------------------------------------------

    uint256 public constant REQUEST_UNSTAKE_DEADLINE = 10 days;
    uint256 private constant MAX_UNSTAKE_REQUESTS = 10;

    // -----------------------------------------------------------------------
    //                             State variables
    // -----------------------------------------------------------------------

    // storage
    mapping (uint256 => address) public nftOwners;
    mapping (address => uint16) public depositedNftsPerOwner;
    mapping (address => FixedSizeQueue.BytesContainer) public unstakeQueue;
    uint96 public tholPerNft;
    uint96 public maxNftRewardCap;
    uint16 public depositedNfts;

    // contracts
    IERC20 public tholos;
    IERC721 public nfts;

    // -----------------------------------------------------------------------
    //                             Security
    // -----------------------------------------------------------------------

    /**************************************

        Authorize upgrade

    **************************************/

    function _authorizeUpgrade(address) internal override
    onlyRole(CAN_UPGRADE) {}

    // -----------------------------------------------------------------------
    //                             Setup
    // -----------------------------------------------------------------------

    /**************************************

        Constructor

    **************************************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    /**************************************

        Initializer

     **************************************/

    function initialize(
        bytes memory _arguments
    ) external initializer {

        // 5109.489 THOL -> 5_600_000 THOL (20% of all rewards) divided by 1095 (days in 3 years)
        maxNftRewardCap = 5109489051094889791488;

        // decode arguments
        (
            address tholos_,
            address nfts_
        ) = abi.decode(
            _arguments,
            (
                address,
                address
            )
        );

        // storage
        tholos = IERC20(tholos_);

        // nfts
        nfts = IERC721(nfts_);

        // super
        __AbstractStaking_init();

        // events
        emit Initialised(_arguments);

    }

    /**************************************

        Configure

     **************************************/

    function configure(
        bytes calldata _configuration
    ) external virtual override
    onlyRole(DEFAULT_ADMIN_ROLE)
    onlyInState(State.UNCONFIGURED) {

        // decode arguments
        (
            address depositPool_,
            address rewardPool_,
            address nftOperator_
        ) = abi.decode(
            _configuration,
            (
                address,
                address,
                address
            )
        );

        // configuration
        _configure(depositPool_, rewardPool_);

        // operator role
        _grantRole(IS_NFT_OPERATOR, nftOperator_);

        // state
        state = State.CONFIGURED;

        // events
        emit Configured(_configuration);

    }

    // -----------------------------------------------------------------------
    //                             External
    // -----------------------------------------------------------------------

    /**************************************

        Claim unstake

    **************************************/

    function claimUnstake() external
    onlyInState(State.CONFIGURED) {

        // tx.members
        uint64 now_ = SafeCast.toUint64(block.timestamp);
        address sender_ = msg.sender;

        // local vars
        FixedSizeQueue.BytesContainer storage userQueue = unstakeQueue[sender_];
        uint256 unstakeRequestsNumber = userQueue.length;

        // counters
        uint96 amountSum_ = 0;
        uint256 numberOfUnstaked_ = 0;

        // claim tokens unstaked >= 10 days ago
        for (uint256 i = 0; i < unstakeRequestsNumber; i++) {

            // decode request
            (
                UnstakeRequest memory request_
            ) = abi.decode(
                userQueue.at(i, MAX_UNSTAKE_REQUESTS),
                (
                    UnstakeRequest
                )
            );

            // check if deadline achieved
            if (now_ < request_.deadline) {
                break;
            }

            // increase sum
            amountSum_ += request_.amount;
            numberOfUnstaked_++;
        }

        if (amountSum_ == 0) revert NothingToUnstake();

        // update user details
        userQueue.popFront(numberOfUnstaked_, MAX_UNSTAKE_REQUESTS);

        // transfer tokens
        IPool(address(depositPool)).withdraw(sender_, amountSum_);

        // emit event
        emit UnstakeClaimed(sender_, amountSum_);
    }

    /**************************************

        Set $THOL per NFT

        ------------------------------

        @param _tholPerNft amount of $THOL per NFT used to calculate NFT rewards

    **************************************/

    function setTholPerNft(uint96 _tholPerNft) external override
    onlyRole(IS_NFT_OPERATOR)
    onlyInState(State.CONFIGURED) {

        // set $THOL per NFT
        tholPerNft = _tholPerNft;

        // event
        emit TholPerNftUpdated(_tholPerNft);

    }

    /**************************************

        Set max reward for NFTs per compound

        ------------------------------

        @param _value maximum reward for NFTs per compound

    **************************************/

    function setMaxNftRewardCap(uint96 _value) external override
    onlyRole(CAN_MANAGE)
    onlyInState(State.CONFIGURED) {

        // set value
        maxNftRewardCap = _value;

        // event
        emit MaxRewardForNftsUpdated(_value);

    }

    /**************************************

        View: Get unstake request details

    **************************************/

    function getUnstakeRequest(address _account, uint256 _index) external view
    returns (bytes memory) {

        // return
        return unstakeQueue[_account].elements[_index];

    }

    // -----------------------------------------------------------------------
    //                             Internal
    // -----------------------------------------------------------------------

    /**************************************

        Deposit

    **************************************/

    function _deposit(
        uint96 _amount,
        bytes memory _extra
    ) internal virtual override {

        // tx.members
        address sender_ = msg.sender;
        address self_ = address(this);

        // decode nfts
        (
            uint256[] memory nfts_
        ) = _decodeExtra(_extra);

        // check amounts
        uint256 nftsCount_ = nfts_.length;
        if (_amount == 0 && nftsCount_ == 0) revert InvalidDeposit();

        // only when deposit tokens
        if (_amount > 0) {

            // check tholos allowance
            if (tholos.allowance(sender_, self_) < _amount) {
                revert NotEnoughAllowance(sender_, _amount);
            }

            // deposit tholos
            tholos.transferFrom(sender_, address(depositPool), _amount);

        }

        // only when deposit nfts
        if (nftsCount_ > 0) {

            // check nfts
            if (!nfts.isApprovedForAll(sender_, self_)) {
                revert NotEnoughNFTAllowance(sender_);
            }

            // deposit nfts
            for (uint256 i = 0; i < nftsCount_; i++) {
                nfts.transferFrom(sender_, address(depositPool), nfts_[i]);
            }

        }

    }

    /**************************************

        Withdraw

    **************************************/

    function _withdraw(
        uint96 _amount,
        bytes memory _extra
    ) internal virtual override {

        // tx.members
        address sender_ = msg.sender;

        // decode extra
        (
            uint256[] memory nfts_
        ) = _decodeExtra(_extra);

        // check amounts
        if (_amount == 0 && nfts_.length == 0) revert InvalidWithdrawal();

        // withdraw from pool
        IPool721(address(depositPool)).withdraw(sender_, nfts_);

    }

    /**************************************

        Check balance

    **************************************/

    function _checkBalance(
        uint96 _amount,
        bytes memory _extra
    ) internal virtual override {

        // tx.members
        address sender_ = msg.sender;

        // check balance
        if (balances[sender_].amount < _amount) {
            revert BalanceSmallerThanAmount(sender_, balances[sender_].amount, _amount);
        }

        // decode extra
        (
            uint256[] memory requiredNFTs_
        ) = _decodeExtra(_extra);

        // check nfts
        for (uint256 i = 0; i < requiredNFTs_.length; i++) {
            if (nftOwners[requiredNFTs_[i]] != sender_) {
                revert MissingNFT(sender_, requiredNFTs_[i]);
            }
        }

    }

    /**************************************

        Increase balance

    **************************************/

    function _increaseBalance(
        uint96 _amount,
        bytes memory _extra
    ) internal virtual override {

        // tx.members
        address sender_ = msg.sender;

        // decode extra
        (
            uint256[] memory newNFTs_
        ) = _decodeExtra(_extra);

        // loop through nfts
        for (uint256 i = 0; i < newNFTs_.length; i++) {

            // save new owner
            nftOwners[newNFTs_[i]] = sender_;

        }

        // update balance
        depositSum += _amount;
        depositedNfts += uint16(newNFTs_.length);
        depositedNftsPerOwner[sender_] += uint16(newNFTs_.length);
        balances[sender_] = Balance(
            balances[sender_].amount + _amount,
            compounding.rate,
            compounding.extraRate
        );

    }

    /**************************************

        Decrease balance

    **************************************/

    function _decreaseBalance(
        uint96 _amount,
        bytes memory _extra
    ) internal virtual override {

        // tx.members
        address sender_ = msg.sender;

        // decode extra
        (
            uint256[] memory oldNFTs_
        ) = _decodeExtra(_extra);

        // loop through nfts
        for (uint256 i = 0; i < oldNFTs_.length; i++) {

            // remove ownership
            delete nftOwners[oldNFTs_[i]];

        }

        // update balance
        depositSum -= _amount;
        depositedNfts -= uint16(oldNFTs_.length);
        depositedNftsPerOwner[sender_] -= uint16(oldNFTs_.length);
        balances[sender_] = Balance(
            balances[sender_].amount - _amount,
            compounding.rate,
            compounding.extraRate
        );

        if (_amount > 0) {
            // unstake
            _requestUnstake(_amount);
        }

    }

    /**************************************

        Request unstake

    **************************************/

    function _requestUnstake(uint96 _amount) internal {

        // tx.members
        uint64 now_ = SafeCast.toUint64(block.timestamp);
        address sender_ = msg.sender;

        // get unstake queue for user
        FixedSizeQueue.BytesContainer storage userQueue = unstakeQueue[sender_];
        if (userQueue.length == 10) {
            revert TooManyUnstakeRequested(sender_);
        }

        // create unstake request
        uint64 deadline_ = uint64(now_ + REQUEST_UNSTAKE_DEADLINE);
        UnstakeRequest memory unstakeRequest_ = UnstakeRequest(
            deadline_,
            _amount
        );

        // save request
        userQueue.pushBack(abi.encode(unstakeRequest_), MAX_UNSTAKE_REQUESTS);

    }

    /**************************************

        Reward pool withdraw

    **************************************/

    function _rewardPoolWithdraw(address _receiver, uint256 _amount) internal override {

        // return
        tholos.transferFrom(rewardPool, _receiver, _amount);

    }

    /**************************************

        Decode extra

    **************************************/

    function _decodeExtra(
        bytes memory _extra
    ) internal pure
    returns (uint256[] memory) {

        // return
        return abi.decode(
            _extra,
            (
                uint256[]
            )
        );

    }

    /**************************************

        View: Reward pool info

    **************************************/

    function _rewardPoolInfo() internal override view
    returns (uint96) {

        // return
        return uint96(tholos.balanceOf(rewardPool));

    }

    /**************************************

        View: Get total amount of rewards for staked NFTs

        ------------------------------

        @param _account address for which rewards should be calculated
        @return rewards for staked NFTs

    **************************************/

    function _userExtraRewards(address _account) internal override view
    returns (uint96) {

        // get user nfts count
        uint256 amount_ = depositedNftsPerOwner[_account];

        // return 0 if user doesn't have NFTs
        if (amount_ == 0) return 0;

        // get balance
        Balance memory balance_ = balances[_account];

        // calculate ratio for NFT rewards
        uint96 rewardRatio_ = uint96(uint256(compounding.extraRate) - uint256(balance_.extraSnapshot));

        // return 0 if ratio equal 0
        if (rewardRatio_ == 0) return 0;

        // return current rewards for given user for staked NFTs
        return uint96(amount_ * rewardRatio_);

    }

    /**************************************

        View: Get extra sum

        ------------------------------

        @return NFT value in $THOL

    **************************************/

    function _getExtraSum() internal override view
    returns (uint96) {

        // return
        return tholPerNft * depositedNfts;

    }

    /**************************************

        View: Calculate rewards per staked NFT

        ------------------------------

        @notice Calculated rewards per staked NFT
        @param _nftVal value of nfts in $THOL
        @param _ipy percentage yield for single compounding
        @return nftRewards_ amount of total NFT rewards
        @return rewardRatio_ ratio of $THOL per NFTs

    **************************************/

    function _calculateExtraRewards(uint96 _nftVal, int128 _ipy) internal override view
    returns (uint96 nftRewards_, bytes32 rewardRate_) {

        // avoid dividing by 0 if NFTs are not staked
        if (depositedNfts == 0) return (0, 0);

        // calculate rewards for NFTs
        nftRewards_ = uint96(_ipy.mulu(_nftVal));

        // compute rate by using smaller value
        uint96 rate_ = nftRewards_ < maxNftRewardCap ? nftRewards_ : maxNftRewardCap;
        rate_ /= depositedNfts;

        // cap rewards
        nftRewards_ = rate_ * depositedNfts;

        // encode rate
        rewardRate_ = bytes32(uint256(rate_));

    }

    /**************************************

        View: Increment extra rate

        ------------------------------

        @param _existingRate byte32 encoded existing NFT rate
        @param _incrementRate byte32 encoded new rate to increment NFT rate
        @return byte32 encoded sum of old and new rate

    **************************************/

    function _incrementExtraRate(bytes32 _existingRate, bytes32 _incrementRate) internal override pure
    returns (bytes32) {

        // return
        return bytes32(uint256(_existingRate) + uint256(_incrementRate));

    }

}