/**
 *Submitted for verification at Etherscan.io on 2023-07-05
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
    /**
     * @notice method that is simulated by the keepers to see if any work actually
     * needs to be performed. This method does does not actually need to be
     * executable, and since it is only ever simulated it can consume lots of gas.
     * @dev To ensure that it is never called, you may want to add the
     * cannotExecute modifier from KeeperBase to your implementation of this
     * method.
     * @param checkData specified in the upkeep registration so it is always the
     * same for a registered upkeep. This can easily be broken down into specific
     * arguments using `abi.decode`, so multiple upkeeps can be registered on the
     * same contract and easily differentiated by the contract.
     * @return upkeepNeeded boolean to indicate whether the keeper should call
     * performUpkeep or not.
     * @return performData bytes that the keeper should call performUpkeep with, if
     * upkeep is needed. If you would like to encode data to decode later, try
     * `abi.encode`.
     */
    function checkUpkeep(
        bytes calldata checkData
    ) external returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @notice method that is actually executed by the keepers, via the registry.
     * The data returned by the checkUpkeep simulation will be passed into
     * this method to actually be executed.
     * @dev The input to this method should not be trusted, and the caller of the
     * method should not even be restricted to any single registry. Anyone should
     * be able call it, and the input should be validated, there is no guarantee
     * that the data passed in is the performData returned from checkUpkeep. This
     * could happen due to malicious keepers, racing keepers, or simply a state
     * change while the performUpkeep transaction is waiting for confirmation.
     * Always validate the data passed in.
     * @param performData is the data which was passed back from the checkData
     * simulation. If it is encoded, it can easily be decoded into other types by
     * calling `abi.decode`. This data should not be trusted, and should be
     * validated against the contract's current state.
     */
    function performUpkeep(bytes calldata performData) external;
}

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
    error OnlySimulatedBackend();

    /**
     * @notice method that allows it to be simulated via eth_call by checking that
     * the sender is the zero address.
     */
    function preventExecution() internal view {
        if (tx.origin != address(0)) {
            revert OnlySimulatedBackend();
        }
    }

    /**
     * @notice modifier that allows it to be simulated via eth_call by checking
     * that the sender is the zero address.
     */
    modifier cannotExecute() {
        preventExecution();
        _;
    }
}

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
    /**
     * @notice Get configuration relevant for making requests
     * @return minimumRequestConfirmations global min for request confirmations
     * @return maxGasLimit global max for request gas limit
     * @return s_provingKeyHashes list of registered key hashes
     */
    function getRequestConfig()
        external
        view
        returns (uint16, uint32, bytes32[] memory);

    /**
     * @notice Request a set of random words.
     * @param keyHash - Corresponds to a particular oracle job which uses
     * that key for generating the VRF proof. Different keyHash's have different gas price
     * ceilings, so you can select a specific one to bound your maximum per request cost.
     * @param subId  - The ID of the VRF subscription. Must be funded
     * with the minimum subscription balance required for the selected keyHash.
     * @param minimumRequestConfirmations - How many blocks you'd like the
     * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
     * for why you may want to request more. The acceptable range is
     * [minimumRequestBlockConfirmations, 200].
     * @param callbackGasLimit - How much gas you'd like to receive in your
     * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
     * may be slightly less than this amount because of gas used calling the function
     * (argument decoding etc.), so you may need to request slightly more than you expect
     * to have inside fulfillRandomWords. The acceptable range is
     * [0, maxGasLimit]
     * @param numWords - The number of uint256 random values you'd like to receive
     * in your fulfillRandomWords callback. Note these numbers are expanded in a
     * secure way by the VRFCoordinator from a single random value supplied by the oracle.
     * @return requestId - A unique identifier of the request. Can be used to match
     * a request to a response in fulfillRandomWords.
     */
    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId);

    /**
     * @notice Create a VRF subscription.
     * @return subId - A unique subscription id.
     * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
     * @dev Note to fund the subscription, use transferAndCall. For example
     * @dev  LINKTOKEN.transferAndCall(
     * @dev    address(COORDINATOR),
     * @dev    amount,
     * @dev    abi.encode(subId));
     */
    function createSubscription() external returns (uint64 subId);

    /**
     * @notice Get a VRF subscription.
     * @param subId - ID of the subscription
     * @return balance - LINK balance of the subscription in juels.
     * @return reqCount - number of requests for this subscription, determines fee tier.
     * @return owner - owner of the subscription.
     * @return consumers - list of consumer address which are able to use this subscription.
     */
    function getSubscription(
        uint64 subId
    )
        external
        view
        returns (
            uint96 balance,
            uint64 reqCount,
            address owner,
            address[] memory consumers
        );

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @param newOwner - proposed new owner of the subscription
     */
    function requestSubscriptionOwnerTransfer(
        uint64 subId,
        address newOwner
    ) external;

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @dev will revert if original owner of subId has
     * not requested that msg.sender become the new owner.
     */
    function acceptSubscriptionOwnerTransfer(uint64 subId) external;

    /**
     * @notice Add a consumer to a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - New consumer which can use the subscription
     */
    function addConsumer(uint64 subId, address consumer) external;

    /**
     * @notice Remove a consumer from a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - Consumer to remove from the subscription
     */
    function removeConsumer(uint64 subId, address consumer) external;

    /**
     * @notice Cancel a subscription
     * @param subId - ID of the subscription
     * @param to - Where to send the remaining LINK to
     */
    function cancelSubscription(uint64 subId, address to) external;

    /*
     * @notice Check to see if there exists a request commitment consumers
     * for all consumers and keyhashes for a given sub.
     * @param subId - ID of the subscription
     * @return true if there exists at least one unfulfilled request for the subscription, false
     * otherwise.
     */
    function pendingRequestExists(uint64 subId) external view returns (bool);
}

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
    error OnlyCoordinatorCanFulfill(address have, address want);
    address private immutable vrfCoordinator;

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
     */
    constructor(address _vrfCoordinator) {
        vrfCoordinator = _vrfCoordinator;
    }

    /**
     * @notice fulfillRandomness handles the VRF response. Your contract must
     * @notice implement it. See "SECURITY CONSIDERATIONS" above for ////important
     * @notice principles to keep in mind when implementing your fulfillRandomness
     * @notice method.
     *
     * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
     * @dev signature, and will call it once it has verified the proof
     * @dev associated with the randomness. (It is triggered via a call to
     * @dev rawFulfillRandomness, below.)
     *
     * @param requestId The Id initially returned by requestRandomness
     * @param randomWords the VRF output expanded to the requested number of words
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal virtual;

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external {
        if (msg.sender != vrfCoordinator) {
            revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
        }
        fulfillRandomWords(requestId, randomWords);
    }
}

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import "./AutomationBase.sol";
////import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is
    AutomationBase,
    AutomationCompatibleInterface
{

}

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

////// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title   BlazeLottery
 * @author  SemiInvader
 * @notice  This contract is a lottery contract that will be used to distribute BLZ tokens to users
 *          The lottery will be a 5/63 lottery, where users will buy tickets with 5 numbers each spanning 8 bits in length
 *          The lottery will be run on a weekly basis, with the lottery ending on a specific time and date
 * @dev ////IMPORTANT DEPENDENCIES:
 *      - Chainlink VRF ConsumerBase -> Request randomness for winner number
 *      - Chainlink VRF Coordinator (Interface only) -> receive randomness from this one
 *      - Chainlink Keepers Implementation -> Once winner is received, check all tickets for matches and return count of matches back to contract to save that particular data
 *      - Chainlink Keeper Implementation 2 -> request randomness for next round
 */

