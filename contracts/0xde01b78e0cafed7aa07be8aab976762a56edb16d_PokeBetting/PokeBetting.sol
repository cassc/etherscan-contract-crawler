/**
 *Submitted for verification at Etherscan.io on 2023-07-29
*/

/*
Website: https://pokebets.io
Telegram bot betting in dev.
visit the website or twitter for latest details and current battles
Twitter: https://twitter.com/PBETSTOKEN/
*/
// File: contracts/Ownable.sol


pragma solidity ^0.8.4;

/// @notice Simple single owner authorization mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/auth/Ownable.sol)
/// @dev While the ownable portion follows [EIP-173](https://eips.ethereum.org/EIPS/eip-173)
/// for compatibility, the nomenclature for the 2-step ownership handover
/// may be unique to this codebase.
abstract contract Ownable {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The caller is not authorized to call the function.
    error Unauthorized();

    /// @dev The `newOwner` cannot be the zero address.
    error NewOwnerIsZeroAddress();

    /// @dev The `pendingOwner` does not have a valid handover request.
    error NoHandoverRequest();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ownership is transferred from `oldOwner` to `newOwner`.
    /// This event is intentionally kept the same as OpenZeppelin's Ownable to be
    /// compatible with indexers and [EIP-173](https://eips.ethereum.org/EIPS/eip-173),
    /// despite it not being as lightweight as a single argument event.
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    /// @dev An ownership handover to `pendingOwner` has been requested.
    event OwnershipHandoverRequested(address indexed pendingOwner);

    /// @dev The ownership handover to `pendingOwner` has been canceled.
    event OwnershipHandoverCanceled(address indexed pendingOwner);

    /// @dev `keccak256(bytes("OwnershipTransferred(address,address)"))`.
    uint256 private constant _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE =
        0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0;

    /// @dev `keccak256(bytes("OwnershipHandoverRequested(address)"))`.
    uint256 private constant _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE =
        0xdbf36a107da19e49527a7176a1babf963b4b0ff8cde35ee35d6cd8f1f9ac7e1d;

    /// @dev `keccak256(bytes("OwnershipHandoverCanceled(address)"))`.
    uint256 private constant _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE =
        0xfa7b8eab7da67f412cc9575ed43464468f9bfbae89d1675917346ca6d8fe3c92;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The owner slot is given by: `not(_OWNER_SLOT_NOT)`.
    /// It is intentionally choosen to be a high value
    /// to avoid collision with lower slots.
    /// The choice of manual storage layout is to enable compatibility
    /// with both regular and upgradeable contracts.
    uint256 private constant _OWNER_SLOT_NOT = 0x8b78c6d8;

    /// The ownership handover slot of `newOwner` is given by:
    /// ```
    ///     mstore(0x00, or(shl(96, user), _HANDOVER_SLOT_SEED))
    ///     let handoverSlot := keccak256(0x00, 0x20)
    /// ```
    /// It stores the expiry timestamp of the two-step ownership handover.
    uint256 private constant _HANDOVER_SLOT_SEED = 0x389a75e1;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Initializes the owner directly without authorization guard.
    /// This function must be called upon initialization,
    /// regardless of whether the contract is upgradeable or not.
    /// This is to enable generalization to both regular and upgradeable contracts,
    /// and to save gas in case the initial owner is not the caller.
    /// For performance reasons, this function will not check if there
    /// is an existing owner.
    function _initializeOwner(address newOwner) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits.
            newOwner := shr(96, shl(96, newOwner))
            // Store the new value.
            sstore(not(_OWNER_SLOT_NOT), newOwner)
            // Emit the {OwnershipTransferred} event.
            log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, 0, newOwner)
        }
    }

    /// @dev Sets the owner directly without authorization guard.
    function _setOwner(address newOwner) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let ownerSlot := not(_OWNER_SLOT_NOT)
            // Clean the upper 96 bits.
            newOwner := shr(96, shl(96, newOwner))
            // Emit the {OwnershipTransferred} event.
            log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, sload(ownerSlot), newOwner)
            // Store the new value.
            sstore(ownerSlot, newOwner)
        }
    }

    /// @dev Throws if the sender is not the owner.
    function _checkOwner() internal view virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // If the caller is not the stored owner, revert.
            if iszero(eq(caller(), sload(not(_OWNER_SLOT_NOT)))) {
                mstore(0x00, 0x82b42900) // `Unauthorized()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC UPDATE FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Allows the owner to transfer the ownership to `newOwner`.
    function transferOwnership(address newOwner) public payable virtual onlyOwner {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(shl(96, newOwner)) {
                mstore(0x00, 0x7448fbae) // `NewOwnerIsZeroAddress()`.
                revert(0x1c, 0x04)
            }
        }
        _setOwner(newOwner);
    }

    /// @dev Allows the owner to renounce their ownership.
    function renounceOwnership() public payable virtual onlyOwner {
        _setOwner(address(0));
    }

    /// @dev Request a two-step ownership handover to the caller.
    /// The request will be automatically expire in 48 hours (172800 seconds) by default.
    function requestOwnershipHandover() public payable virtual {
        unchecked {
            uint256 expires = block.timestamp + ownershipHandoverValidFor();
            /// @solidity memory-safe-assembly
            assembly {
                // Compute and set the handover slot to `expires`.
                mstore(0x0c, _HANDOVER_SLOT_SEED)
                mstore(0x00, caller())
                sstore(keccak256(0x0c, 0x20), expires)
                // Emit the {OwnershipHandoverRequested} event.
                log2(0, 0, _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE, caller())
            }
        }
    }

    /// @dev Cancels the two-step ownership handover to the caller, if any.
    function cancelOwnershipHandover() public payable virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and set the handover slot to 0.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, caller())
            sstore(keccak256(0x0c, 0x20), 0)
            // Emit the {OwnershipHandoverCanceled} event.
            log2(0, 0, _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE, caller())
        }
    }

    /// @dev Allows the owner to complete the two-step ownership handover to `pendingOwner`.
    /// Reverts if there is no existing ownership handover requested by `pendingOwner`.
    function completeOwnershipHandover(address pendingOwner) public payable virtual onlyOwner {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and set the handover slot to 0.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, pendingOwner)
            let handoverSlot := keccak256(0x0c, 0x20)
            // If the handover does not exist, or has expired.
            if gt(timestamp(), sload(handoverSlot)) {
                mstore(0x00, 0x6f5e8818) // `NoHandoverRequest()`.
                revert(0x1c, 0x04)
            }
            // Set the handover slot to 0.
            sstore(handoverSlot, 0)
        }
        _setOwner(pendingOwner);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   PUBLIC READ FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the owner of the contract.
    function owner() public view virtual returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(not(_OWNER_SLOT_NOT))
        }
    }

    /// @dev Returns the expiry timestamp for the two-step ownership handover to `pendingOwner`.
    function ownershipHandoverExpiresAt(address pendingOwner)
        public
        view
        virtual
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the handover slot.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, pendingOwner)
            // Load the handover slot.
            result := sload(keccak256(0x0c, 0x20))
        }
    }

    /// @dev Returns how long a two-step ownership handover is valid for in seconds.
    function ownershipHandoverValidFor() public view virtual returns (uint64) {
        return 48 * 3600;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MODIFIERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Marks a function as only callable by the owner.
    modifier onlyOwner() virtual {
        _checkOwner();
        _;
    }
}
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/PokeBetting.sol


