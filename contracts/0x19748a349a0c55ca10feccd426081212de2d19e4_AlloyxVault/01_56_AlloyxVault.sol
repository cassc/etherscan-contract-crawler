// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../config/ConfigHelper.sol";
import "../config/AlloyxConfig.sol";
import "../interfaces/IAlloyxVault.sol";
import "../interfaces/IAlloyxVaultToken.sol";

/**
 * @title AlloyxVault
 * @notice Alloyx Vault holds the logic for stakers and investors to interact with different protocols
 * @author AlloyX
 */
contract AlloyxVault is IAlloyxVault, AdminUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using ConfigHelper for AlloyxConfig;
  using SafeMath for uint256;

  uint256 internal constant DURA_MANTISSA = uint256(10)**uint256(18);
  uint256 internal constant USDC_MANTISSA = uint256(10)**uint256(6);
  uint256 internal constant ONE_YEAR_IN_SECONDS = 365.25 days;

  bool internal locked;
  uint256 totalAlyxClaimable;
  uint256 snapshotIdForLiquidation;
  uint256 preTotalUsdcValue;
  uint256 preTotalInvestorUsdcValue;
  uint256 prePermanentStakerGain;
  uint256 preRegularStakerGain;
  uint256 lastProtocolFeeTimestamp;

  State public state;
  AlloyxConfig public config;
  IAlloyxVaultToken public vaultToken;
  Component[] public components;

  // snapshot=>(investor=>claimed)
  mapping(uint256 => mapping(address => bool)) internal hasClaimedLiquidationCompensation;

  event AlloyxConfigUpdated(address indexed who, address configAddress);
  event SetComponent(address indexed creatorAddress, address poolAddress, uint256 proportion, uint256 tranche, Source source);
  event SetState(State _state);

  /**
   * @notice Ensure there is no reentrant
   */
  modifier nonReentrant() {
    require(!locked);
    locked = true;
    _;
    locked = false;
  }

  /**
   * @notice If user operation is paused
   */
  modifier isPaused() {
    require(config.isPaused(), "operations paused");
    _;
  }

  /**
   * @notice If operation is not paused
   */
  modifier notPaused() {
    require(!config.isPaused(), "pause first");
    _;
  }

  /**
   * @notice If address is whitelisted
   */
  modifier isWhitelisted() {
    require(config.getWhitelist().isUserWhitelisted(msg.sender), "not whitelisted");
    _;
  }

  /**
   * @notice If the vault is at the right state
   */
  modifier atState(State _state) {
    require(state == _state, "wrong state");
    _;
  }

  /**
   * @notice If the transaction is triggered from manager contract
   */
  modifier onlyManager() {
    require(msg.sender == config.managerAddress(), "only manager");
    _;
  }

  /**
   * @notice Initialize the contract
   * @param _configAddress the address of configuration contract
   * @param _vaultTokenAddress the address of vault token contract
   */
  function initialize(address _configAddress, address _vaultTokenAddress) external initializer {
    __AdminUpgradeable_init(msg.sender);
    config = AlloyxConfig(_configAddress);
    vaultToken = IAlloyxVaultToken(_vaultTokenAddress);
  }

  /**
   * @notice Set the state of the vault
   * @param _state the state of the contract
   */
  function setState(State _state) internal {
    state = _state;
    emit SetState(_state);
  }

  /**
   * @notice Get address of the vault token
   */
  function getTokenAddress() external view override returns (address) {
    return address(vaultToken);
  }

  /**
   * @notice Check if the vault is at certain state
   * @param _state the state to check
   */
  function isAtState(State _state) internal view returns (bool) {
    return state == _state;
  }

  /**
   * @notice Update configuration contract address
   */
  function updateConfig() external onlyAdmin isPaused {
    config = AlloyxConfig(config.configAddress());
    emit AlloyxConfigUpdated(msg.sender, address(config));
  }

  /**
   * @notice Start the vault by setting up the portfolio of the vault and initial depositors' info
   * @param _components the initial setup of the portfolio for this vault
   * @param _usdcDepositorArray the array of DepositAmount containing the amount and address of the USDC depositors
   * @param _alyxDepositorArray the array of DepositAmount containing the amount and address of the ALYX depositors
   * @param _totalUsdc total amount of USDC to start the vault with
   */
  function startVault(
    Component[] calldata _components,
    DepositAmount[] memory _usdcDepositorArray,
    DepositAmount[] memory _alyxDepositorArray,
    uint256 _totalUsdc
  ) external override onlyManager atState(State.INIT) {
    for (uint256 i = 0; i < _usdcDepositorArray.length; i++) {
      vaultToken.mint(usdcToAlloyxDura(_usdcDepositorArray[i].amount), _usdcDepositorArray[i].depositor);
    }

    for (uint256 i = 0; i < _alyxDepositorArray.length; i++) {
      permanentlyStake(_alyxDepositorArray[i].depositor, _alyxDepositorArray[i].amount);
    }

    preTotalInvestorUsdcValue = _totalUsdc;
    preTotalUsdcValue = _totalUsdc;
    lastProtocolFeeTimestamp = block.timestamp;

    setComponents(_components);
    setState(State.STARTED);
  }

  /**
   * @notice Reinstate governance called by manager contract only
   * @param _alyxDepositorArray the array of DepositAmount containing the amount and address of the ALYX depositors
   */
  function reinstateGovernance(DepositAmount[] memory _alyxDepositorArray) external override onlyManager atState(State.NON_GOVERNANCE) {
    for (uint256 i = 0; i < _alyxDepositorArray.length; i++) {
      permanentlyStake(_alyxDepositorArray[i].depositor, _alyxDepositorArray[i].amount);
    }
    setState(State.STARTED);
  }

  /**
   * @notice Accrue the protocol fee by minting vault tokens to the treasury
   */
  function accrueProtocolFee() external override onlyManager {
    uint256 totalSupply = vaultToken.totalSupply();
    uint256 timeSinceLastFee = block.timestamp.sub(lastProtocolFeeTimestamp);
    uint256 totalTokenToMint = totalSupply.mul(timeSinceLastFee).mul(config.getInflationPerYearForProtocolFee()).div(10000).div(ONE_YEAR_IN_SECONDS);
    vaultToken.mint(totalTokenToMint, config.treasuryAddress());
    lastProtocolFeeTimestamp = block.timestamp;
  }

  /**
   * @notice Stake certain amount of ALYX as permanent staker, this can only be called internally during starting vault or reinstating governance
   */
  function permanentlyStake(address _account, uint256 _amount) internal {
    config.getStakeDesk().addPermanentStakeInfo(_account, _amount);
  }

  /**
   * @notice Stake certain amount of ALYX as regular staker, user needs to approve ALYX before calling this
   */
  function stake(uint256 _amount) external isWhitelisted notPaused nonReentrant {
    _transferERC20From(msg.sender, config.alyxAddress(), address(this), _amount);
    config.getStakeDesk().addRegularStakeInfo(msg.sender, _amount);
  }

  /**
   * @notice Unstake certain amount of ALYX as regular staker, user needs to approve ALYX before calling this
   */
  function unstake(uint256 _amount) external isWhitelisted notPaused nonReentrant {
    config.getStakeDesk().subRegularStakeInfo(msg.sender, _amount);
    _transferERC20(config.alyxAddress(), msg.sender, _amount);
  }

  /**
   * @notice Claim the available USDC and update the checkpoints
   */
  function claim() external isWhitelisted notPaused nonReentrant {
    updateUsdcValuesAndGains(0, 0);
    (uint256 regularGain, uint256 permanentGain) = claimable();
    _transferERC20(config.usdcAddress(), msg.sender, regularGain.add(permanentGain));
    preRegularStakerGain = preRegularStakerGain.sub(regularGain);
    prePermanentStakerGain = prePermanentStakerGain.sub(permanentGain);
    preTotalInvestorUsdcValue = preTotalInvestorUsdcValue.sub(regularGain.add(permanentGain));
    preTotalUsdcValue = preTotalUsdcValue.sub(regularGain.add(permanentGain));
    config.getStakeDesk().clearStakeInfoAfterClaiming(msg.sender);
  }

  /**
   * @notice Claimable USDC for ALYX stakers
   * @return the claimable USDC for regular staked ALYX
   * @return the claimable USDC for permanent staked ALYX
   */
  function claimable() public view returns (uint256, uint256) {
    uint256 totalRegularGain = getRegularStakerGainInVault();
    uint256 totalPermanentGain = getPermanentStakerGainInVault();
    uint256 regularGain = config.getStakeDesk().getRegularStakerProrataGain(msg.sender, totalRegularGain);
    uint256 permanentGain = config.getStakeDesk().getPermanentStakerProrataGain(msg.sender, totalPermanentGain);
    return (regularGain, permanentGain);
  }

  /**
   * @notice Liquidate the vault by unstaking from all permanent and regular stakers and burn all the governance tokens issued
   */
  function liquidate() external override onlyManager atState(State.STARTED) {
    config.getStakeDesk().unstakeAllStakersAndBurnAllGovTokens();
    totalAlyxClaimable = config.getAlyx().balanceOf(address(this));
    snapshotIdForLiquidation = vaultToken.snapshot();
    setState(State.NON_GOVERNANCE);
  }

  /**
   * @notice Claim liquidation compensation by user who has active investment at the time of liquidation
   */
  function claimLiquidationCompensation() external notPaused {
    require(snapshotIdForLiquidation > 0, "invalid snapshot id");
    uint256 balance = vaultToken.balanceOfAt(msg.sender, snapshotIdForLiquidation);
    require(balance > 0, "no balance at liquidation");
    require(!hasClaimedLiquidationCompensation[snapshotIdForLiquidation][msg.sender], "already claimed");
    uint256 supply = vaultToken.totalSupplyAt(snapshotIdForLiquidation);
    uint256 reward = totalAlyxClaimable.mul(balance).div(supply);
    _transferERC20(config.alyxAddress(), msg.sender, reward);
    hasClaimedLiquidationCompensation[snapshotIdForLiquidation][msg.sender] = true;
  }

  /**
   * @notice Update the internal checkpoint of total asset value, asset value for investors, the gains for permanent and regular stakers, and protocol fee
   * @param _increaseAmount the increase of amount for USDC by deposit
   * @param _decreaseAmount the decrease of amount for USDC by withdrawal
   */
  function updateUsdcValuesAndGains(uint256 _increaseAmount, uint256 _decreaseAmount) internal {
    (uint256 totalInvestorUsdcValue, uint256 permanentStakerGain, uint256 regularStakerGain) = getTotalInvestorUsdcValueAndAdditionalGains();
    preTotalUsdcValue = config.getOperator().getTotalBalanceInUsdc(address(this)).add(_increaseAmount).sub(_decreaseAmount);
    preTotalInvestorUsdcValue = totalInvestorUsdcValue.add(_increaseAmount).sub(_decreaseAmount);
    prePermanentStakerGain = prePermanentStakerGain.add(permanentStakerGain);
    preRegularStakerGain = preRegularStakerGain.add(regularStakerGain);
  }

  /**
   * @notice A Liquidity Provider can deposit USDC for Alloy Tokens
   * @param _tokenAmount Number of stable coin
   */
  function deposit(uint256 _tokenAmount) external isWhitelisted notPaused nonReentrant {
    uint256 amountToMint = usdcToAlloyxDura(_tokenAmount);
    updateUsdcValuesAndGains(_tokenAmount, 0);
    _transferERC20From(msg.sender, config.usdcAddress(), address(this), _tokenAmount);
    vaultToken.mint(amountToMint, msg.sender);
  }

  /**
   * @notice An Alloy token holder can deposit their tokens and redeem them for USDC
   * @param _tokenAmount Number of Alloy Tokens
   */
  function withdraw(uint256 _tokenAmount) external override isWhitelisted notPaused nonReentrant {
    uint256 amountToWithdraw = alloyxDuraToUsdc(_tokenAmount);
    vaultToken.burn(_tokenAmount, msg.sender);
    updateUsdcValuesAndGains(0, amountToWithdraw);
    _transferERC20(config.usdcAddress(), msg.sender, amountToWithdraw);
  }

  /**
   * @notice Rebalance the vault by performing deposits to different third party protocols based on the proportion defined
   */
  function rebalance() external onlyAdmin {
    updateUsdcValuesAndGains(0, 0);
    uint256 usdcValue = config.getUSDC().balanceOf(address(this));
    require(usdcValue > preRegularStakerGain.add(prePermanentStakerGain), "not enough usdc");
    uint256 amountToInvest = usdcValue.sub(preRegularStakerGain).sub(prePermanentStakerGain);
    for (uint256 i = 0; i < components.length; i++) {
      uint256 additionalInvestment = config.getOperator().getAdditionalDepositAmount(
        components[i].source,
        components[i].poolAddress,
        components[i].tranche,
        components[i].proportion,
        preTotalInvestorUsdcValue
      );
      if (additionalInvestment > 0 && amountToInvest > 0) {
        if (additionalInvestment > amountToInvest) {
          additionalInvestment = amountToInvest;
        }
        performDeposit(components[i].source, components[i].poolAddress, components[i].tranche, additionalInvestment);
        amountToInvest = amountToInvest.sub(additionalInvestment);
        if (amountToInvest == 0) {
          break;
        }
      }
    }
  }

  /**
   * @notice Get the total investor value aka the vault asset value, the additional gain from the last checkpoint for protocol, permanent staker, regular staker
   * @return the total investor value aka the vault asset value
   * @return the additional gain from last checkpoint for permanent stakers
   * @return the additional gain from last checkpoint for regular stakers
   */
  function getTotalInvestorUsdcValueAndAdditionalGains()
    private
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 totalValue = config.getOperator().getTotalBalanceInUsdc(address(this));
    if (totalValue > preTotalUsdcValue) {
      uint256 interest = totalValue.sub(preTotalUsdcValue);
      uint256 permanentStakerGain = config.getPermanentStakerProportion().mul(interest).div(10000);
      uint256 regularStakerGain = config.getRegularStakerProportion().mul(interest).div(10000);
      uint256 investorGain = interest.sub(permanentStakerGain).sub(regularStakerGain);
      uint256 totalInvestorUsdcValue = investorGain.add(preTotalInvestorUsdcValue);
      return (totalInvestorUsdcValue, permanentStakerGain, regularStakerGain);
    } else {
      uint256 loss = preTotalUsdcValue.sub(totalValue);
      uint256 totalInvestorUsdcValue = preTotalInvestorUsdcValue.sub(loss);
      return (totalInvestorUsdcValue, 0, 0);
    }
  }

  /**
   * @notice Get the USDC value of the total supply of DURA in this Vault
   */
  function getTotalUsdcValueForDuraInVault() public view returns (uint256) {
    (uint256 totalInvestorValue, , ) = getTotalInvestorUsdcValueAndAdditionalGains();
    return totalInvestorValue;
  }

  /**
   * @notice Get total the regular staker gain
   */
  function getRegularStakerGainInVault() public view returns (uint256) {
    (, , uint256 regularStakerGain) = getTotalInvestorUsdcValueAndAdditionalGains();
    return regularStakerGain.add(preRegularStakerGain);
  }

  /**
   * @notice Get total the permanent staker gain
   */
  function getPermanentStakerGainInVault() public view returns (uint256) {
    (, uint256 permanentStakerGain, ) = getTotalInvestorUsdcValueAndAdditionalGains();
    return permanentStakerGain.add(prePermanentStakerGain);
  }

  /**
   * @notice Set components of the vault
   * @param _components the components of this vault, including the address of the vault to invest
   */
  function setComponents(Component[] memory _components) public {
    require(msg.sender == config.managerAddress() || isAdmin(msg.sender), "only manager or admin");
    uint256 sumOfProportion = 0;
    for (uint256 i = 0; i < _components.length; i++) {
      sumOfProportion += _components[i].proportion;
    }
    require(sumOfProportion == 10000, "not equal to 100%");
    delete components;
    for (uint256 i = 0; i < _components.length; i++) {
      components.push(Component(_components[i].proportion, _components[i].poolAddress, _components[i].tranche, _components[i].source));
      emit SetComponent(msg.sender, _components[i].poolAddress, _components[i].proportion, _components[i].tranche, _components[i].source);
    }
  }

  function getComponents() public view returns (Component[] memory) {
    return components;
  }

  /**
   * @notice Transfer certain amount token of certain address to some other account
   * @param _account the address to transfer
   * @param _tokenId the token ID to transfer
   * @param _tokenAddress the token address to transfer
   */
  function transferERC721(
    address _tokenAddress,
    address _account,
    uint256 _tokenId
  ) public onlyAdmin {
    IERC721(_tokenAddress).safeTransferFrom(address(this), _account, _tokenId);
  }

  /**
   * @notice Migrate certain ERC20 to an address
   * @param _tokenAddress the token address to migrate
   * @param _to the address to transfer tokens to
   */
  function migrateERC20(address _tokenAddress, address _to) external onlyAdmin {
    uint256 balance = IERC20Upgradeable(_tokenAddress).balanceOf(address(this));
    IERC20Upgradeable(_tokenAddress).safeTransfer(_to, balance);
  }

  /**
   * @notice Convert USDC Amount to Alloyx DURA
   * @param _amount the amount of usdc to convert to DURA token
   */
  function usdcToAlloyxDura(uint256 _amount) public view returns (uint256) {
    if (isAtState(State.INIT)) {
      return _amount.mul(DURA_MANTISSA).div(USDC_MANTISSA);
    }
    return _amount.mul(vaultToken.totalSupply()).div(getTotalUsdcValueForDuraInVault());
  }

  /**
   * @notice Convert Alloyx DURA to USDC amount
   * @param _amount the amount of DURA token to convert to usdc
   */
  function alloyxDuraToUsdc(uint256 _amount) public view returns (uint256) {
    if (isAtState(State.INIT)) {
      return _amount.mul(USDC_MANTISSA).div(DURA_MANTISSA);
    }
    return _amount.mul(getTotalUsdcValueForDuraInVault()).div(vaultToken.totalSupply());
  }

  /**
   * @notice Perform deposit operation to different source
   * @param _source the source of the third party protocol
   * @param _poolAddress the pool address of the third party protocol
   * @param _tranche the tranche to deposit
   * @param _amount the amount to deposit
   */
  function performDeposit(
    Source _source,
    address _poolAddress,
    uint256 _tranche,
    uint256 _amount
  ) public onlyAdmin nonReentrant {
    _transferERC20(config.usdcAddress(), config.operatorAddress(), _amount);
    config.getOperator().performDeposit(_source, _poolAddress, _tranche, _amount);
  }

  /**
   * @notice Perform withdrawal operation for different source
   * @param _source the source of the third party protocol
   * @param _poolAddress the pool address of the third party protocol
   * @param _tokenId the token ID
   * @param _amount the amount to withdraw
   */
  function performWithdraw(
    Source _source,
    address _poolAddress,
    uint256 _tokenId,
    uint256 _amount,
    WithdrawalStep _step
  ) public onlyAdmin nonReentrant {
    config.getOperator().performWithdraw(_source, _poolAddress, _tokenId, _amount, _step);
  }

  /**
   * @notice Transfer certain amount token of certain address to some other account
   * @param _account the address to transfer
   * @param _amount the amount to transfer
   * @param _tokenAddress the token address to transfer
   */
  function _transferERC20(
    address _tokenAddress,
    address _account,
    uint256 _amount
  ) internal {
    IERC20Upgradeable(_tokenAddress).safeTransfer(_account, _amount);
  }

  /**
   * @notice Transfer certain amount token of certain address to some other account
   * @param _from the address to transfer from
   * @param _account the address to transfer
   * @param _amount the amount to transfer
   * @param _tokenAddress the token address to transfer
   */
  function _transferERC20From(
    address _from,
    address _tokenAddress,
    address _account,
    uint256 _amount
  ) internal {
    IERC20Upgradeable(_tokenAddress).safeTransferFrom(_from, _account, _amount);
  }
}