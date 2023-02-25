// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface ISwapMILE {
  /// @dev Throws if user pass zero address.
  error ZeroAddress();

  /// @dev Throws if user pass zero value,
  /// in cases when set up values: cooldownPeriod, withdrawPeriod
  error ZeroValue();

  /// @dev Throws if user pass zero amount of tokens.
  error ZeroAmount();

  /// @dev Throws if user pass not entity contract address.
  error NotEntityAddress();

  /// @dev Throws if user isn't owner of passed entity contract.
  error IncorrectSender();

  /// @dev Throws if user try withdraw or cancel withdraw request
  /// and pass entity address which haven't requested withdraw.
  error WrongEntity();

  /// @dev Throws if owner set up incorrect value of cooldownPeriod.
  error WrongCooldownPeriod();

  /// @dev Throws if owner set up incorrect value of withdrawPeriod.
  error WrongWithdrawPeriod();

  /// @dev Throws when user request withdraw but
  /// deosn't have enogth sMILE tokens to swap.
  error NotEnoughSMILEToWithdraw();

  /// @dev Throws when admin try to withdraw MILE tokens from SwapMIE
  /// but SwapMILE doesn't have enogth tokens or
  /// all tokens belongs to swap pool
  error NotEnoughMILEToWithdraw();

  /// @dev Throws when user try to withdraw by nonexistent withdraw request
  /// or cancel nonexistent withdraw request
  error WithdrawalRequestNotExist();

  /// @dev Throws when user try to add already existing withdrw request
  error WithdrawalRequestAlreadyExist();

  /// @dev Throws when user pass swap path
  /// there last token doesn't equal to MILE token
  error WrongTokenAddress();

  /// @dev Throws when user pass swap path which has length less than 2
  error WrongSwapPath();

  /// @dev Enum which containes all ways of tranfering tokens
  enum TokenSupply {
    SenderWallet,
    UserEntity,
    Entity
  }

  /// @dev structure for describing withdraw request
  /// @param id id of request
  /// @param amountOfsMILE amount of sMILE tokens to swap
  /// @param creationTimestamp timestamp of creating the request
  /// @param coolDownEnd timestamp of ending cooldown period
  /// @param withdrawEnd timestamp of ending withdraw period
  struct WithdrawRequest {
    uint256 id;
    uint256 amountOfsMILE;
    uint256 creationTimestamp;
    uint256 coolDownEnd;
    uint256 withdrawEnd;
  }

  /// @dev structure to fix "Stak to deep" error in function "withdraw"
  /// @param amountOfMILE amount of MILE tokens after converting from sMILE
  /// @param fee total fee
  /// @param feeToBurn amount of fee to burn
  /// @param toTransfer amount of MILE token to transfer
  /// @param sMILEToken address of sMILE token
  /// @param tokenMILE address of MILE token
  struct WithdrawCalc {
    uint256 amountOfMILE;
    uint256 fee;
    uint256 feeToBurn;
    uint256 toTransfer;
    address sMILEToken;
    address tokenMILE;
  }

  /// @dev Emitted when user stake MILE tokens to SwapMILE
  /// @param caller address of user which call functions stake...
  /// @param recipient address of entity contract which get sMILE tokens
  /// @param stakedMILE amount of stake MILE tokens
  /// @param swappedSMILE amount of swapped sMILE tokens to recipient
  event Staked(
    address indexed caller,
    address indexed recipient,
    uint256 stakedMILE,
    uint256 swappedSMILE
  );

  /// @dev Emitted when user create withdraw request
  /// @param withdrawalId id of withdraw request
  /// @param recipient address of entity contract which get MILE tokens
  /// @param amountOfsMILE amount of sMILE tokens to swap
  /// @param timestampOfCreation timestamp of creation withdraw request
  event CreatedWithdrawRequest(
    uint256 indexed withdrawalId,
    address recipient,
    uint256 amountOfsMILE,
    uint256 timestampOfCreation
  );

  /// @dev Emitted when user withdraw MILE tokens(swap sMILE->MILE)
  /// @param withdrawalId id of withdraw request
  /// @param recipient address of entity contract which get MILE tokens
  /// @param amountOfsMILE amount of sMILE tokens
  /// @param amountOfMILE amount of MILE tokens
  /// @param fee fee of withdraw
  /// @param success status of withdraw
  event Withdrawn(
    uint256 indexed withdrawalId,
    address recipient,
    uint256 amountOfsMILE,
    uint256 amountOfMILE,
    uint256 fee,
    bool success
  );

  /// @dev Emitted when user cancel withdraw request
  /// @param withdrawalId id of withdraw request
  /// @param amountOfsMILE amount of sMILE tokens
  /// @param recipient address of entity contract which get MILE tokens
  event WithdrawCanceled(
    uint256 indexed withdrawalId,
    uint256 amountOfsMILE,
    address recipient
  );

  /// @dev Emitted when user add MILE tokens to swap pool
  /// @param sender sender of MILE tokens
  /// @param amount amount of MILE tokens
  event AddMILE(address sender, uint256 amount);

  /// @dev Emitted when damin withdraw tokens/eth
  /// @param token address of swapped token
  /// @param amount amount of tokens
  /// @param recipient address of tokens recipient
  event WithdrawnUnusedFunds(address token, uint256 amount, address recipient);

  /// @dev Emitted when admin set up new cooldownPeriod value
  /// @param oldPeriod old value of cooldownPeriod
  /// @param newPeriod new value of cooldownPeriod
  event UpdatedCoolDownPeriod(uint256 oldPeriod, uint256 newPeriod);

  /// @dev Emitted when admin set up new withdrawPeriod value
  /// @param oldPeriod old value of withdrawPeriod
  /// @param newPeriod new value of withdrawPeriod
  event UpdatedWithdrawPeriod(uint256 oldPeriod, uint256 newPeriod);

  /// @dev Emitted when price between sMILE and MILE change
  /// @param smilePrice new price of sMILE token to MILE token
  /// @param timestamp timestamp of price update
  event PriceUpdated(uint256 smilePrice, uint256 timestamp);

  /// @dev Sets new coolDown period.
  /// @param newValue value of new coolDown period.
  function setCoolDownPeriod(uint256 newValue) external;

  /// @dev Sets new withdraw period.
  /// @param newValue value of new withdraw period.
  function setWithdrawPeriod(uint256 newValue) external;

  /// @dev Shows current MILE price (MILE per sMILE).
  /// @return current MILE price (MILE per sMILE).
  function getMILEPrice() external returns (uint256);

  /// @dev Shows current sMILE price (sMILE per MILE).
  /// @return current sMILE price (sMILE per MILE).
  function getSMILEPrice() external returns (uint256);

  /// @dev Shows amounts of MILE and sMILE tokens in the pool.
  /// @return amounts of MILE and sMILE tokens in the pool.
  function getLiquidityAmount() external returns (uint256, uint256);

  /// @dev Swap amount of MILE tokens to sMILE by market price to entity.
  /// @param entity address of Entity contract.
  /// @param amount amount of MILE tokens to swap.
  /// @param supplyType flag to define way to get mile tokens.
  function stake(
    address entity,
    uint256 amount,
    TokenSupply supplyType
  ) external;

  /// @dev Swap amount of MILE tokens to sMILE by market price to entity.
  /// @param entity address of Entity contract.
  /// @param to address of recipient of sMILE tokens.
  /// @param amount amount of MILE tokens to swap.
  /// @param supplyType flag to define way to get mile tokens.
  function stakeTo(
    address entity,
    address to,
    uint256 amount,
    TokenSupply supplyType
  ) external;

  /// @dev Swap transfered erc20Tokens to MILE tokens by PancakeSwapRouter
  /// contact and stake MILE to Entity contract.
  /// @param entity address of Entity contract.
  /// @param amount amount of MILE tokens to swap.
  /// @param path array of addresses of ERC20 tokens. It will be used by pancakeRouter contract
  /// to convert first token to last token. Last token must be equal to MILE.
  /// @param deadline Timestamp of converting expire time.
  /// @param supplyType flag to define way to get mile tokens.
  /// @param amountOutMin Min amount of MILE tokens which swapMILE will get after converting.
  function swapStake(
    address entity,
    uint256 amount,
    address[] calldata path,
    uint256 deadline,
    uint256 amountOutMin,
    TokenSupply supplyType
  ) external;

  /// @dev Swap transfered erc20Tokens to MILE tokens by PancakeSwapRouter
  /// contact and stake MILE to Entity contract.
  /// @param entity address of Entity contract.
  /// @param amount amount of MILE tokens to swap.
  /// @param path array of addresses of ERC20 tokens. It will be used by pancakeRouter contract
  /// to convert first token to last token. Last token must be equal to MILE.
  /// @param to address of recipient of sMILE tokens.
  /// @param deadline Timestamp of converting expire time.
  /// @param supplyType flag to define way to get mile tokens.
  /// @param amountOutMin Min amount of MILE tokens which swapMILE will get after converting.
  function swapStakeTo(
    address entity,
    uint256 amount,
    address[] calldata path,
    address to,
    uint256 deadline,
    uint256 amountOutMin,
    TokenSupply supplyType
  ) external;

  /// @dev Shows number of entity’s requests.
  /// @param entity Address of entity;
  /// @return Number of entity’s requests.
  function getRequestAmountByEntity(address entity) external returns (uint256);

  /// @dev Shows request ids created by enity.
  /// @param entity address of entity;
  /// @return array of request ids and requests amount.
  function getRequestIdsByEntity(address entity)
    external
    returns (uint256[] memory, uint256);

  /// @dev Shows array of entity’s withdrawal requests.
  /// @param entity address of entity;
  /// @param offset number of withdrawal requests to skip;
  /// @param limit number of withdrawal request to return;
  /// @return array of entity’s withdrawal requests and requests amount.
  function getRequestsByEntity(
    address entity,
    uint256 offset,
    uint256 limit
  ) external returns (WithdrawRequest[] memory, uint256);

  /// @dev Shows amount of sMILE tokens which entity can request to withdraw.
  /// @param entity address of entity.
  /// @return available sMILE tokens for entity.
  function getAvailableSMILEToWithdraw(address entity)
    external
    returns (uint256);

  /// @dev Shows amount of sMILE tokens which the entity has requested to withdraw.
  /// @param entity address of entity.
  /// @return amount of sMILE tokens which the entity has requested to withdraw.
  function getRequestedSMILE(address entity) external returns (uint256);

  /// @dev Creates request for entity, start cooldown period and make possible to withdraw
  /// (Swap sMILE to MILE with rewards) till ending of withdrawPeriod.
  /// @param entity Address of entity contract which will get sMILE tokens.
  /// @param amount Amount of sMILE tokens to swap.
  /// @return Id of the request.
  function requestWithdraw(address entity, uint256 amount)
    external
    returns (uint256);

  /// @dev Withdraw MILE tokens from contract,
  /// swap sMILE to MILE by market price, subtracted fee (10-40%) rewards.
  /// @param entity address of entity contract which was used for creation the withdrawal request.
  /// @param withdrawalId iId of withdrawal request.
  /// @return State of withdraw execution.
  function withdraw(address entity, uint256 withdrawalId)
    external
    returns (bool);

  /// @dev Cancel withdraw by update status of the request from "ctive" to "Canceled".
  /// @param entity address of entity contract which was used for creation the withdrawal request.
  /// @param withdrawalId Id of withdrawal request.
  function cancelWithdraw(address entity, uint256 withdrawalId) external;

  /// @dev Transfer MILE tokens from sender to contract and add them to the pool.
  /// without return back.
  /// @param amount Amount of MILE tokrequestWithdrawens to transfer.
  function addRewards(uint256 amount) external;

  /// @dev Transfer amount of sMILE, MILE or BNB to the user address.
  /// @param token Address of token;
  /// @param amount Amount of tokens to send;
  /// @param to Address of recipient.
  function withdrawUnusedFunds(
    address token,
    uint256 amount,
    address to
  ) external;
}