pragma solidity ^0.8.21;




contract PokeBetting is ReentrancyGuard, Ownable {
    IERC20 public pbetsToken;

    uint256 constant CONTRACT_FEE_PERCENT = 2;
    
    uint256 private contractBalance;

    uint256 public version;

    enum States {
        Open,
        Closed,
        Resolved
    }
    States public state = States.Resolved;

    mapping(uint256 => mapping(address => mapping(uint256 => uint256)))
        public betAmounts;
    mapping(uint256 => mapping(uint256 => uint256)) public totalPerOutcome;

    mapping(uint256 => mapping(address => uint16[])) public userPredictions;

    mapping(uint256 => uint256) public winningOutcome;
    mapping(uint256 => uint256) public total;

    event BetPlaced(
        address indexed user,
        uint256 prediction,
        uint256 amount,
        uint256 version
    );
    event BetResolved(uint256 winningOutcome, uint256 version);
    event Claimed(address indexed user, uint256 amount, uint256 version);
    event BettingOpened(uint256 version);
    event BettingClosed();

    constructor(IERC20 _pbetsToken) {
        _initializeOwner(msg.sender);
        pbetsToken = _pbetsToken;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               PUBLIC NON-PAYABLE FUNCTIONS                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @notice Function to place a bet
     * @param _prediction The prediction made by the bettor
     * @param _amount The bet amount
     */
    function battleWager(uint256 _prediction, uint256 _amount)
        public
        nonReentrant
    {
        require(state == States.Open);
        require(_prediction == 0 || _prediction == 1, "Prediction cannot be zero");
        require(_amount >= 100 * 1e9, "Bet amount must be greater than 100");

        uint256 betAmount = (_amount * (100 - CONTRACT_FEE_PERCENT)) / 100;

        pbetsToken.transferFrom(msg.sender, address(this), _amount);

        contractBalance += (_amount - betAmount);
        betAmounts[version][msg.sender][_prediction] += betAmount;
        totalPerOutcome[version][_prediction] += betAmount;
        total[version] += betAmount;

        userPredictions[version][msg.sender].push(uint16(_prediction));

        emit BetPlaced(msg.sender, _prediction, betAmount, version);
    }

    /**
     * @notice Function to claim winnings
     */
    function winnerClaim() public nonReentrant {
        require(state == States.Resolved, "Bet has not been resolved yet");
        uint256 currentOutcome = winningOutcome[version];
        require(
            betAmounts[version][msg.sender][currentOutcome] > 0,
            "No winnings to claim"
        );

        uint256 amount = (betAmounts[version][msg.sender][currentOutcome] *
            total[version]) / totalPerOutcome[version][currentOutcome];
        require(
            pbetsToken.balanceOf(address(this)) >= amount,
            "Not enough tokens to pay out"
        );

        betAmounts[version][msg.sender][currentOutcome] = 0;
        pbetsToken.transfer(msg.sender, amount);

        emit Claimed(msg.sender, amount, version);
    }

    /**
     * @notice Function to claim winnings from a previous version
     * @param _version The version from which to claim
     */
    function claimOldWinnings(uint256 _version) public nonReentrant {
        require(_version > 0);
        require(
            _version < version,
            "This function is only for claiming old winnings"
        );
        uint256 currentOutcome = winningOutcome[version];
        require(
            betAmounts[_version][msg.sender][currentOutcome] > 0,
            "No winnings to claim"
        );

        uint256 amount = (betAmounts[_version][msg.sender][currentOutcome] *
            total[version]) / totalPerOutcome[_version][currentOutcome];
        require(
            pbetsToken.balanceOf(address(this)) >= amount,
            "Not enough tokens to pay out"
        );

        betAmounts[_version][msg.sender][currentOutcome] = 0;
        pbetsToken.transfer(msg.sender, amount);

        emit Claimed(msg.sender, amount, version);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC VIEW FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @notice Function to get the total bet amount for a particular outcome
     * @param _outcome The outcome to check
     * @return The total bet amount for the outcome
     */
    function getTotalBetsForOutcome(uint256 _outcome)
        public
        view
        returns (uint256)
    {
        return totalPerOutcome[version][_outcome];
    }

    /**
     * @notice Function to get the total bet amount of a user
     * @param _user The user to check
     * @return The total bet amount of the user
     */
    function getUserTotalBets(address _user) public view returns (uint256) {
        uint256 totalBets = 0;
        unchecked {
            for (
                uint256 i = 0;
                i < userPredictions[version][_user].length;
                i++
            ) {
                totalBets += betAmounts[version][_user][
                    userPredictions[version][_user][i]
                ];
            }
        }
        return totalBets;
    }

    /**
     * @notice Function to get the total bet amount a user has placed for a particular outcome
     * @param _user The user to check
     * @param _outcome The outcome to check
     * @return The total bet amount the user has placed for the outcome
     */
    function getUserPredictionForOutcome(address _user, uint256 _outcome)
        public
        view
        returns (uint256)
    {
        return betAmounts[version][_user][_outcome];
    }

    /**
     * @notice Function to get the total bet amount a user has placed for a particular outcome
     * @param _user The user to check
     * @param _outcomes The outcomes to check
     * @return amounts The total bet amounts the user has placed for the outcomes
     */
    function getUserPredictionForOutcomes(
        address _user,
        uint256[] memory _outcomes
    ) public view returns (uint256[] memory amounts) {
        amounts = new uint256[](_outcomes.length);
        unchecked {
            for (uint256 i = 0; i < _outcomes.length; i++) {
                amounts[i] = betAmounts[version][_user][_outcomes[i]];
            }
        }
        return amounts;
    }

    /**
     * @notice Function to get the total balance currently held in the contract
     * @return The total balance currently held in the contract
     */
    function getContractBalance() public view returns (uint256) {
        return contractBalance;
    }

    /**
     * @notice Function to get all outcomes a user has bet on
     * @param _user The address of the user
     * @return An array of outcomes the user has bet on
     */
    function getUserOutcomes(address _user)
        public
        view
        returns (uint16[] memory)
    {
        return userPredictions[version][_user];
    }

    /**
     * @notice Function to get amount to claim for current version     
     * @return amount The amount to claim
     */
    function getAmountToClaimCurrent() public view returns (uint256) {        
        if (betAmounts[version][msg.sender][winningOutcome[version]] == 0) {
            return 0;
        }

        uint256 amount = (betAmounts[version][msg.sender][
            winningOutcome[version]
        ] * total[version]) / totalPerOutcome[version][winningOutcome[version]];

        return amount;
    }

    /**
     * @notice Function to get amount to claim
     * @param _version The version from which to claim
     * @return amount The amount to claim
     */
    function getAmountToClaim(uint256 _version) public view returns (uint256) {
        require(_version > 0);
        require(_version <= version, "Version does not exist");

        if (betAmounts[_version][msg.sender][winningOutcome[_version]] == 0) {
            return 0;
        }

        uint256 amount = (betAmounts[_version][msg.sender][
            winningOutcome[_version]
        ] * total[version]) / totalPerOutcome[_version][winningOutcome[_version]];

        return amount;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               EXTERNAL ONLY-OWNER FUNCTIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    /**
     * @notice Function to close betting
     */
    function openBetting() external onlyOwner {
        require(state == States.Resolved);
        version++;
        state = States.Open;        

        emit BettingOpened(version);
    }

    /**
     * @notice Function to close betting
     */
    function closeBetting() external onlyOwner {
        require(state == States.Open);
        state = States.Closed;

        emit BettingClosed();
    }

    /**
     * @notice Function to resolve a bet
     * @param _winningOutcome The winning outcome
     */
    function resolveBet(uint256 _winningOutcome) external onlyOwner {
        require(state == States.Closed);
        winningOutcome[version] = _winningOutcome;
        state = States.Resolved;

        emit BetResolved(_winningOutcome, version);
    }

    /**
     * @notice Function to withdraw contract fees
     * @param recipient Address to receive the withdrawn fees
     */
    function withdrawContractFees(address recipient) external onlyOwner {
        uint256 balance = contractBalance;
        contractBalance = 0;
        // Transfer fees to the owner
        pbetsToken.transfer(recipient, balance);
    }
}