////import "@openzeppelin/contracts/access/Ownable.sol";
////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
////import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
////import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
////import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

//-------------------------------------------------------------------------
//    INTERFACES
//-------------------------------------------------------------------------
interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}
//-------------------------------------------------------------------------
//    ERRORS
//-------------------------------------------------------------------------
error BlazeJackpot__RoundInactive(uint256);
error BlazeJackpot__InsufficientTickets();
error BlazeJackpot__InvalidMatchers();
error BlazeJackpot__InvalidMatchRound();
error BlazeJackpot__InvalidUpkeeper();
error BlazeJackpot__InvalidRoundEndConditions();
error BlazeJackpot__InvalidRound();
error BlazeJackpot__TransferFailed();
error BlazeJackpot__InvalidClaim();
error BlazeJackpot__DuplicateTicketIdClaim(uint _round, uint _ticketIndex);
error BlazeJackpot__InvalidClaimMatch(uint ticketIndex);

contract BlazeJackpot is
    Ownable,
    ReentrancyGuard,
    AutomationCompatible,
    VRFConsumerBaseV2
{
    //-------------------------------------------------------------------------
    //    TYPE DECLARATIONS
    //-------------------------------------------------------------------------
    struct RoundInfo {
        uint256 pot;
        uint256 ticketsBought;
        uint256 price;
        uint256 endRound; // Timestamp OR block number when round ends
        uint randomnessRequestID;
        bool active;
    }
    struct UserTickets {
        uint64[] tickets;
        bool[] claimed;
    }
    struct Matches {
        uint256 match1;
        uint256 match2;
        uint256 match3;
        uint256 match4;
        uint256 match5;
        uint256 roundId;
        uint64 winnerNumber; // We'll need to process this so it matches the same format as the tickets
        bool completed;
    }
    //-------------------------------------------------------------------------
    //    State Variables
    //-------------------------------------------------------------------------
    // kept for coverage purposes
    // mapping(address => bool ) public upkeeper;
    // mapping(uint  => Matches ) public matches;
    // mapping(uint => RoundInfo) public roundInfo;
    // mapping(uint => address[]) private roundUsers;
    // mapping(address  => mapping(uint => UserTickets))
    //     private userTickets;
    mapping(address _upkeep => bool _enabled) public upkeeper;
    mapping(uint _randomnessRequestID => Matches _winnerMatches) public matches;
    mapping(uint _roundId => RoundInfo) public roundInfo;
    mapping(uint _roundId => address[] participatingUsers) private roundUsers;
    mapping(address _user => mapping(uint _round => UserTickets _all))
        private userTickets;

    uint[7] public distributionPercentages;
    // [match1, match2, match3, match4, match5, burn, team]
    // 25% Match 5
    // 25% Match 4
    // 25% Match 3
    // 0% Match 2
    // 0% Match 1
    // 20% Burns
    // 5%  Team
    address public constant DEAD_WALLET =
        0x000000000000000000000000000000000000dEaD;
    //-------------------------------------------------------------------------
    //    VRF Config Variables
    //-------------------------------------------------------------------------
    address public immutable vrfCoordinator;
    bytes32 public immutable keyHash;
    uint64 private immutable subscriptionId;
    uint16 private constant minimumRequestConfirmations = 4;
    uint32 private callbackGasLimit = 100000;

    address public teamWallet;

    IERC20Burnable public currency;
    uint256 public currentRound;
    uint256 public roundDuration;
    uint256 public constant PERCENTAGE_BASE = 100;
    uint64 public constant BIT_8_MASK = 0x00000000000000FF;
    uint64 public constant BIT_6_MASK = 0x000000000000003F;
    uint8 public constant BIT_1_MASK = 0x01;
    bool public roundIsActive;

    //-------------------------------------------------------------------------
    //    Events
    //-------------------------------------------------------------------------
    event AddToPot(address indexed user, uint256 indexed round, uint256 amount);
    event BoughtTickets(address indexed user, uint _round, uint amount);
    event EditRoundPrice(uint _round, uint _newPrice);
    event RolloverPot(uint _round, uint _newPot);
    event RoundEnded(uint indexed _round);
    event StartRound(uint indexed _round);
    event UpkeeperSet(address indexed upkeeper, bool isUpkeeper);
    event RewardClaimed(address indexed _user, uint rewardAmount);
    event RoundDurationSet(uint _oldDuration, uint _newDuration);

    //-------------------------------------------------------------------------
    //    Modifiers
    //-------------------------------------------------------------------------
    modifier onlyUpkeeper() {
        if (!upkeeper[msg.sender]) revert BlazeJackpot__InvalidUpkeeper();
        _;
    }

    //-------------------------------------------------------------------------
    //    Constructor
    //-------------------------------------------------------------------------
    constructor(
        address _tokenAccepted,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        address _team
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        // _tokenAccepted is BLZ token
        currency = IERC20Burnable(_tokenAccepted);

        roundDuration = 1 weeks;
        vrfCoordinator = _vrfCoordinator;
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;

        distributionPercentages = [0, 0, 25, 25, 25, 20, 5];
        teamWallet = _team;
    }

    //-------------------------------------------------------------------------
    //    EXTERNAL Functions
    //-------------------------------------------------------------------------

    /**
     *
     * @param tickets Array of tickets to buy. The tickets need to have 5 numbers each spanning 8 bits in length
     * @dev each number will be constrained to 6 bit numbers e.g. 0 - 63
     * @dev since each number is 6 bits in length but stored on an 8 bit space, we'll be using uint64 to store the numbers
     *      E.G.
     *      Storing the ticket with numbers 35, 12, 0, 63, 1
     *      each number in 8 bit hex becomes 0x23, 0x0C, 0x00, 0x3F, 0x01
     *      number to store = 0x000000230C003F01
     *      Although we will not check for this, the numbers will be be checked using bit shifting with a mask so any larger numbers will be ignored
     * @dev gas cost is reduced ludicrously, however we will be relying heavily on chainlink keepers to check for winners and get the match amount data
     */
    function buyTickets(uint64[] calldata tickets) external nonReentrant {
        RoundInfo storage playingRound = roundInfo[currentRound];
        if (!playingRound.active || block.timestamp > playingRound.endRound)
            revert BlazeJackpot__RoundInactive(currentRound);
        // Check ticket array
        uint256 ticketAmount = tickets.length;
        if (ticketAmount == 0) {
            revert BlazeJackpot__InsufficientTickets();
        }
        // Get payment from ticket price
        uint256 price = playingRound.price * ticketAmount;
        if (price > 0) addToPot(price, currentRound);

        playingRound.ticketsBought += ticketAmount;
        // Save Ticket to current Round
        UserTickets storage user = userTickets[msg.sender][currentRound];
        // Add user to the list of users to check for winners
        if (user.tickets.length == 0) roundUsers[currentRound].push(msg.sender);

        for (uint i = 0; i < ticketAmount; i++) {
            user.tickets.push(tickets[i]);
            user.claimed.push(false);
        }
        emit BoughtTickets(msg.sender, currentRound, ticketAmount);
    }

    /**
     *
     * @param _round round to claim tickets from
     * @param _userTicketIndexes Indexes / IDs of the tickets to claim
     * @param _matches matching number of the ticket/id to claim
     */
    function claimTickets(
        uint _round,
        uint[] calldata _userTicketIndexes,
        uint8[] calldata _matches
    ) public nonReentrant {
        uint toReward = _claimTickets(_round, _userTicketIndexes, _matches);
        if (toReward > 0) currency.transfer(msg.sender, toReward);
        emit RewardClaimed(msg.sender, toReward);
    }

    /**
     *
     * @param _rounds array of all rounds that will be claimed
     * @param _ticketsPerRound number of tickets that will be claimed in this call
     * @param _ticketIndexes array of ticket indexes to be claimed, the length of this array should be equal to the sum of _ticketsPerRound
     * @param _matches array to matches per ticket, the length of this array should be equal to the sum of _ticketsPerRound
     */
    function claimMultipleRounds(
        uint[] calldata _rounds,
        uint[] calldata _ticketsPerRound,
        uint[] calldata _ticketIndexes,
        uint8[] calldata _matches
    ) external nonReentrant {
        if (
            _rounds.length != _ticketsPerRound.length ||
            _rounds.length == 0 ||
            _ticketIndexes.length != _matches.length ||
            _ticketIndexes.length == 0
        ) revert BlazeJackpot__InvalidClaim();
        uint ticketOffset;
        uint rewards;
        for (uint i = 0; i < _rounds.length; i++) {
            uint round = _rounds[i];
            uint endOffset = _ticketsPerRound[i] - 1;
            uint[] memory tickets = _ticketIndexes[ticketOffset:ticketOffset +
                endOffset];
            uint8[] memory allegedMatch = _matches[ticketOffset:ticketOffset +
                endOffset];

            rewards += _claimTickets(round, tickets, allegedMatch);
            ticketOffset += _ticketsPerRound[i];
        }
        if (rewards > 0) currency.transfer(msg.sender, rewards);
        emit RewardClaimed(msg.sender, rewards);
    }

    /**
     * @notice Edit the price for an upcoming round
     * @param _newPrice Price for the next upcoming round
     * @param _roundId ID of the upcoming round to edit
     * @dev If this is not called, on round end, the price will be the same as the previous round
     */
    function setPrice(uint256 _newPrice, uint256 _roundId) external onlyOwner {
        require(_roundId > currentRound, "Invalid ID");
        roundInfo[_roundId].price = _newPrice;
        emit EditRoundPrice(_roundId, _newPrice);
    }

    /**
     *
     * @param initPrice Price for the first round
     * @param firstRoundEnd the Time when the first round ends
     * @dev This function can only be called once by owner and sets the initial price
     */
    function activateLottery(
        uint initPrice,
        uint firstRoundEnd
    ) external onlyOwner {
        require(currentRound == 0, "Lottery started");
        currentRound++;
        RoundInfo storage startRound = roundInfo[1];
        startRound.price = initPrice;
        startRound.active = true;
        startRound.endRound = firstRoundEnd;
        emit StartRound(1);
    }

    /**
     * @param _upkeeper Address of the upkeeper
     * @param _status Status of the upkeeper
     * @dev enable or disable an address that can call performUpkeep
     */
    function setUpkeeper(address _upkeeper, bool _status) external onlyOwner {
        upkeeper[_upkeeper] = _status;
        emit UpkeeperSet(_upkeeper, _status);
    }

    /**
     *
     * @param performData Data to perform upkeep
     * @dev performData is abi encoded as (bool, uint256[])
     *      - bool is if it's a round end request upkeep or winner array request upkeep
     *      - uint256[] is the array of winners that match the criteria
     */
    function performUpkeep(bytes calldata performData) external onlyUpkeeper {
        //Only upkeepers can do this
        if (!upkeeper[msg.sender]) revert BlazeJackpot__InvalidUpkeeper();

        (bool isRandomRequest, uint256[] memory matchers) = abi.decode(
            performData,
            (bool, uint256[])
        );
        RoundInfo storage playingRound = roundInfo[currentRound];
        if (isRandomRequest) {
            endRound();
        } else {
            if (matchers.length != 5 || playingRound.active)
                revert BlazeJackpot__InvalidMatchers();
            Matches storage currentMatches = matches[
                playingRound.randomnessRequestID
            ];
            if (currentMatches.winnerNumber == 0 || currentMatches.completed)
                revert BlazeJackpot__InvalidMatchRound();
            currentMatches.match1 = matchers[0];
            currentMatches.match2 = matchers[1];
            currentMatches.match3 = matchers[2];
            currentMatches.match4 = matchers[3];
            currentMatches.match5 = matchers[4];
            currentMatches.completed = true;
            rolloverAmount(currentRound, currentMatches);
            newRound(playingRound);
        }
    }

    function setRoundDuration(uint256 _newDuration) external onlyOwner {
        emit RoundDurationSet(roundDuration, _newDuration);
        roundDuration = _newDuration;
    }

    //-------------------------------------------------------------------------
    //    PUBLIC FUNCTIONS
    //-------------------------------------------------------------------------
    /**
     * @notice Add Blaze to the POT of the selected round
     * @param amount Amount of Blaze to add to the pot
     * @param round Round to add the Blaze to
     */
    function addToPot(uint amount, uint round) public {
        if (round < currentRound || round == 0)
            revert BlazeJackpot__InvalidRound();
        currency.transferFrom(msg.sender, address(this), amount);
        roundInfo[round].pot += amount;
        emit AddToPot(msg.sender, amount, round);
    }

    /**
     * @notice End the current round
     * @dev this function can be called by anyone as long as the conditions to end the round are met
     */
    function endRound() public {
        RoundInfo storage playingRound = roundInfo[currentRound];
        // Check that endRound of current Round is passed
        if (
            block.timestamp > playingRound.endRound &&
            playingRound.active &&
            playingRound.randomnessRequestID == 0
        ) {
            playingRound.active = false;
            emit RoundEnded(currentRound);
            if (playingRound.ticketsBought == 0) {
                rolloverAmount(currentRound, matches[0]);
                newRound(playingRound);
            } else {
                uint requestId = VRFCoordinatorV2Interface(vrfCoordinator)
                    .requestRandomWords(
                        keyHash,
                        subscriptionId,
                        minimumRequestConfirmations,
                        callbackGasLimit,
                        1
                    );
                playingRound.randomnessRequestID = requestId;
                matches[requestId].roundId = currentRound;
            }
        } else revert BlazeJackpot__InvalidRoundEndConditions();
    }

    //-------------------------------------------------------------------------
    //    INTERNAL FUNCTIONS
    //-------------------------------------------------------------------------
    function fulfillRandomWords(
        uint requestId,
        uint256[] memory randomWords
    ) internal override {
        uint64 winnerNumber = uint64(randomWords[0]);
        uint64 addedMask = 0;
        for (uint8 i = 0; i < 5; i++) {
            // pass a 6 bit mask to get the last 6 bits of each number
            addedMask += winnerNumber & (BIT_6_MASK << (8 * i));
        }
        if (addedMask == 0) addedMask = uint64(1);
        matches[requestId].winnerNumber = addedMask;
    }

    function _claimTickets(
        uint _round,
        uint[] memory _userTicketIndexes,
        uint8[] memory _matches
    ) internal returns (uint) {
        if (_round >= currentRound) revert BlazeJackpot__InvalidRound();
        if (
            _userTicketIndexes.length != _matches.length ||
            _userTicketIndexes.length == 0
        ) revert BlazeJackpot__InvalidClaim();
        RoundInfo storage round = roundInfo[_round];

        UserTickets storage user = userTickets[msg.sender][_round];
        if (user.tickets.length < _userTicketIndexes.length)
            revert BlazeJackpot__InvalidClaim();

        Matches storage roundMatches = matches[round.randomnessRequestID];
        uint toReward;

        // Cycle through all tickets to claim
        for (uint i = 0; i < _userTicketIndexes.length; i++) {
            uint ticketIndex = _userTicketIndexes[i];
            // index is checked and if out of bounds, will revert
            if (_matches[i] == 0 || _matches[i] > 5)
                revert BlazeJackpot__InvalidClaimMatch(i);

            if (user.claimed[ticketIndex])
                revert BlazeJackpot__DuplicateTicketIdClaim(
                    _round,
                    ticketIndex
                );

            uint64 ticket = user.tickets[ticketIndex];

            if (
                _compareTickets(roundMatches.winnerNumber, ticket) ==
                _matches[i]
            ) {
                uint totalMatches = getTotalMatches(roundMatches, _matches[i]);

                user.claimed[ticketIndex] = true;

                uint256 matchReward = (round.pot *
                    distributionPercentages[_matches[i] - 1]);
                toReward += matchReward / (totalMatches * PERCENTAGE_BASE);
            } else {
                revert BlazeJackpot__InvalidClaimMatch(i);
            }
        }
        return toReward;
    }

    //-------------------------------------------------------------------------
    //    PRIVATE FUNCTIONS
    //-------------------------------------------------------------------------
    function rolloverAmount(uint round, Matches storage matchInfo) private {
        RoundInfo storage playingRound = roundInfo[round];
        RoundInfo storage nextRound = roundInfo[round + 1];

        uint currentPot = playingRound.pot;
        uint nextPot = 0;
        if (playingRound.pot == 0) return;
        // Check amount of winners of each match type and their distribution percentages
        if (matchInfo.match1 == 0 && distributionPercentages[0] > 0)
            nextPot += (currentPot * distributionPercentages[0]) / 100;
        if (matchInfo.match2 == 0 && distributionPercentages[1] > 0)
            nextPot += (currentPot * distributionPercentages[1]) / 100;
        if (matchInfo.match3 == 0 && distributionPercentages[2] > 0)
            nextPot += (currentPot * distributionPercentages[2]) / 100;
        if (matchInfo.match4 == 0 && distributionPercentages[3] > 0)
            nextPot += (currentPot * distributionPercentages[3]) / 100;
        if (matchInfo.match5 == 0 && distributionPercentages[4] > 0)
            nextPot += (currentPot * distributionPercentages[4]) / 100;
        // BURN the Currency Amount
        uint burnAmount = (distributionPercentages[5] * currentPot) / 100;
        // Send the appropriate percent to the team wallet
        uint teamPot = (distributionPercentages[6] * currentPot) / 100;
        try currency.burn(burnAmount) {} catch {
            currency.transfer(DEAD_WALLET, burnAmount);
        }
        bool succ = currency.transfer(teamWallet, teamPot);
        if (!succ) revert BlazeJackpot__TransferFailed();
        nextRound.pot += nextPot;
        emit RolloverPot(round, nextPot);
    }

    function newRound(RoundInfo storage playingRound) private {
        currentRound++;
        roundInfo[currentRound].active = true;
        roundInfo[currentRound].endRound =
            playingRound.endRound +
            roundDuration;
        if (roundInfo[currentRound].price == 0)
            roundInfo[currentRound].price = playingRound.price;
    }

    function getTotalMatches(
        Matches storage winners,
        uint8 matched
    ) private view returns (uint) {
        if (matched == 1) return winners.match1;
        if (matched == 2) return winners.match2;
        if (matched == 3) return winners.match3;
        if (matched == 4) return winners.match4;
        if (matched == 5) return winners.match5;
        return 0;
    }

    //-------------------------------------------------------------------------
    //    INTERNAL & PRIVATE VIEW & PURE FUNCTIONS
    //-------------------------------------------------------------------------
    /**
     *
     * @param winnerNumber Base Number to check against
     * @param ticketNumber Number to check against the base number
     * @return matchAmount Number of matches between the two numbers
     */
    function _compareTickets(
        uint64 winnerNumber,
        uint64 ticketNumber
    ) private pure returns (uint8 matchAmount) {
        uint64 winnerMask;
        uint64 ticketMask;
        uint8 matchesChecked = 0x00;

        // cycle through all 5 numbers on winnerNumber
        for (uint8 i = 0; i < 5; i++) {
            winnerMask = (winnerNumber >> (8 * i)) & BIT_6_MASK;
            // cycle through all 5 numbers on ticketNumber
            for (uint8 j = 0; j < 5; j++) {
                // check if this ticket Mask has already been matched
                uint8 maskCheck = BIT_1_MASK << j;
                if (matchesChecked & maskCheck == maskCheck) {
                    continue;
                }
                ticketMask = (ticketNumber >> (8 * j)) & BIT_8_MASK;
                // If number is larger than 6 bits, ignore
                if (ticketMask > BIT_6_MASK) {
                    matchesChecked = matchesChecked | maskCheck;
                    continue;
                }

                if (winnerMask == ticketMask) {
                    matchAmount++;
                    matchesChecked = matchesChecked | maskCheck;
                    break;
                }
            }
        }
    }

    //-------------------------------------------------------------------------
    //    EXTERNAL AND PUBLIC VIEW & PURE FUNCTIONS
    //-------------------------------------------------------------------------
    /**
     * @notice Check if upkeep is needed
     * @param checkData Data to check for upkeep
     * @return upkeepNeeded Whether upkeep is needed
     * @return performData Data to perform upkeep
     *          - We use two types of upkeeps here. 1 Time , 2 Custom logic
     *          - 1. Time based upkeep is used to end the round and request for randomness
     *          - 2. Custom logic is used to check for winners
     *          - performData has 2 values, endRoundRequest (bool) and matching numbers (uint[])
     *           if endRoundRequest is true, then we will end the round and request for randomness
     *          if matching numbers is not empty, then we will check for winners
     *          after winners are selected we increase the round number and activate it
     */
    function checkUpkeep(
        bytes calldata checkData
    ) external view returns (bool upkeepNeeded, bytes memory performData) {
        checkData; // Dummy to remove unused var warning
        // Is this a endRound request or a checkWinner request?
        RoundInfo storage playingRound = roundInfo[currentRound];
        uint[] memory matchingNumbers = new uint[](5);
        performData = bytes("");
        if (playingRound.active) {
            upkeepNeeded = playingRound.endRound < block.timestamp;
            performData = abi.encode(true, matchingNumbers);
        } else if (
            playingRound.randomnessRequestID > 0 &&
            !matches[playingRound.randomnessRequestID].completed &&
            matches[playingRound.randomnessRequestID].winnerNumber > 0
        ) {
            upkeepNeeded = true;
            address[] storage participants = roundUsers[currentRound];
            uint participantsLength = participants.length;
            uint64 winnerNumber = matches[playingRound.randomnessRequestID]
                .winnerNumber;
            for (uint i = 0; i < participantsLength; i++) {
                UserTickets storage user = userTickets[participants[i]][
                    currentRound
                ];
                uint ticketsLength = user.tickets.length;
                for (uint j = 0; j < ticketsLength; j++) {
                    uint8 matchAmount = _compareTickets(
                        winnerNumber,
                        user.tickets[j]
                    );
                    if (matchAmount > 0) {
                        matchingNumbers[matchAmount - 1]++;
                    }
                }
            }
            performData = abi.encode(false, matchingNumbers);
        } else upkeepNeeded = false;
    }

    function checkTicket(
        uint round,
        uint _userTicketIndex,
        address _user
    ) external view returns (uint) {
        uint pot = roundInfo[round].pot;
        uint64 winnerNumber = matches[roundInfo[round].randomnessRequestID]
            .winnerNumber;
        if (pot == 0 || winnerNumber == 0) return 0;
        // Check if user has claimed this ticket
        if (userTickets[_user][round].claimed[_userTicketIndex]) return 0;

        uint8 _matched_ = _compareTickets(
            matches[roundInfo[round].randomnessRequestID].winnerNumber,
            userTickets[_user][round].tickets[_userTicketIndex]
        );
        if (_matched_ == 0) return 0;
        uint totalMatches = getTotalMatches(
            matches[roundInfo[round].randomnessRequestID],
            _matched_
        );
        if (totalMatches == 0) return 0;
        return
            (pot * distributionPercentages[_matched_ - 1]) /
            (PERCENTAGE_BASE * totalMatches);
    }

    function checkTickets(
        uint round,
        uint[] calldata _userTicketIndexes,
        address _user
    ) external view returns (uint) {
        uint pot = roundInfo[round].pot;
        uint64 winnerNumber = matches[roundInfo[round].randomnessRequestID]
            .winnerNumber;
        if (pot == 0 || winnerNumber == 0) return 0;

        uint totalReward;
        uint rndId = roundInfo[round].randomnessRequestID;

        for (uint i = 0; i < _userTicketIndexes.length; i++) {
            uint ticketIndex = _userTicketIndexes[i];
            // Check if user has claimed this ticket
            if (userTickets[_user][round].claimed[ticketIndex]) continue;

            uint8 _matched_ = _compareTickets(
                matches[rndId].winnerNumber,
                userTickets[_user][round].tickets[ticketIndex]
            );
            if (_matched_ == 0) continue;
            uint totalMatches = getTotalMatches(matches[rndId], _matched_);
            if (totalMatches == 0) continue;
            totalReward +=
                (pot * distributionPercentages[_matched_ - 1]) /
                (PERCENTAGE_BASE * totalMatches);
        }
        return totalReward;
    }

    function getUserTickets(
        address _user,
        uint round
    )
        external
        view
        returns (
            uint64[] memory _userTickets,
            bool[] memory claimed,
            uint tickets
        )
    {
        UserTickets storage user = userTickets[_user][round];
        tickets = user.tickets.length;
        _userTickets = new uint64[](tickets);
        claimed = new bool[](tickets);
        for (uint i = 0; i < tickets; i++) {
            _userTickets[i] = user.tickets[i];
            claimed[i] = user.claimed[i];
        }
    }

    function checkTicketMatching(
        uint64 ticket1,
        uint64 ticket2
    ) external pure returns (uint8) {
        return _compareTickets(ticket1, ticket2);
    }
}