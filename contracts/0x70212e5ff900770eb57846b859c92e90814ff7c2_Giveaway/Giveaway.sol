/**
 *Submitted for verification at Etherscan.io on 2023-08-06
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);

  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}
interface VRFV2WrapperInterface {
  /**
   * @return the request ID of the most recent VRF V2 request made by this wrapper. This should only
   * be relied option within the same transaction that the request was made.
   */
  function lastRequestId() external view returns (uint256);

  /**
   * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   */
  function calculateRequestPrice(uint32 _callbackGasLimit) external view returns (uint256);

  /**
   * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPrice(uint32 _callbackGasLimit, uint256 _requestGasPriceWei) external view returns (uint256);
}

/** *******************************************************************************
 * @notice Interface for contracts using VRF randomness through the VRF V2 wrapper
 * ********************************************************************************
 * @dev PURPOSE
 *
 * @dev Create VRF V2 requests without the need for subscription management. Rather than creating
 * @dev and funding a VRF V2 subscription, a user can use this wrapper to create one off requests,
 * @dev paying up front rather than at fulfillment.
 *
 * @dev Since the price is determined using the gas price of the request transaction rather than
 * @dev the fulfillment transaction, the wrapper charges an additional premium on callback gas
 * @dev usage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFV2WrapperConsumerBase. The consumer must be funded
 * @dev with enough LINK to make the request, otherwise requests will revert. To request randomness,
 * @dev call the 'requestRandomness' function with the desired VRF parameters. This function handles
 * @dev paying for the request based on the current pricing.
 *
 * @dev Consumers must implement the fullfillRandomWords function, which will be called during
 * @dev fulfillment with the randomness result.
 */
abstract contract VRFV2WrapperConsumerBase {
  LinkTokenInterface internal immutable LINK;
  VRFV2WrapperInterface internal immutable VRF_V2_WRAPPER;

  /**
   * @param _link is the address of LinkToken
   * @param _vrfV2Wrapper is the address of the VRFV2Wrapper contract
   */
  constructor(address _link, address _vrfV2Wrapper) {
    LINK = LinkTokenInterface(_link);
    VRF_V2_WRAPPER = VRFV2WrapperInterface(_vrfV2Wrapper);
  }

  /**
   * @dev Requests randomness from the VRF V2 wrapper.
   *
   * @param _callbackGasLimit is the gas limit that should be used when calling the consumer's
   *        fulfillRandomWords function.
   * @param _requestConfirmations is the number of confirmations to wait before fulfilling the
   *        request. A higher number of confirmations increases security by reducing the likelihood
   *        that a chain re-org changes a published randomness outcome.
   * @param _numWords is the number of random words to request.
   *
   * @return requestId is the VRF V2 request ID of the newly created randomness request.
   */
  function requestRandomness(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords
  ) internal returns (uint256 requestId) {
    LINK.transferAndCall(
      address(VRF_V2_WRAPPER),
      VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit),
      abi.encode(_callbackGasLimit, _requestConfirmations, _numWords)
    );
    return VRF_V2_WRAPPER.lastRequestId();
  }

  /**
   * @notice fulfillRandomWords handles the VRF V2 wrapper response. The consuming contract must
   * @notice implement it.
   *
   * @param _requestId is the VRF V2 request ID.
   * @param _randomWords is the randomness result.
   */
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
    require(msg.sender == address(VRF_V2_WRAPPER), "only VRF V2 wrapper can fulfill");
    fulfillRandomWords(_requestId, _randomWords);
  }
}

interface IFactory02 {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
}

interface IPair02 {
    function factory() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function sync() external;
}


interface IRouter02 {
    function WETH() external pure returns (address);
    function factory() external pure returns (address);

}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

