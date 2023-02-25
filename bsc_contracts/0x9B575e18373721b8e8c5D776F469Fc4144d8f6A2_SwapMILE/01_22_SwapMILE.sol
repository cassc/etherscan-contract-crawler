// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./Constants.sol";
import "./interfaces/IContractsRegistry.sol";
import "./interfaces/ISwapMILE.sol";
import "./interfaces/IERC20MintableBurnable.sol";
import "./interfaces/IEntityFactory.sol";
import "./entities/interfaces/IBaseEntity.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/// @title Contract which allows to swap MILE tokens to sMILE tokens by market price.
/// @dev Implements ISwapMILE interface.
contract SwapMILE is ISwapMILE, AccessControlUpgradeable {
  using SafeERC20Upgradeable for IERC20MintableBurnable;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
  using AddressUpgradeable for address payable;

  /// @notice Stores variable for calculation fee, min fee - 10%.
  /// @return Returns 10% of fee.
  uint256 public constant MIN_FEE = 10 ether;

  /// @notice Stores variable for calculation fee, max fee - 40%.
  /// @return Returns 40% of fee.
  uint256 public constant MAX_FEE = 40 ether;

  /// @notice Stores variable for calculation fee, 100% of entered value.
  /// @return Returns 100% of fee.
  uint256 public constant TOTAL = 100 ether;

  /// @notice  Variable to increasing fee calculation accuracy.
  /// @return Returns 1 eth.
  uint256 public constant DIVIDER = 1 ether;

  /// @notice Stores the address of ContractsRegistry contract.
  /// It is used to get addresses of main contracts as(sMILE, MILE, EntityFactory etc.)
  /// @return address of ContractsRegistry contract.
  IContractsRegistry public contractRegistry;

  /// @notice Stores the amount of MILE tokens in the contract.
  /// @return Amount of MILE tokens.
  uint256 public totalPool;

  /// @notice Stores the amount of sMILE tokens in the contract.
  /// @return Amount of sMILE tokens.
  uint256 public sMILEPool;

  /// @notice Stores the cooldownPeriod. After cooldown period user will pay only 10%,
  /// before cooldown period end fee will decrease from 40% -> 10%
  /// @return cooldown period.
  uint256 public cooldownPeriod;

  /// @notice Stores the withdrawPeriod.
  /// After withdraw period user will not be possible to execute withdrawal request.
  /// @return withdraw period.
  uint256 public withdrawPeriod;

  /// @notice Stores the user's created withdrawal requests.
  mapping(uint256 => WithdrawRequest) public withdrawalRequests;

  /// @notice Stores the withdrawl requests.
  /// After withdraw period user will not be possible to execute withdrawal request.
  mapping(address => EnumerableSetUpgradeable.UintSet)
    internal _withdrawalRequestIdsByEntity;

  /// @notice Stors the counter of requests id.
  uint256 internal _requestsCreated;

  /// @notice Stores the withdrawl requests.
  /// After withdraw period user will not be possible to execute withdrawal request.
  mapping(address => uint256) internal _activeRequestedAmountByUser;

  modifier onlyEntity(address entity) {
    if (
      IEntityFactory(
        contractRegistry.getContractByKey(ENTITY_FACTORY_CONTRACT_CODE)
      ).entityRegister(entity) == IEntityFactory.EntityType.None
    ) {
      revert NotEntityAddress();
    }
    _;
  }

  modifier onlyOwnerOfEntity(address entity, address sender) {
    if (!IBaseEntity(entity).isOwner(sender)) {
      revert IncorrectSender();
    }
    _;
  }

  /// @param _admin address of admin;
  /// @param _contractRegistry address of ContractsRegistry contract;
  /// @param _cooldownPeriod value of cooldown period;
  /// @param _withdrawPeriod value of withdraw period.
  function initialize(
    address _admin,
    address _contractRegistry,
    uint256 _cooldownPeriod,
    uint256 _withdrawPeriod
  ) external initializer {
    if (_admin == address(0) || _contractRegistry == address(0)) {
      revert ZeroAddress();
    }
    if (_cooldownPeriod == 0 || _withdrawPeriod == 0) {
      revert ZeroValue();
    }
    if (_withdrawPeriod <= _cooldownPeriod) {
      revert WrongCooldownPeriod();
    }
    __AccessControl_init();
    _setupRole(DEFAULT_ADMIN_ROLE, _admin);

    contractRegistry = IContractsRegistry(_contractRegistry);
    cooldownPeriod = _cooldownPeriod;
    withdrawPeriod = _withdrawPeriod;
  }

  /// @notice Sets new coolDown period.
  /// @param newValue value of new coolDown period.
  function setCoolDownPeriod(uint256 newValue) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    if (newValue == 0) {
      revert ZeroValue();
    }
    if (newValue >= withdrawPeriod) {
      revert WrongCooldownPeriod();
    }
    uint256 oldPeriod = cooldownPeriod;
    cooldownPeriod = newValue;

    emit UpdatedCoolDownPeriod(oldPeriod, cooldownPeriod);
  }

  /// @notice Sets new withdraw period.
  /// @param newValue value of new withdraw period.
  function setWithdrawPeriod(uint256 newValue) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    if (newValue == 0) {
      revert ZeroValue();
    }
    if (newValue <= cooldownPeriod) {
      revert WrongWithdrawPeriod();
    }
    uint256 oldPeriod = withdrawPeriod;
    withdrawPeriod = newValue;

    emit UpdatedWithdrawPeriod(oldPeriod, withdrawPeriod);
  }

  /// @notice Swap amount of MILE tokens to sMILE by market price to entity.
  /// @param entity address of Entity contract.
  /// @param amount amount of MILE tokens to swap.
  /// @param supplyType flag to define way to get mile tokens.
  /// 0 - SenderWallet, mile tokens will be transfered from sender address
  /// 1 - UserEntity, the contract will get address of sender's user entity and transfer tokens from it
  /// 2 - Entity, mile tokens will be transfered from passed entity contract
  function stake(
    address entity,
    uint256 amount,
    TokenSupply supplyType
  )
    external
    override
    onlyEntity(entity)
    onlyOwnerOfEntity(entity, _msgSender())
  {
    _managingTokenSupply(
      contractRegistry.getContractByKey(MILE_CONTRACT_CODE),
      amount,
      entity,
      _msgSender(),
      supplyType
    );
    _stake(_msgSender(), entity, amount);
  }

  /// @notice Swap amount of MILE tokens to sMILE by market price to entity.
  /// @param entity address of Entity contract.
  /// @param to address of recipient of sMILE tokens.
  /// @param amount amount of MILE tokens to swap.
  /// @param supplyType flag to define way to get mile tokens.
  /// 0 - SenderWallet, mile tokens will be transfered from sender address
  /// 1 - UserEntity, the contract will get address of sender's user entity and transfer tokens from it
  /// 2 - Entity, mile tokens will be transfered from passed entity contract
  function stakeTo(
    address entity,
    address to,
    uint256 amount,
    TokenSupply supplyType
  )
    external
    override
    onlyEntity(to)
    onlyEntity(entity)
    onlyOwnerOfEntity(entity, _msgSender())
  {
    _managingTokenSupply(
      contractRegistry.getContractByKey(MILE_CONTRACT_CODE),
      amount,
      entity,
      _msgSender(),
      supplyType
    );
    _stake(_msgSender(), to, amount);
  }

  /// @notice Swap transfered erc20Tokens to MILE tokens by PancakeSwapRouter
  /// contact and stake MILE to Entity contract.
  /// @param entity address of Entity contract.
  /// @param amount amount of MILE tokens to swap.
  /// @param path array of addresses of ERC20 tokens. It will be used by pancakeRouter contract
  /// to convert first token to last token. Last token must be equal to MILE.
  /// @param deadline Timestamp of converting expire time.
  /// @param supplyType flag to define way to get mile tokens.
  /// @param amountOutMin Min amount of MILE tokens which swapMILE will get after converting.
  /// 0 - SenderWallet, mile tokens will be transfered from sender address
  /// 1 - UserEntity, the contract will get address of sender's user entity and transfer tokens from it
  /// 2 - Entity, mile tokens will be transfered from passed entity contract
  function swapStake(
    address entity,
    uint256 amount,
    address[] calldata path,
    uint256 deadline,
    uint256 amountOutMin,
    TokenSupply supplyType
  )
    external
    override
    onlyEntity(entity)
    onlyOwnerOfEntity(entity, _msgSender())
  {
    _managingTokenSupply(path[0], amount, entity, _msgSender(), supplyType);
    _swapStake(_msgSender(), entity, amount, path, deadline, amountOutMin);
  }

  /// @notice Swap transfered erc20Tokens to MILE tokens by PancakeSwapRouter
  /// contact and stake MILE to Entity contract.
  /// @param entity address of Entity contract.
  /// @param amount amount of MILE tokens to swap.
  /// @param path array of addresses of ERC20 tokens. It will be used by pancakeRouter contract
  /// to convert first token to last token. Last token must be equal to MILE.
  /// @param to address of recipient of sMILE tokens.
  /// @param deadline Timestamp of converting expire time.
  /// @param supplyType flag to define way to get mile tokens.
  /// @param amountOutMin Min amount of MILE tokens which swapMILE will get after converting.
  /// 0 - SenderWallet, mile tokens will be transfered from sender address
  /// 1 - UserEntity, the contract will get address of sender's user entity and transfer tokens from it
  /// 2 - Entity, mile tokens will be transfered from passed entity contract
  function swapStakeTo(
    address entity,
    uint256 amount,
    address[] calldata path,
    address to,
    uint256 deadline,
    uint256 amountOutMin,
    TokenSupply supplyType
  )
    external
    override
    onlyEntity(to)
    onlyEntity(entity)
    onlyOwnerOfEntity(entity, _msgSender())
  {
    _managingTokenSupply(path[0], amount, entity, _msgSender(), supplyType);
    _swapStake(_msgSender(), to, amount, path, deadline, amountOutMin);
  }

  /// @notice Creates request for entity, start cooldown period and make possible to withdraw
  /// (Swap sMILE to MILE with rewards) till ending of withdrawPeriod.
  /// @param entity Address of entity contract which will get sMILE tokens.
  /// @param amount Amount of sMILE tokens to swap.
  /// @return Id of the request.
  function requestWithdraw(address entity, uint256 amount)
    external
    override
    onlyEntity(entity)
    onlyOwnerOfEntity(entity, _msgSender())
    returns (uint256)
  {
    if (amount == 0) {
      revert ZeroAmount();
    }
    address sMILEToken = contractRegistry.getContractByKey(SMILE_CONTRACT_CODE);
    if (
      IERC20MintableBurnable(sMILEToken).balanceOf(entity) -
        _activeRequestedAmountByUser[entity] <
      amount
    ) {
      revert NotEnoughSMILEToWithdraw();
    }

    _requestsCreated++;
    uint256 id = _requestsCreated;

    uint256 currentTime = block.timestamp;
    if (!_withdrawalRequestIdsByEntity[entity].add(id)) {
      revert WithdrawalRequestAlreadyExist();
    }
    withdrawalRequests[id] = WithdrawRequest({
      id: id,
      amountOfsMILE: amount,
      creationTimestamp: currentTime,
      coolDownEnd: currentTime + cooldownPeriod,
      withdrawEnd: currentTime + withdrawPeriod
    });
    _activeRequestedAmountByUser[entity] += amount;
    emit CreatedWithdrawRequest(id, entity, amount, currentTime);

    return id;
  }

  /// @notice Withdraw MILE tokens from contract,
  /// swap sMILE to MILE by market price, subtracted fee (10-40%) rewards.
  /// @param entity address of entity contract which was used for creation the withdrawal request.
  /// @param withdrawalId iId of withdrawal request.
  /// @return State of withdraw execution.
  function withdraw(address entity, uint256 withdrawalId)
    external
    override
    onlyEntity(entity)
    onlyOwnerOfEntity(entity, _msgSender())
    returns (bool)
  {
    WithdrawRequest memory request = withdrawalRequests[withdrawalId];
    if (request.amountOfsMILE == 0) {revert WithdrawalRequestNotExist();}
    if (!_withdrawalRequestIdsByEntity[entity].contains(withdrawalId)) {revert WrongEntity();}
    WithdrawCalc memory data;
    data.sMILEToken = contractRegistry.getContractByKey(SMILE_CONTRACT_CODE);
    data.tokenMILE = contractRegistry.getContractByKey(MILE_CONTRACT_CODE);
    data.amountOfMILE = _convertToMILE(request.amountOfsMILE);
    if (request.withdrawEnd <= block.timestamp) {
      _activeRequestedAmountByUser[entity] -= request.amountOfsMILE;
      _deleteRequestWithdraw(entity, withdrawalId);
      emit Withdrawn(withdrawalId, entity, 0, 0, 0, false);
      return false;
    }
    data.fee = _calculateWithdrawFee(
      block.timestamp,
      request.creationTimestamp,
      request.coolDownEnd,
      data.amountOfMILE
    );
    data.toTransfer = data.amountOfMILE - data.fee;
    data.feeToBurn = data.fee - data.fee / 2;
    totalPool = totalPool - data.amountOfMILE + data.fee / 2;
    sMILEPool = sMILEPool - request.amountOfsMILE;
    IERC20MintableBurnable(data.sMILEToken).burnFrom(entity,request.amountOfsMILE);
    IERC20MintableBurnable(data.tokenMILE).burn(data.feeToBurn);
    IERC20MintableBurnable(data.tokenMILE).safeTransfer(entity,data.toTransfer);
    _deleteRequestWithdraw(entity, withdrawalId);
    _activeRequestedAmountByUser[entity] -= request.amountOfsMILE;
    emit Withdrawn(
      withdrawalId,
      entity,
      request.amountOfsMILE,
      data.toTransfer,
      data.fee,
      true
    );
    emit PriceUpdated(_convertToMILE(1 ether), block.timestamp); //SMILE -> MILE, miles per one SMILE
    return true;
  }

  /// @notice Cancel withdraw by update status of the request from "ctive" to "Canceled".
  /// @param entity address of entity contract which was used for creation the withdrawal request.
  /// @param withdrawalId Id of withdrawal request.
  function cancelWithdraw(address entity, uint256 withdrawalId)
    external
    override
    onlyEntity(entity)
    onlyOwnerOfEntity(entity, _msgSender())
  {
    if (withdrawalRequests[withdrawalId].amountOfsMILE == 0) {
      revert WithdrawalRequestNotExist();
    }
    if (!_withdrawalRequestIdsByEntity[entity].contains(withdrawalId)) {
      revert WrongEntity();
    }
    uint256 amountOfsMILE = withdrawalRequests[withdrawalId].amountOfsMILE;
    _deleteRequestWithdraw(entity, withdrawalId);
    _activeRequestedAmountByUser[entity] -= amountOfsMILE;
    emit WithdrawCanceled(withdrawalId, amountOfsMILE, entity);
  }

  /// @notice Transfer MILE tokens from sender to contract and add them to the pool.
  /// without return back.
  /// @param amount Amount of MILE tokrequestWithdrawens to transfer.
  function addRewards(uint256 amount) external override {
    if (amount == 0) {
      revert ZeroAmount();
    }
    IERC20MintableBurnable tokenMILE = IERC20MintableBurnable(
      contractRegistry.getContractByKey(MILE_CONTRACT_CODE)
    );
    totalPool = totalPool + amount;
    tokenMILE.safeTransferFrom(_msgSender(), address(this), amount);
    emit PriceUpdated(_convertToMILE(1 ether), block.timestamp);
    emit AddMILE(_msgSender(), amount);
  }

  /// @notice Transfer amount of sMILE, MILE or BNB to the user address.
  /// @param token Address of token;
  /// @param amount Amount of tokens to send;
  /// @param to Address of recipient.
  function withdrawUnusedFunds(
    address token,
    uint256 amount,
    address to
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (amount == 0) {
      revert ZeroAmount();
    }
    if (to == address(0)) {
      revert ZeroAddress();
    }
    address tokenMILE = contractRegistry.getContractByKey(MILE_CONTRACT_CODE);
    uint256 tokenBalance;
    if (token == address(0)) {
      payable(to).sendValue(amount);
    } else if (token == address(tokenMILE)) {
      tokenBalance = IERC20MintableBurnable(tokenMILE).balanceOf(address(this));
      if (tokenBalance - totalPool < amount) {
        revert NotEnoughMILEToWithdraw();
      }
      IERC20MintableBurnable(tokenMILE).safeTransfer(to, amount);
    } else {
      IERC20MintableBurnable(token).safeTransfer(to, amount);
    }

    emit WithdrawnUnusedFunds(token, amount, to);
  }

  /// @notice Shows amount of sMILE tokens which the entity has requested to withdraw.
  /// @param entity address of entity.
  /// @return amount of sMILE tokens which the entity has requested to withdraw.
  function getRequestedSMILE(address entity) external view returns (uint256) {
    return _activeRequestedAmountByUser[entity];
  }

  /// @notice Shows current MILE price (MILE per sMILE).
  /// @return current MILE price (MILE per sMILE).
  function getMILEPrice() external view override returns (uint256) {
    return _convertToSMILE(1 ether);
  }

  /// @notice Shows current sMILE price (sMILE per MILE).
  /// @return current sMILE price (sMILE per MILE).
  function getSMILEPrice() external view override returns (uint256) {
    return _convertToMILE(1 ether);
  }

  /// @notice Shows amounts of MILE and sMILE tokens in the pool.
  /// @return amounts of MILE and sMILE tokens in the pool.
  function getLiquidityAmount()
    external
    view
    override
    returns (uint256, uint256)
  {
    return (totalPool, sMILEPool);
  }

  /// @notice Shows request ids created by enity.
  /// @param entity address of entity;
  /// @return array of request ids and requests amount.
  function getRequestIdsByEntity(address entity)
    external
    view
    returns (uint256[] memory, uint256)
  {
    return (
      _withdrawalRequestIdsByEntity[entity].values(),
      _withdrawalRequestIdsByEntity[entity].length()
    );
  }

  /// @notice Shows array of entity’s withdrawal requests.
  /// @param entity address of entity;
  /// @param offset number of withdrawal requests to skip;
  /// @param limit number of withdrawal request to return;
  /// @return array of entity’s withdrawal requests and requests amount.
  function getRequestsByEntity(
    address entity,
    uint256 offset,
    uint256 limit
  ) external view returns (WithdrawRequest[] memory, uint256) {
    if (
      _withdrawalRequestIdsByEntity[entity].length() == 0 ||
      _withdrawalRequestIdsByEntity[entity].length() <= offset ||
      limit == 0
    ) {
      return (new WithdrawRequest[](0), 0);
    }
    uint256 arrayLength = _withdrawalRequestIdsByEntity[entity].length();
    uint256 arrayLimit;
    uint256 arraySize;
    if (arrayLength > (offset + limit)) {
      arrayLimit = offset + limit;
      arraySize = limit;
    } else {
      arrayLimit = arrayLength;
      arraySize = arrayLength - offset;
    }
    WithdrawRequest[] memory array = new WithdrawRequest[](arraySize);
    unchecked {
      uint256 j;
      for (uint256 i = offset; i < arrayLimit; i++) {
        uint256 id = _withdrawalRequestIdsByEntity[entity].at(i);
        array[j] = withdrawalRequests[id];
        j++;
      }
    }
    return (array, arrayLength);
  }

  /// @notice Shows amount of sMILE tokens which entity can request to withdraw.
  /// @param entity address of entity.
  /// @return available sMILE tokens for entity.
  function getAvailableSMILEToWithdraw(address entity)
    external
    view
    returns (uint256)
  {
    address sMILEToken = contractRegistry.getContractByKey(SMILE_CONTRACT_CODE);
    uint256 balance = IERC20MintableBurnable(sMILEToken).balanceOf(entity);
    uint256 sum = _activeRequestedAmountByUser[entity];
    if (balance <= sum) {
      return 0;
    }
    return balance - sum;
  }

  /// @notice Shows number of entity’s requests.
  /// @param entity Address of entity;
  /// @return Number of entity’s requests.
  function getRequestAmountByEntity(address entity)
    public
    view
    returns (uint256)
  {
    return _withdrawalRequestIdsByEntity[entity].length();
  }

  function _swapStake(
    address _from,
    address _to,
    uint256 _amount,
    address[] calldata _path,
    uint256 _deadline,
    uint256 _amountOutMin
  ) internal {
    if (_amount == 0) {
      revert ZeroAmount();
    }
    if (_path.length < 2) {
      revert WrongSwapPath();
    }

    if (
      _path[_path.length - 1] !=
      contractRegistry.getContractByKey(MILE_CONTRACT_CODE)
    ) {
      revert WrongTokenAddress();
    }
    address router = contractRegistry.getContractByKey(
      PANCAKE_ROUTER_CONTRACT_CODE
    );
    IERC20MintableBurnable(_path[0]).safeIncreaseAllowance(router, _amount);
    uint256[] memory amounts = IUniswapV2Router02(router)
      .swapExactTokensForTokens(
        _amount,
        _amountOutMin,
        _path,
        address(this),
        _deadline
      );

    _stake(_from, _to, amounts[amounts.length - 1]);
  }

  function _stake(
    address _from,
    address _to,
    uint256 _amountMILE
  ) internal {
    if (_amountMILE == 0) {
      revert ZeroAmount();
    }
    uint256 amountSMILE = _convertToSMILE(_amountMILE);
    totalPool = totalPool + _amountMILE;
    sMILEPool = sMILEPool + amountSMILE;
    address sMILEToken = contractRegistry.getContractByKey(SMILE_CONTRACT_CODE);
    IERC20MintableBurnable(sMILEToken).mint(_to, amountSMILE);
    emit Staked(_from, _to, _amountMILE, amountSMILE);
  }

  function _managingTokenSupply(
    address token,
    uint256 amount,
    address entity,
    address sender,
    TokenSupply supplyType
  ) internal {
    if (supplyType == TokenSupply.SenderWallet) {
      IERC20MintableBurnable(token).safeTransferFrom(
        sender,
        address(this),
        amount
      );
    } else if (supplyType == TokenSupply.UserEntity) {
      address userEntity = IEntityFactory(
        contractRegistry.getContractByKey(ENTITY_FACTORY_CONTRACT_CODE)
      ).ownersOfUserEntity(sender);
      IERC20MintableBurnable(token).safeTransferFrom(
        userEntity,
        address(this),
        amount
      );
    } else {
      IERC20MintableBurnable(token).safeTransferFrom(
        entity,
        address(this),
        amount
      );
    }
  }

  function _deleteRequestWithdraw(address entity, uint256 withdrawalId)
    internal
  {
    delete withdrawalRequests[withdrawalId];
    if (!_withdrawalRequestIdsByEntity[entity].remove(withdrawalId)) {
      revert WithdrawalRequestNotExist();
    }
  }

  function _calculateWithdrawFee(
    uint256 currentTime,
    uint256 creationTimestamp,
    uint256 cooldownEnd,
    uint256 amountOfMILE
  ) internal view returns (uint256 fee) {
    if (currentTime > cooldownEnd) {
      fee = (amountOfMILE * MIN_FEE) / TOTAL;
    } else {
      uint256 percent = (MAX_FEE * DIVIDER) -
        (MAX_FEE - MIN_FEE) *
        (((currentTime - creationTimestamp) * DIVIDER) / cooldownPeriod);
      fee = ((amountOfMILE * percent) / DIVIDER) / TOTAL;
    }
  }

 function _convertToSMILE(uint256 _amount)
    internal
    view
    returns (uint256 sMILE)
  {
    if (totalPool > 0 && sMILEPool > 0) {
      sMILE = (sMILEPool * _amount) / totalPool;
    } else {
      sMILE = _amount;
    }
  }

  function _convertToMILE(uint256 _amount)
    internal
    view
    returns (uint256 mile)
  {
    if (totalPool > 0 && sMILEPool > 0) {
      mile = (totalPool * _amount) / sMILEPool;
    } else {
      mile = _amount;
    }
  }
}