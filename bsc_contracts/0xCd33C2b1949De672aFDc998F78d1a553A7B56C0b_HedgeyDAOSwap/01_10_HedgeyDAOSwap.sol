// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './libraries/TransferHelper.sol';
import './libraries/NFTHelper.sol';

/** @title This contract is specially designed for DAO to DAO swaps
  * The purpose of this is to make it easy for DAO_A with tokenA to swap an exact amount of tokens with DAO_B for tokenB
  * The Swap has an initiator and an executor
  * The initiator is delivering tokenA and amountA in exchange for amountB of tokenB with the executor DAO
  * The initiator sets up the swap parameters, ie tokens to be exchanged, amounts, and other DAO
  * The executor confirms and executes the swap
  * If something is wrong the initiator can cancel the swap anytime unless the executor has already executed it
  * The swaps may lock the tokens or swap them unlocked. If they are locking, the DAOs will utilize the Hedgeys NFT contract
  * to perform the locking of the tokens, which has a single vesting cliff date when the tokens can unlock for each DAO
*/
contract HedgeyDAOSwap is ReentrancyGuard {
  /// @notice id counters to map each struct
  uint256 public swapId;

  /// @notice this is the Swap struct, the definition of a Swap defined by the following
  /// @param tokenA is the address of the tokens that the initiator DAO will be delivering (and executor DAO will receive)
  /// @param tokenB is the address of the tokens that the executor DAO will be deliveriny (and the initiator DAO will receive)
  /// @param amountA is the amount of tokenA that the initiator DAO will deliver (and the amount executor will receive)
  /// @param amountB is the amount of tokenB that the executor DAO will deliver (and the amount the initiator will receive)
  /// @param unlockDate is the block timestamp for when the tokens will unlock. if this is set to 0 or anything in the past the tokens will not be locked upon swap
  /// @param initiator is the initiator DAO address who will initialize the swap and will deliver amountA of tokenA
  /// @param executor is the executor DAO address that will execute the swap and deliver amountB of tokenB
  /// @param nftLocker is an address of the Hedgeys NFT contract that will lock the tokens IF the unlock date is in the future
  struct Swap {
    address tokenA;
    address tokenB;
    uint256 amountA;
    uint256 amountB;
    uint256 unlockDate;
    address initiator;
    address executor;
    address nftLocker;
  }

  /// @notice mapping of the swapIDs to the struct Swap - made public so the executor can confirm accuracy of swap prior to execution
  mapping(uint256 => Swap) public swaps;

  /// @notice event of the new swap being initialized
  event NewSwap(
    uint256 indexed id,
    address tokenA,
    address tokenB,
    uint256 amountA,
    uint256 amountB,
    uint256 unlockDate,
    address indexed initiator,
    address indexed executor,
    address nftLocker
  );
  /// @notice event of when a swap is executed and completed
  event SwapExecuted(uint256 indexed id);

  /// @notice event of when a swap has been cancelled
  event SwapCancelled(uint256 indexed id);

  /// @notice function to initialize the swap - with all of the parameters
  /// @dev the DAO performing this function automatically becomes the initiator DAO
  /// @param tokenA is the token address that the DAO calling this function will be delivering. 
  /// ...The initiator needs to ensure sufficient allowance has been set for tokenA of amountA with this contract
  /// ... as the amountA of tokenA will be pulled into this contract to be held until execution or cancellation
  /// @param tokenB is the token address of the DAO that will exexute the swap
  /// @param amountA is the amount of tokenA that will be swapped and will be pulled into this contract to be held until execution
  /// @param amountB is the amount of tokenB that will be swapped - it is transferred during the execution step & function
  /// @param unlockDate is the date in which tokens will be unlocked, denominated as block timestamp.
  /// ... if the tokens are not to be locked, then the initiator should just use 0 for this parameter
  /// @param executor is the executor DAO address - only the executor address will be able to execute this swap
  /// @param nftLocker IF the tokens are to be locked, this is the address of the Hedgeys NFTs that will lock the tokens
  /// @dev for more information on the correct address for the Hedgey NFTs pls visit the github repo readme at https://github.com/hedgey-finance/NFT_OTC_Core
  /// @dev this function will emit the New Swap event, and then create a Swap struct held in storage - mapped to the next index swapId
  function initSwap(
    address tokenA,
    address tokenB,
    uint256 amountA,
    uint256 amountB,
    uint256 unlockDate,
    address executor,
    address nftLocker
  ) external nonReentrant {
    require(tokenA != address(0x0) && tokenB != address(0x0), "token address issue");
    require(executor != address(0x0), "executor cannot be zero address");
    require(amountA > 0 && amountB > 0, "amounts cannot be 0");
    if(unlockDate > block.timestamp) require(nftLocker != address(0x0), "nft locker cannot be zero");
    TransferHelper.transferTokens(tokenA, msg.sender, address(this), amountA);
    emit NewSwap(swapId, tokenA, tokenB, amountA, amountB, unlockDate, msg.sender, executor, nftLocker);
    swaps[swapId++] = Swap(tokenA, tokenB, amountA, amountB, unlockDate, msg.sender, executor, nftLocker);
  }

  /// @notice this is the function that actually executes the swap
  /// @param _swapId is the swapId that is mapped to the specific Swap struct in storage
  /// @dev only the Executor DAO of the swap can call this function
  /// @dev for security the Swap struct in storage is immediately deleted so it cannot be executed twice
  /// @dev The swap is executed where amountA of tokenA is delivered to the Executor DAO
  /// ... and amountB of tokenB is delivered to the Initiator DAO
  /// ... if the swap requires the tokens to be locked, then amountB of tokenB will be pulled into this address first
  /// ... and then amountB of tokenB will be locked in an NFT minted to Initiator DAO
  /// ... and then amountA of tokenA will be locked in an NFT minted to the Executor DAO
  /// @dev this function emits a SwapExecuted event for tracking the swap
  function executeSwap(uint256 _swapId) external nonReentrant {
    Swap memory swap = swaps[_swapId];
    require(msg.sender == swap.executor, "only executor");
    delete swaps[_swapId];
    if (swap.unlockDate > block.timestamp) {
      TransferHelper.transferTokens(swap.tokenB, swap.executor, address(this), swap.amountB);
      NFTHelper.lockTokens(swap.nftLocker, swap.initiator, swap.tokenB, swap.amountB, swap.unlockDate);
      NFTHelper.lockTokens(swap.nftLocker, swap.executor, swap.tokenA, swap.amountA, swap.unlockDate);
    } else {
      TransferHelper.transferTokens(swap.tokenB, swap.executor, swap.initiator, swap.amountB);
      TransferHelper.withdrawTokens(swap.tokenA, swap.executor, swap.amountA);
    }
    emit SwapExecuted(_swapId);
  }

  /// @notice this function will cancel a swap that has been initiated but not executed yet
  /// @param _swapId is the swapId that is mapped to the specific Swap struct stored in storage
  /// @dev only the initiator of the swap can call this function
  /// @dev this function will delete the Swap stored in storage
  ///... and then withdraw the amountA of tokenA back to the initiator
  /// @dev this function emits a SwapCancelled event
  function cancelSwap(uint256 _swapId) external nonReentrant {
    Swap memory swap = swaps[_swapId];
    require(msg.sender == swap.initiator, "only initiator");
    delete swaps[_swapId];
    TransferHelper.withdrawTokens(swap.tokenA, swap.initiator, swap.amountA);
    emit SwapCancelled(_swapId);
  }
}