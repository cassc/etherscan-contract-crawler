// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "ConfirmedOwner.sol";
import "Pausable.sol";
import "SafeERC20.sol";
import "IERC20.sol";
import "IERC20Metadata.sol";
import "interfaces.sol";


/**
 * @title veBal fees injector
 * @author 0xtritium.eth
 * @notice Chainlink automation compatible smart contract to handle streaming of fees to veBAL. https://docs.chain.link/chainlink-automation/register-upkeep#register-an-upkeep-using-your-own-deployed-contract
 * @notice Each 2 weeks fees are processed, there is USD and BAL that needs to be dripped into the veBAL fee distributor over 2 weekly injections.
 * @notice This smart contract handles paying in these fees.  It is build such that it receives new funds every 2 weeks after both runs (rendering it empty)
 * @notice New funds should be sent in when Half is true.  Then half will be paid the first run and the rest wll be paid the second run.
 * @notice There are a number of management functions to allow the owner to sweep tokens and/or change how things work.
 */
contract veBalFeeInjector is ConfirmedOwner, Pausable {
  event KeeperRegistryUpdated(address oldAddress, address newAddress);
  event ERC20Swept(address indexed token, address payee, uint256 amount);
  event TokensSet(IERC20[] tokens);
  event FeesPaid(IERC20[] tokens, uint256[] amounts, uint256 timeCurser, bool half);
  event MinAmountSet(uint256 minAmount);
  event HalfFlipped(bool newHalf);

  address public  KeeperRegistry;
  uint256 public LastRunTimeCurser;
  IERC20[] public ManagedTokens;
  bool public Half;
  IFeeDistributor public FeeDistributor;
  bytes constant EmptyBytes = bytes("");
  // to minimize changes after review, using a single minamount of all tokens, next version should support min amounts per tokens
  uint256 public MinAmount;


    /**
   * @param _keeperRegistry The address of the keeper registry contract
   * @param _feeDistributor The address of the veBAL fee distributor
   * @param _tokens A list of tokens to handle.
   */
  constructor(address _keeperRegistry, address _feeDistributor, IERC20[] memory _tokens, uint256 minAmount) ConfirmedOwner(msg.sender)  {
    setKeeperRegistry(_keeperRegistry);
    FeeDistributor = IFeeDistributor(_feeDistributor);
    setTokens(_tokens);
    Half = true; // half on first run
    MinAmount = minAmount;
  }

  /*
   * @notice Get list of addresses that are underfunded and return keeper-compatible payload
   * @param calldata Required by chainlink interface but unused, can set to 0 or anything
   * @return upkeepNeeded signals if upkeep is needed, performData is an abi encoded list of addresses that need injection
   * @return emptyBytes perform data required by chainlink interfaces but unused in this contract
   */
  function checkUpkeep(bytes calldata)
    external
    view
    whenNotPaused
    returns (bool upkeepNeeded, bytes memory performData)
  {
    int counter = 0;
    for(uint i=0; i< ManagedTokens.length; i++){
      if (ManagedTokens[i].balanceOf(address(this)) > MinAmount * 10**(IERC20Metadata(address(ManagedTokens[i])).decimals())){
        counter++;
      }
      if (LastRunTimeCurser >= FeeDistributor.getTimeCursor()) { //Not time yet
        // ensure that counter can never match managedTokens.length if the above is not true
        counter--;
      }
    }
    return (counter == int256(ManagedTokens.length), EmptyBytes);
  }

  /*
   * @notice Injects new veBAL
   * @param performData required by chainlink keeper interface but not used in this contract, can be 0x0 or anything else.
   * @return upkeepNeeded signals if upkeep is needed
   *
   */
  function performUpkeep(bytes calldata performData) external  onlyKeeperRegistry whenNotPaused {
    uint256 timeCursor = FeeDistributor.getTimeCursor();
    require(LastRunTimeCurser < timeCursor, "Not ready");

    uint counter = 0;
    for(uint i=0; i< ManagedTokens.length; i++){
      if (ManagedTokens[i].balanceOf(address(this)) > MinAmount * 10**(IERC20Metadata(address(ManagedTokens[i])).decimals())){
        counter++;
      }
    }
    require(counter == ManagedTokens.length, "Not ready");
    _payFees();
  }

  /*
   * @notice Allows the owner to directly trigger a run.
   *
   */
  function payFees() external onlyOwner whenNotPaused {
    _payFees();
  }

   /*
   * @notice Inject fees into veBAL distributor based on token balances and half, assuming it is past the end of the last epoch.
   *
   */
  function _payFees() internal  {
    uint256 timeCurser = FeeDistributor.getTimeCursor();
    IERC20[] memory tokens = ManagedTokens;
    bool didSomething;
    uint256[] memory amounts = new uint256[](tokens.length);
    uint256 amount;
    for(uint i=0; i<tokens.length; i++){
      if(Half){
        amount = tokens[i].balanceOf(address(this))/2;
      } else {
        amount = tokens[i].balanceOf(address(this));
      }
      if(amount > 0){
        didSomething = true;
        amounts[i] = amount;
      }
    }
    if(didSomething){
      FeeDistributor.depositTokens(ManagedTokens, amounts);
      emit FeesPaid(tokens, amounts, timeCurser, Half);
      Half = !Half;
      LastRunTimeCurser = timeCurser;
    }
  }

  /**
   * @notice Withdraws the contract balance
   * @param amount The amount of eth (in wei) to withdraw
   * @param payee The address to pay
   */
  function withdraw(uint256 amount, address payable payee) external onlyOwner {
    if (payee == address(0)) {
      revert("zero address");
    }
    payee.transfer(amount);
  }
   /**
   * @notice Flips the half bit to be false if true and true if false
   */
    function flipHalf() external onlyOwner {
      Half = !Half;
      emit HalfFlipped(Half);
  }

  /**
   * @notice Sweep the full contract's balance for a given ERC-20 token
   * @param token The ERC-20 token which needs to be swept
   * @param payee The address to pay
   */
  function sweep(address token, address payee) external onlyOwner {
    uint256 balance = IERC20(token).balanceOf(address(this));
    emit ERC20Swept(token, payee, balance);
    SafeERC20.safeTransfer(IERC20(token), payee, balance);
  }


   /**
   * @notice Sets the list of fee tokens to operate on
   * @param tokens the list of addresses to distribute
   */
  function setTokens(IERC20[] memory tokens) public onlyOwner {
    require(tokens.length >= 1, "Must provide at least once token");
    IERC20[] memory oldTokens = ManagedTokens;
    for(uint i=0; i<oldTokens.length; i++){
      SafeERC20.safeApprove(oldTokens[i], address(FeeDistributor), 0);
  }
    emit TokensSet(tokens);
    for(uint i=0; i < tokens.length; i++){
      SafeERC20.safeApprove(tokens[i],address(FeeDistributor), 2**128);
    }
    ManagedTokens = tokens;
  }

  /**
  * @notice Set the global minimum amount that all tokens must have in order for upkeep to run
  * @param minAmount the minimum amount for each token
  * @notice NOTE: this is in whole numbers, it is not adjusted for decimals
  */
  function setMinAmount(uint256 minAmount) public onlyOwner {
    MinAmount = minAmount;
  }

  /*
  * @notice Gets a list of tokens managed/watched by the injector
  */
  function getTokens() public view returns (address[] memory) {
    IERC20[] memory tokens = ManagedTokens;
    address[] memory addresses = new address[](tokens.length);
    for (uint i=0; i< ManagedTokens.length; i++) {
      addresses[i] = address(ManagedTokens[i]);
    }
    return addresses;
  }

  /**
   * @notice Sets the keeper registry address
   */
  function setKeeperRegistry(address _keeperRegistry) public onlyOwner {
    emit KeeperRegistryUpdated(KeeperRegistry, _keeperRegistry);
    KeeperRegistry = _keeperRegistry;
  }

  /**
   * @notice Unpauses the contract
   */
  function unpause() external onlyOwner {
    _unpause();
  }

    /**
   * @notice Pause the contract, preventing any payment of fees into the distributor but still allowing sweeps
   */
   function pause() external onlyOwner {
    _pause();
  }

  modifier onlyKeeperRegistry() {
    if (msg.sender != KeeperRegistry && msg.sender != owner()) {
      require(false, "Only the Registry can do that");
    }
    _;
  }


}