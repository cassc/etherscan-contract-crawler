// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IAvoFactory } from "./interfaces/IAvoFactory.sol";

/// @title    AvoDepositManager
/// @notice   Handles deposits in a deposit token (e.g. USDC), user balances are tracked off-chain through events
contract AvoDepositManager is Initializable, PausableUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    struct WithdrawRequest {
        address to;
        uint256 amount;
    }

    /***********************************|
    |        IMMUTABLE VARIABLES        |
    |__________________________________*/

    /// @notice address of the deposit token (USDC)
    IERC20 public immutable depositToken;

    /// @notice address of the AvoFactory (proxy)
    IAvoFactory public immutable avoFactory;

    /***********************************|
    |           STATE VARIABLES         |
    |__________________________________*/

    /// @notice address to which funds can be withdrawn to. Configurable by owner
    /// @dev tightly packed with withdrawLimit
    address public withdrawAddress;

    /// @notice minimum amount which must stay in contract and can not be withdrawn. Configurable by owner
    /// @dev tightly packed with withdrawAddress
    uint96 public withdrawLimit;

    /// @notice static withdraw fee charged when a withdrawRequest is processed. Configurable by owner
    /// @dev tightly packed with minWithdrawAmount
    uint96 public withdrawFee;

    /// @notice minimum withdraw amount that a user must request to withdraw. Configurable by owner
    /// @dev tightly packed with withdrawFee
    uint96 public minWithdrawAmount;

    /// @notice allowed auths list (1 = allowed). Can confirm withdraw requests. Configurable by owner
    mapping(address => uint256) public auths;

    /// @notice withdraw requests. unique id -> WithdrawRequest (amount and receiver)
    mapping(bytes32 => WithdrawRequest) public withdrawRequests;

    /***********************************|
    |                EVENTS             |
    |__________________________________*/

    /// @notice emitted whenever a deposit occurs through depositOnBehalf
    event Deposit(address indexed sender, address indexed avoSafe, uint256 indexed amount);

    /// @notice emitted whenever a user requests a withdrawal
    event WithdrawRequested(bytes32 indexed id, address indexed avoSafe, uint256 indexed amount);

    /// @notice emitted whenever a withdraw request is executed
    event WithdrawProcessed(bytes32 indexed id, address indexed avoSafe, uint256 indexed amount, uint256 fee);

    /// @notice emitted whenever a withdraw request is removed
    event WithdrawRemoved(bytes32 indexed id);

    // Settings events
    /// @notice emitted whenever the withdrawLimit is modified by owner
    event SetWithdrawLimit(uint96 indexed withdrawLimit);
    /// @notice emitted whenever the withdrawFee is modified by owner
    event SetWithdrawFee(uint96 indexed withdrawFee);
    /// @notice emitted whenever the minWithdrawAmount is modified by owner
    event SetMinWithdrawAmount(uint96 indexed minWithdrawAmount);
    /// @notice emitted whenever the withdrawAddress is modified by owner
    event SetWithdrawAddress(address indexed withdrawAddress);
    /// @notice emitted whenever the auths are modified by owner
    event SetAuth(address indexed auth, bool indexed allowed);

    /***********************************|
    |                ERRORS             |
    |__________________________________*/

    /// @notice thrown when msg.sender is not authorized to access requested functionality
    error AvoDepositManager__Unauthorized();

    /// @notice thrown when invalid params for a method are submitted, e.g. 0x00 address
    error AvoDepositManager__InvalidParams();

    /// @notice thrown when a withdraw request already exists.
    error AvoDepositManager__RequestAlreadyExist();

    /// @notice thrown when a withdraw request does not exist.
    error AvoDepositManager__RequestNotExist();

    /// @notice thrown when a withdraw request does not at least request minWithdrawAmount
    error AvoDepositManager__MinWithdraw();

    /// @notice thrown when a withdraw request amount does not cover the withdraw fee at processing time
    error AvoDepositManager__FeeNotCovered();

    /***********************************|
    |              MODIFIERS            |
    |__________________________________*/

    /// @notice checks if an address is not 0x000...
    modifier validAddress(address address_) {
        if (address_ == address(0)) {
            revert AvoDepositManager__InvalidParams();
        }
        _;
    }

    /// @notice checks if msg.sender is allowed auth
    modifier onlyAuths() {
        // @dev using inverted positive case to save gas
        if (!(auths[msg.sender] == 1 || msg.sender == owner())) {
            revert AvoDepositManager__Unauthorized();
        }
        _;
    }

    /// @notice checks if address_ is an AvoSafe through AvoFactory
    modifier onlyAvoSafe(address address_) {
        if (avoFactory.isAvoSafe(address_) == false) {
            revert AvoDepositManager__Unauthorized();
        }
        _;
    }

    /***********************************|
    |    CONSTRUCTOR / INITIALIZERS     |
    |__________________________________*/

    constructor(IERC20 depositToken_, IAvoFactory avoFactory_)
        validAddress(address(depositToken_))
        validAddress(address(avoFactory_))
    {
        depositToken = depositToken_;
        avoFactory = avoFactory_;

        // ensure logic contract initializer is not abused by disabling initializing
        // see https://forum.openzeppelin.com/t/security-advisory-initialize-uups-implementation-contracts/15301
        // and https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializing_the_implementation_contract
        _disableInitializers();
    }

    /// @notice initializes the contract for owner_ as owner
    /// @param owner_           address of owner_ authorized to withdraw funds
    function initialize(
        address owner_,
        address withdrawAddress_,
        uint96 withdrawLimit_,
        uint96 minWithdrawAmount_,
        uint96 withdrawFee_
    ) public initializer validAddress(owner_) validAddress(withdrawAddress_) {
        // minWithdrawAmount must cover the withdrawFee at all times
        if (minWithdrawAmount_ < withdrawFee_) {
            revert AvoDepositManager__InvalidParams();
        }

        _transferOwnership(owner_);

        // contract will be paused at start, must be manually unpaused
        _pause();

        withdrawAddress = withdrawAddress_;
        withdrawLimit = withdrawLimit_;
        minWithdrawAmount = minWithdrawAmount_;
        withdrawFee = withdrawFee_;
    }

    /***********************************|
    |            PUBLIC API             |
    |__________________________________*/

    /// @notice         checks if a certain address is an allowed auth
    /// @param auth_    address to check
    /// @return         true if address is allowed auth
    function isAuth(address auth_) external view returns (bool) {
        return auths[auth_] == 1 || auth_ == owner();
    }

    /// @notice             Deposits amount of deposit token to this contract and emits the Deposit event
    ///                     with receiver address for off-chain tracking
    /// @param receiver_    address receiving funds via indirect off-chain tracking
    /// @param amount_      amount to deposit
    function depositOnBehalf(address receiver_, uint256 amount_) external validAddress(receiver_) {
        // @dev we can't use onlyAvoSafe modifier here because it would only work for already deployed AvoSafe
        depositToken.safeTransferFrom(msg.sender, address(this), amount_);

        emit Deposit(msg.sender, receiver_, amount_);
    }

    /// @notice             users can request withdrawal of funds
    /// @param amount_      amount to withdraw
    /// @return             uniqueId_ the unique withdraw request id used to trigger processing
    function requestWithdraw(uint256 amount_)
        external
        whenNotPaused
        onlyAvoSafe(msg.sender)
        returns (bytes32 uniqueId_)
    {
        if (amount_ < minWithdrawAmount || amount_ == 0) {
            revert AvoDepositManager__MinWithdraw();
        }

        // get a unique id based on block timestamp, sender and amount
        uniqueId_ = keccak256(abi.encode(block.timestamp, msg.sender, amount_));

        if (withdrawRequests[uniqueId_].amount > 0) {
            revert AvoDepositManager__RequestAlreadyExist();
        }

        withdrawRequests[uniqueId_] = WithdrawRequest(msg.sender, amount_);

        emit WithdrawRequested(uniqueId_, msg.sender, amount_);
    }

    /// @notice             auths or withdraw request receiver can remove a withdraw request
    /// @param withdrawId_  unique withdraw request id
    function removeWithdrawRequest(bytes32 withdrawId_) external {
        WithdrawRequest memory withdrawRequest_ = withdrawRequests[withdrawId_];

        if (withdrawRequest_.amount == 0) {
            revert AvoDepositManager__RequestNotExist();
        }

        // only auth (&owner) or withdraw request receiver can remove a withdraw request
        // @dev using inverted positive case to save gas
        if (!(auths[msg.sender] == 1 || msg.sender == owner() || msg.sender == withdrawRequest_.to)) {
            revert AvoDepositManager__Unauthorized();
        }

        delete withdrawRequests[withdrawId_];

        emit WithdrawRemoved(withdrawId_);
    }

    /// @notice    Withdraws balance of deposit token down to withdrawLimit to the configured withdrawAddress
    function withdraw() external {
        IERC20 depositToken_ = depositToken;
        uint256 withdrawLimit_ = withdrawLimit;

        uint256 balance_ = depositToken_.balanceOf(address(this));
        if (balance_ > withdrawLimit_) {
            uint256 withdrawAmount_;
            unchecked {
                // can not underflow because of if statement just above
                withdrawAmount_ = balance_ - withdrawLimit_;
            }

            depositToken_.safeTransfer(withdrawAddress, withdrawAmount_);
        }
    }

    /***********************************|
    |            ONLY AUTHS             |
    |__________________________________*/

    /// @notice             auths can authorize and execute withdraw requests
    /// @param withdrawId_  unique withdraw request id
    function processWithdraw(bytes32 withdrawId_) external onlyAuths whenNotPaused {
        WithdrawRequest memory withdrawRequest_ = withdrawRequests[withdrawId_];

        if (withdrawRequest_.amount == 0) {
            revert AvoDepositManager__RequestNotExist();
        }

        uint256 withdrawFee_ = withdrawFee;

        if (withdrawRequest_.amount < withdrawFee_) {
            // withdrawRequest_.amount could be < withdrawFee if the config value was modified after request was created
            revert AvoDepositManager__FeeNotCovered();
        }

        uint256 withdrawAmount_;
        unchecked {
            // because of if statement above we know this can not underflow
            withdrawAmount_ = withdrawRequest_.amount - withdrawFee_;
        }
        delete withdrawRequests[withdrawId_];

        depositToken.safeTransfer(withdrawRequest_.to, withdrawAmount_);

        emit WithdrawProcessed(withdrawId_, withdrawRequest_.to, withdrawAmount_, withdrawFee_);
    }

    /// @notice pauses withdraw requests and processing. Can only be unpaused by owner.
    function pause() external onlyAuths {
        _pause();
    }

    /***********************************|
    |            ONLY OWNER             |
    |__________________________________*/

    /// @notice                 Sets new withdraw limit
    /// @param withdrawLimit_   new value
    function setWithdrawLimit(uint96 withdrawLimit_) external onlyOwner {
        withdrawLimit = withdrawLimit_;
        emit SetWithdrawLimit(withdrawLimit_);
    }

    /// @notice                 Sets new withdraw fee (in absolute amount)
    /// @param withdrawFee_     new value
    function setWithdrawFee(uint96 withdrawFee_) external onlyOwner {
        // minWithdrawAmount must cover the withdrawFee at all times
        if (minWithdrawAmount < withdrawFee_) {
            revert AvoDepositManager__InvalidParams();
        }
        withdrawFee = withdrawFee_;
        emit SetWithdrawFee(withdrawFee_);
    }

    /// @notice                     Sets new min withdraw amount
    /// @param minWithdrawAmount_   new value
    function setMinWithdrawAmount(uint96 minWithdrawAmount_) external onlyOwner {
        // minWithdrawAmount must cover the withdrawFee at all times
        if (minWithdrawAmount_ < withdrawFee) {
            revert AvoDepositManager__InvalidParams();
        }
        minWithdrawAmount = minWithdrawAmount_;
        emit SetMinWithdrawAmount(minWithdrawAmount_);
    }

    /// @notice                   Sets new withdraw address
    /// @param withdrawAddress_   new value
    function setWithdrawAddress(address withdrawAddress_) external onlyOwner validAddress(withdrawAddress_) {
        withdrawAddress = withdrawAddress_;
        emit SetWithdrawAddress(withdrawAddress_);
    }

    /// @notice                   Sets an address as allowed auth or not
    /// @param auth_              address to set auth value for
    /// @param allowed_           bool flag for whether address is allowed as auth or not
    function setAuth(address auth_, bool allowed_) external onlyOwner validAddress(auth_) {
        auths[auth_] = allowed_ ? 1 : 0;
        emit SetAuth(auth_, allowed_);
    }

    /// @notice re-enables withdraw requests and processing
    function unpause() external onlyOwner {
        _unpause();
    }
}