contract Giveaway is  Context, Ownable, VRFV2WrapperConsumerBase(0x514910771AF9Ca656af840dff83E8264EcF986CA,0x5A861794B927983406fCE1D062e00b9368d97Df6)   {
    mapping(uint32 => address) public userIds;
    mapping(address => User) public users;
    uint32 public totalUsers = 0;
    uint32 public totalActiveUsers = 0;

    uint256 public totalLock = 0;
    uint256 public totalActiveLock = 0;

    uint256 public lockTime = 5_184_000 seconds; // 60 days
    uint256 public lockAmount = 10_000_000_000 * 10**18;

    address public winner;
    bool public isGameFinished;

    IERC20 public token;

    event Lock(address indexed locker, uint256 lockedAmount, uint256 unlockDate);
    event Unlock(address indexed locker, uint256 unlockedAmount);
    event LockTimeUpdated(uint256 newTime);
    event TokenUpdated(address newToken);
    event WinnerDrawn();
    event WinnerUpdated(address indexed winner, uint256 chainLinkRequestId);
    event LockAmountUpdated(uint256 lockAmount);

    struct User {
        uint256 lockedAmount;
        bool isUnlocked;
        uint256 unlockDate;
    }

    constructor(address _token) {
        token = IERC20(_token);
    }

    function lock() external returns(uint256 _lockAmount) {
        require(!isGameFinished, "Game is finished");
        address sender = _msgSender();
        User memory currentUser = users[sender];
        require(currentUser.lockedAmount == 0, "Tokens already locked");

        // Update User
        users[sender] = User(lockAmount,false, block.timestamp + lockTime);
        userIds[totalUsers] = sender;

        // Update Global stats
        totalUsers+=1;
        totalActiveUsers+=1;
        totalLock+=lockAmount;
        totalActiveLock+=lockAmount;
        // Get tokens
        token.transferFrom(sender,address(this),lockAmount);
        emit Lock(sender,lockAmount,users[sender].unlockDate);
        return _lockAmount;
    }

    function unlock() external returns(uint256 unlockAmount) {
        address sender = _msgSender();
        User memory currentUser = users[sender];
        require(currentUser.lockedAmount > 0, "Tokens are not locked");
        require(!currentUser.isUnlocked, "Tokens have been already unlocked");
        require(currentUser.unlockDate <= block.timestamp, "Lock time is not yet finished");
        
        users[sender].isUnlocked = true;

        // Update Global stats
        totalActiveUsers-=1;
        totalActiveLock-=currentUser.lockedAmount;

        // Send tokens
        token.transfer(sender,currentUser.lockedAmount);
        emit Unlock(sender,currentUser.lockedAmount);
        return currentUser.lockedAmount;
    }
    function drawRandomWinner(uint32 gas, uint16 requestConfirmations) external onlyOwner {
        require(!isGameFinished, "Game is already finished");
        require(totalUsers > 0, "Not enought users");
        isGameFinished = true;
        super.requestRandomness(gas,requestConfirmations,1);

        emit WinnerDrawn();
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) override internal {
        uint32 randomUserId = uint32(_randomWords[0] % totalUsers);
        winner = userIds[randomUserId];
        emit WinnerUpdated(winner,_requestId);
    }

    function updateLockTime(uint256 newTime) external onlyOwner {
        require(totalActiveUsers == 0, "Lock already started");
        require(newTime >= 1 && newTime <= 31_536_000, "Lock cannot last more than 1 year");

        lockTime = newTime;
        emit LockTimeUpdated(newTime);
    }

    function updateToken(address _token) external onlyOwner {
        require(totalActiveUsers == 0, "Lock already started");

        token = IERC20(_token);
        emit TokenUpdated(_token);
    }

    function updateLockAmount(uint256 _lockAmount) external onlyOwner {
        uint256 totalSupply = token.totalSupply();
        require(_lockAmount <= totalSupply/100, "Lock amount too high");
        lockAmount = _lockAmount;
        emit LockAmountUpdated(_lockAmount);
    }

    function getStuckETH(address payable _to) external onlyOwner {
        require(address(this).balance > 0, "There are no ETH in the contract");
        _to.transfer(address(this).balance);
    } 

    function getStuckTokens(address payable _to, address _token, uint256 _amount) external onlyOwner {
        require(IERC20(_token).balanceOf(address(this)) > 0, "No tokens in the contract");
        require(address(token) != _token,"POOPOO cannot be got from the contract");
        IERC20(_token).transfer(_to,_amount);
    }


}