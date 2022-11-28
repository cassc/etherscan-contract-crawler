// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ILendingPool} from './external/aave/ILendingPool.sol';
import {FlashLoanReceiverBase} from "./external/aave/FlashLoanReceiverBase.sol";
import {ILendingPool} from './external/aave/ILendingPool.sol';
import {ILendingPoolAddressesProvider} from './external/aave/ILendingPoolAddressesProvider.sol';
import {IProtocolDataProvider} from './external/aave/IProtocolDataProvider.sol';
import {ICurvePool} from './external/curve/ICurvePool.sol';
import {IPriceOracle} from './external/babylon/IPriceOracle.sol';
import {IWETH} from './external/weth/IWETH.sol';

import {ISwapRouter} from 'v3-periphery/interfaces/ISwapRouter.sol';
import {IUniswapV3Factory} from 'v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import {TransferHelper} from 'v3-periphery/libraries/TransferHelper.sol';
import {IUniswapV3Pool} from 'v3-core/contracts/interfaces/IUniswapV3Pool.sol';

import {AutomationCompatibleInterface} from "chainlink/contracts/src/v0.8/AutomationCompatible.sol";

import {IERC20} from 'openzeppelin-contracts/token/ERC20/IERC20.sol';
import {Pausable} from 'openzeppelin-contracts/security/Pausable.sol';
import {ERC20} from 'openzeppelin-contracts/token/ERC20/ERC20.sol';
import {SafeERC20} from 'openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol';
import {SafeDecimalMath} from './lib/SafeDecimalMath.sol';
import {ReentrancyGuard} from 'openzeppelin-contracts/security/ReentrancyGuard.sol';
import {PreciseUnitMath} from './lib/PreciseUnitMath.sol';
import {ISupa} from './ISupa.sol';

import "forge-std/console2.sol";
// import {ERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';

contract Supa is ERC20, FlashLoanReceiverBase, AutomationCompatibleInterface, Pausable, ReentrancyGuard, ISupa {
  using PreciseUnitMath for uint256;
  using SafeDecimalMath for uint256;
  using SafeERC20 for ERC20;

  /* ============ Events ============ */

  event Deposit(
      address indexed _sender,
      address indexed _owner,
      uint256 _assets,
      uint256 _shares
  );

  event Withdraw(
      address indexed _sender,
      address indexed _receiver,
      address indexed _owner,
      uint256 _assets,
      uint256 _shares
  );

  event Unwind(
      uint256 _daiRepaid,
      uint256 _wethRepaid,
      uint256 _healthFactor
  );

  event Leverage(
      uint256 _daiCapital,
      uint256 _healthFactor
  );

  event Rebalance(
      bool _reduceShort,
      uint256 _wethToRebalance,
      uint256 _healthFactor
  );

  /* ============ Constants ============ */

  // Uniswap
  uint24 private constant FEE_LOW = 500;
  uint24 private constant FEE_MEDIUM = 3000;
  uint24 private constant FEE_HIGH = 10000;
  uint256 private constant DEFAULT_TRADE_SLIPPAGE = 25e15; // 2.5%
  IUniswapV3Factory internal constant factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

  // Price Oracle (from Babylon)
  address private constant PRICE_ORACLE = 0x9f194E8341a99df8eC254637862D719650033A2f;

  // AAVE
  ILendingPool constant lendingPool = ILendingPool(address(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9)); // Mainnet
  IProtocolDataProvider constant dataProvider =
      IProtocolDataProvider(address(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d)); // Mainnet

  // Wrapped ETH address
  IWETH private constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  ERC20 private constant DAI = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  IERC20 private constant stETH = IERC20(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
  IERC20 private constant astETH = IERC20(0x1982b2F5814301d4e9a8b0201555376e62F82428);

  // Supa settings
  uint256 private constant MIN_CONTRIBUTION = 500e18;
  uint256 private constant MAX_DEPOSIT = 5e22;
  uint256 private constant MAX_TOTAL_DEPOSITS = 1e24;
  uint256 private constant MIN_CAPITAL_POSITION = 1e22;

  uint256 private constant LONG_LEVERAGE_FACTOR = 7e17; // 70%
  uint256 private constant SHORT_LEVERAGE_FACTOR = 7e17; // 70%

  uint256 private constant LONG_PERCENTAGE = 5e17; // 50%
  uint256 private constant SHORT_PERCENTAGE = 5e17; // 50%
  uint256 private constant MIN_HEALTH_FACTOR = 12e17; // Min 1.2
  uint256 private constant MEDIUM_HEALTH_FACTOR = 13e17; // Medium 1.3
  uint256 private constant MAX_HEALTH_FACTOR = 14e17; // MAX 1.4

  /* ============ State Variables ============ */

  address public override owner; // owner of this smart contract
  address public override feeRecipient; // Address that receives the profit % fee
  uint256 public override fee; // % in 1e18
  uint256 public override currentDeposits; // total deposits minus withdrawals in DAI
  mapping(address => uint256) public override lastDepositAt;
  uint8 public override longLeverageTimes;
  uint8 public override shortLeverageTimes;
  bool private reduceShort = false; // variable for flashloans

  /* ============ Constructor ============ */

  constructor(address _owner, address _feeRecipient) ERC20("Supa Vault", "SUPA") Pausable() FlashLoanReceiverBase(ILendingPoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5)) {
    owner = _owner;
    feeRecipient = _feeRecipient;
    // Fee disabled
    fee = 0;
  }

  /* ============ Modifiers ============ */

  function _onlyOwner() private view {
      require(msg.sender == owner, 'Only owner');
  }

  /* ============ External Functions ============ */

  /**
   * Underlying needs to be approved by the sender.
   * @notice This function deposits assets of underlying tokens into the vault and grants ownership of shares to receiver.
   * @param _assets Units of the underlying asset to deposit
   * @param _receiver Address to receive the shares of the vault. Usually the sender
   * @return _shares Shares emitted to the receiver
   */
  function deposit(uint256 _assets, address _receiver) external nonReentrant whenNotPaused returns (uint256 _shares) {
      _shares = _internalDeposit(_assets, _receiver);
  }

  /**
   * Underlying needs to be approved by the sender.
   * @notice This function mints exactly shares vault shares to receiver by depositing assets of underlying tokens.
   * @param _shares Units of the underlying asset to receive
   * @param _receiver Address to receive the shares of the vault. Usually the sender
   * @return _assets Shares of the underlying asset taken from the depositor
   */
  function mint(uint256 _shares, address _receiver) external nonReentrant whenNotPaused returns (uint256 _assets) {
      _assets = convertToAssets(_shares);
      _internalDeposit(_assets, _receiver);
  }

  /**
   * @notice This function burns shares from owner and send exactly assets token from the vault to receiver.
   * @param _assets Units of the underlying asset to withdraw
   * @param _receiver Address to receive the underlying asset. Usually the sender
   * @param _owner Address that owns the token shares. Usually the sender
   * @return _shares Vault shares burned
   */
  function withdraw(uint256 _assets, address _receiver, address _owner) external nonReentrant whenNotPaused returns (uint256 _shares) {
      _shares = convertToShares(_assets);
      _internalWithdraw(_shares, _receiver, _owner);
  }

  /**
   * @notice This function redeems a specific number of shares from owner and send assets of underlying token from the vault to receiver.
   * @param _shares Units of the underlying asset to withdraw
   * @param _receiver Address to receive the underlying assets. Usually the sender
   * @param _owner Address that owns the token shares. Usually the sender
   * @return _assets Units of the underlying assets returned
   */
  function redeem(uint256 _shares, address _receiver, address _owner) external nonReentrant whenNotPaused returns (uint256 _assets) {
      _assets = _internalWithdraw(_shares, _receiver, _owner);
  }

  /**
   * @notice This function leverages the long and short position
   */
  function leverage() public nonReentrant whenNotPaused {
      require(_liquidReserve() > MIN_CAPITAL_POSITION, 'Not enough liquid reserve');
      uint256 amountAvailable = _liquidReserve();
      if (longLeverageTimes > 0) {
          _createLeverageLongStETh(shortLeverageTimes > 0 ? amountAvailable.preciseMul(LONG_PERCENTAGE) : amountAvailable, longLeverageTimes);
      }
      if (shortLeverageTimes > 0) {
          _createLeverageShortETH(longLeverageTimes > 0 ? amountAvailable.preciseMul(SHORT_PERCENTAGE): amountAvailable, shortLeverageTimes);
      }
      (,uint256 healthFactor,) = getAaveAccountStatus();
      require(healthFactor >= MIN_HEALTH_FACTOR, "Health factor too low");
      emit Leverage(amountAvailable, healthFactor);
  }

  /**
   * @notice This function rebalances the position between the short and the long
   */
  function rebalance() public nonReentrant whenNotPaused {
    // Given that the mode is 0, we are paying back the premium
      (,uint256 healthFactor, uint256 netPosition) = getAaveAccountStatus();
      // Owner can skip the check
      require(msg.sender == owner || healthFactor < MIN_HEALTH_FACTOR || healthFactor > MAX_HEALTH_FACTOR, "Health factor in range");
      require(getBorrowBalance(address(DAI)) == 0, "DAI debt needs to be repaid");
      // check aave eth borrow balance
      // check aave steth balance
      uint256 stETHDeposit = astETH.balanceOf(address(this));
      // Only count the borrowings used for shorting. only 70% of stETH is used for borrowing
      uint256 wethBorrowDebt = getBorrowBalance(address(WETH)) - (stETHDeposit.preciseMul(7e17));
      uint256 netWethPos = netPosition.preciseMul(IPriceOracle(PRICE_ORACLE).getPrice(address(DAI), address(WETH)));
      // get the diff in ETH, rebalance half that amount between long and short
      uint256 difference = netWethPos > wethBorrowDebt ? (netWethPos - wethBorrowDebt) : wethBorrowDebt - netWethPos;
      require(difference >= 3e17, "No diff to rebalance");

      // Flashloan
      address[] memory assets = new address[](1);
      assets[0] = address(WETH);

      uint256[] memory amounts = new uint256[](1);
      amounts[0] = difference / 2;

      // 0 = no debt, 1 = stable, 2 = variable
      uint256[] memory modes = new uint256[](1);
      modes[0] = 0;

      bytes memory params = "";
      uint16 referralCode = 0;
      reduceShort = netWethPos < wethBorrowDebt;
      lendingPool.flashLoan(
          address(this), // receiver address
          assets,
          amounts,
          modes,
          address(this), // onBehalfOf
          params,
          referralCode
      );
  }

  /**
   * This function unwinds the net position in AAVE to match net deposits
   * @notice There needs to be at least a difference of $10k
   */
  function unwind() public nonReentrant whenNotPaused {
      (,,uint256 netPosition) = getAaveAccountStatus();
      // Check net position vs current deposits and unwind if needed
      uint256 netDAIDifference = netPosition >= currentDeposits ? netPosition - currentDeposits : 0;
      uint256 borrowDAI = getBorrowBalance(address(DAI));
      uint256 wethTraded = 0;
      require(netDAIDifference >= MIN_CAPITAL_POSITION || borrowDAI >= 1e21, "Nothing to unwind");
      // Withdraw DAI
      lendingPool.withdraw(address(DAI), netDAIDifference + borrowDAI, address(this));
      if (borrowDAI > 0) {
          // Pay debt first
          DAI.approve(address(lendingPool), borrowDAI);
          lendingPool.repay(address(DAI), borrowDAI, 2, address(this));
      }
      if (netDAIDifference >= MIN_CAPITAL_POSITION) {
          // Reduce net position with the rest
          wethTraded = _trade(address(DAI), address(WETH), netDAIDifference);
          // Repay debt with collateral to reduce net position
          WETH.approve(address(lendingPool), wethTraded);
          lendingPool.repay(address(WETH), wethTraded, 2, address(this));
      }
      (,uint256 healthFactor,) = getAaveAccountStatus();
      require(healthFactor >= MIN_HEALTH_FACTOR, "Health factor too low");
      emit Unwind(borrowDAI, wethTraded, healthFactor);
  }

  /**
   * This function checks if there is any work needed to be performed by keepers
   * @return upkeepNeeded Whether work needs to be performed
   * @return performData Encoded data that contains the id of the op to perform
   */
  function checkUpkeep(
      bytes calldata /* checkData */
  )
      external
      view
      override
      returns (bool upkeepNeeded, bytes memory performData)
  {
      uint256 operation = 0;
      (,uint256 healthFactor,uint256 netPosition) = getAaveAccountStatus();
      if (netPosition > 0) {
        // Check net position vs current deposits and unwind if needed
        uint256 netDAIDifference = netPosition > currentDeposits ? netPosition - currentDeposits : 0;
        uint256 borrowDAI = getBorrowBalance(address(DAI));
        if (netDAIDifference >= MIN_CAPITAL_POSITION || borrowDAI >= 1e21) {
            // Unwind
            operation = 2;
        } else {
            if (healthFactor < MIN_HEALTH_FACTOR || healthFactor > MAX_HEALTH_FACTOR) {
                // Rebalance
                operation = 3;
            }
        }
      }
      // Add to position in instadapp if enough liquid reserve
      if (operation == 0 && _liquidReserve() >= MIN_CAPITAL_POSITION) {
          // Leverage
          operation = 1;
      }
      return (operation > 0, abi.encodePacked(operation));
  }

  /**
   * This function performs the work according to the operation passed in bytes
   * @param _performData Data that contains the uint8 with the operation to perform
   */
  function performUpkeep(bytes calldata _performData) external nonReentrant whenNotPaused override {
      uint256 operation = abi.decode(_performData, (uint256));
      require(operation >= 1 && operation <= 3, 'Incorrect operation');
      if (operation == 1) {
          leverage();
      } else if (operation == 2) {
          unwind();
      } else if (operation == 3) {
          rebalance();
      }
  }

  /* ============ Privileged State Functions ============ */

  /**
   * @dev Returns to paused state.
   * Requirements:
   * - The contract must not be paused.
   * - Caller must be the owner
   */
  function pause() external {
      _onlyOwner();
      _pause();
  }

  /**
   * @dev Returns to normal state.
   * Requirements:
   * - The contract must be paused.
   * - Caller must be the owner
   */
  function unpause() external {
      _onlyOwner();
      _unpause();
  }

  /**
   * @notice This function sets the fee and fee recipient. Only owner can change it.
   * @param _fee Fee of profits to be sent to recipient. 1e18 = 100%
   * @param _feeRecipient Address to receive the fee
   */
  function setFee(uint256 _fee, address _feeRecipient) external nonReentrant {
      _onlyOwner();
      require(_fee >= 0 && _fee <= 1e17, 'Fee <= than 10%');
      require(feeRecipient != address(0), 'No Fee recipient');
      feeRecipient = _feeRecipient;
      fee = _fee;
  }

  /**
   * @notice This function sets the leverage configuration
   * @param _longLeverageTimes How many times to loop the long
   * @param _shortLeverageTimes How many times to loop the short
   */
  function setLeverageConfig(uint8 _longLeverageTimes, uint8 _shortLeverageTimes) external nonReentrant {
      _onlyOwner();
      require(_longLeverageTimes >= 0 && _longLeverageTimes <= 9, 'LLong out of bounds');
      require(_shortLeverageTimes >= 0 && _shortLeverageTimes <= 9, 'LShort out of bounds');
      longLeverageTimes = _longLeverageTimes;
      shortLeverageTimes = _shortLeverageTimes;
  }

  /**
    Flashloan Callback AAVE.
    This function is called after your contract has received the flash loaned amount
   */
  function executeOperation(
      address[] calldata /* assets */,
      uint256[] calldata amounts,
      uint256[] calldata premiums,
      address initiator,
      bytes calldata /* params */
  )
      external
      override
      returns (bool)
  {
      require(initiator == address(this), 'Only this contract');
      // We got our ETH flashloan
      if (reduceShort) {
        // Swap WETH to stETH on curve
        _swapWETHToStETH(amounts[0]);
        uint swapped = stETH.balanceOf(address(this));
        stETH.approve(address(lendingPool), swapped);
        // Deposit the stETH as collateral
        lendingPool.deposit(address(stETH), swapped, address(this), 0);
        // Get the DAI collateral out with flashloan premium, swap to ETH to repay flashloan
        uint DAItoWithdraw = amounts[0].preciseMul(IPriceOracle(PRICE_ORACLE).getPrice(address(WETH), address(DAI))).preciseMul(101e16);
        lendingPool.withdraw(address(DAI), DAItoWithdraw, address(this));
        // Swap DAI to WETH
        _trade(address(DAI), address(WETH), DAI.balanceOf(address(this)));
      } else {
        // Swap eth amount to repay to DAI and deposit as collateral
        // Swap WETH into DAI and add it as collateral
        uint256 newDAI = _trade(address(WETH), address(DAI), amounts[0]);
        DAI.approve(address(lendingPool), newDAI);
        lendingPool.deposit(address(DAI), newDAI, address(this), 0);
        // Borrow WETH to pay back loan plus premium
        lendingPool.borrow(address(WETH), amounts[0] + premiums[0], 2, 0, address(this));
      }

      // Given that the mode is 0, we are paying back the premium
      (,uint256 healthFactor,) = getAaveAccountStatus();
      // Approve to repay the debt + premium
      WETH.approve(address(lendingPool), amounts[0] + premiums[0]);
      require(healthFactor >= MIN_HEALTH_FACTOR && healthFactor <= MAX_HEALTH_FACTOR, "Health factor out of range");
      emit Rebalance(reduceShort, amounts[0], healthFactor);
      return true;
  }

  /* ============ External View Functions ============ */

  /**
   * @notice This function returns the amount of underlying returned per 1e18 share
   * @return uint256 Amount of underlying per share
   */
  function pricePerShare() public view returns (uint256) {
      if (totalSupply() == 0) {
        return 1e18;
      }
      // Liquid reserve + net position
      (,,uint256 netPosition) = getAaveAccountStatus();
      return (_liquidReserve() + netPosition).preciseDiv(totalSupply());
  }

  /**
   * @notice This function returns the total amount of underlying assets held by the vault.
   * @return uint256 Total number of AUM
   */
  function totalAssets() public view returns (uint256) {
      return totalSupply().preciseMul(pricePerShare());
  }

  /**
   * @notice This function returns the address of the underlying token used for the vault for accounting, depositing, withdrawing.
   * @return address Vault underlying asset
   */
  function asset() external pure returns (address) {
      return address(DAI);
  }

  /**
   * @notice This function returns the amount of shares that would be exchanged by the vault for the amount of assets provided.
   * @param _assets Number of units of the underlying to be converted to shares at the current price
   * @return _shares Number of shares to receive
   */
  function convertToShares(uint256 _assets) public view returns (uint256 _shares) {
      return _assets.preciseDiv(10**DAI.decimals()).preciseDiv(pricePerShare());
  }

  /**
  * @notice
  * This function returns the amount of assets that would be exchanged by the vault for the amount of shares provided.
  * @param _shares Number of shares to be exchanged to units of the underlying assets
  * @return _assets Number of units of the underlying asset that match the shares
  */
  function convertToAssets(uint256 _shares) public view returns (uint256 _assets) {
      return _shares.preciseMul(pricePerShare()).preciseMul(10**DAI.decimals());
  }

  /**
   * @notice This function returns the maximum amount of underlying assets that can be deposited in a single deposit call by the receiver.
   * hparam _receiver Depositor
   * @return uint256 Max amount of underlying assets to deposit
  */
  function maxDeposit(address /* _receiver */) external pure returns (uint256) {
      return MAX_DEPOSIT;
  }

  /**
   * @notice This function allows users to simulate the effects of their deposit at the current block.
   * @param _assets Number of units of the underlying to deposit
   * @return uint256 Amount of shares to be received upon deposit
  */
  function previewDeposit(uint256 _assets) external view returns (uint256) {
      return convertToShares(_assets);
  }

  /**
   * @notice This function returns the maximum amount of shares that can be minted in a single mint call by the receiver.
   * hparam _receiver Receiver address
   * @return uint256 Max amount of shares that can be minted
   */
  function maxMint(address /* _receiver */) external view returns (uint256) {
      return convertToShares(MAX_DEPOSIT);
  }

  /**
   * @notice This function allows users to simulate the effects of their mint at the current block.
   * @param _shares Shares to mint
   * @return uint256 Amount of underlying assets to receive
   */
  function previewMint(uint256 _shares) external view returns (uint256) {
      return convertToAssets(_shares);
  }

  /**
   * @notice This function returns the maximum amount of underlying assets that can be withdrawn from the owner balance with a single withdraw call.
   * hparam _owner Owner of the ERC-20 tokens
   * @return uint256 underlying assets to receive
  */
  function maxWithdraw(address /* _owner */) external view returns (uint256) {
      return convertToAssets(balanceOf(msg.sender));
  }

  /**
   * @notice This function allows users to simulate the effects of their withdrawal at the current block.
   * @param _assets Number of underlying assets to withdraw
   * @return uint256 shares to burn
  */
  function previewWithdraw(uint256 _assets) external view returns (uint256) {
      return convertToShares(_assets);
  }

  /**
   * @notice This function returns the maximum amount of shares that can be redeem from the owner balance through a redeem call.
   * @param _owner Owner of the vault token shares
   * @return uint256 Returns the max amount of shares that can be redeemed
   */
  function maxRedeem(address _owner) external view returns (uint256) {
      return convertToShares(balanceOf(_owner));
  }

  /**
   * @notice This function allows users to simulate the effects of their redeemption at the current block.
   * @param _shares Shares to redeem
   * @return uint256 Number of underlying assets to receive
   */
  function previewRedeem(uint256 _shares) external view returns (uint256) {
      return convertToAssets(_shares);
  }

  /**
   * More info https://docs.aave.com/developers/v/2.0/the-core-protocol/lendingpool#getuseraccountdata
   * Returns the status of the position. The keeper acts based on this information
   * @return bool Whether the position needs to be acted upon
   * @return uint256 Health factor of the account
   * @return uint256 Net value of the position in DAI
   */
  function getAaveAccountStatus() public view override returns (bool, uint256, uint256) {
      (
          uint256 totalCollateral,
          uint256 totalDebt,
          , // uint256 borrowingPower
          , // uint256 liquidationThreshold
          , // uint256 ltv
          uint256 healthFactor
      ) = lendingPool.getUserAccountData(address(this));
      uint256 wethIntoDAI = IPriceOracle(PRICE_ORACLE).getPrice(address(WETH), address(DAI));
      return (healthFactor < MIN_HEALTH_FACTOR, healthFactor, (totalCollateral - totalDebt).preciseMul(wethIntoDAI));
  }

  /**
   * Get the amount of borrowed debt that needs to be repaid
   * @param _asset   The underlying asset
   */
  function getBorrowBalance(address _asset) public view override returns (uint256) {
      (, uint256 currentStableDebt, uint256 currentVariableDebt, , , , , , ) =
          dataProvider.getUserReserveData(_asset, address(this));
      // Account for both stable and variable debt
      return currentStableDebt + currentVariableDebt;
  }

  /* ============ Private Functions ============ */

  // Returns the amount of DAI readily available in this smart contract
  function _liquidReserve() private view returns (uint256) {
      return DAI.balanceOf(address(this));
  }

  /**
   * Underlying needs to be approved by the sender.
   * @notice This function deposits assets of underlying tokens into the vault and grants ownership of shares to receiver.
   * @param _assets Units of the underlying asset to receive
   * @param _receiver Address to receive the shares of the vault. Usually the sender
   * @return _shares Shares emitted to the receiver
   */
  function _internalDeposit(uint256 _assets, address _receiver) private returns (uint256 _shares) {
      require(_assets >= MIN_CONTRIBUTION && _assets <= MAX_DEPOSIT, "Contrib too small");
      require((totalAssets() + _assets) <= MAX_TOTAL_DEPOSITS, "Exceed total max deposits");
      // Calculate reserve balance before deposit
      uint256 reserveAssetBalanceBefore = DAI.balanceOf(address(this));
      _shares = convertToShares(_assets);
      // Transfer DAI to the vault
      DAI.safeTransferFrom(msg.sender, address(this), _assets);
      // Make sure we received the correct amount of reserve asset
      require(
          (DAI.balanceOf(address(this)) - reserveAssetBalanceBefore) == _assets,
          "Assets do not match"
      );

      // make sure contributor gets desired amount of shares
      require(_shares > 0, "Receiver shares");

      // mint shares
      _mint(_receiver, _shares);

      lastDepositAt[_receiver] = block.timestamp;
      currentDeposits += _assets;

      // Emit Deposit event
      emit Deposit(msg.sender, _receiver, _assets, _shares);
  }

  function _internalWithdraw(uint256 _shares, address _receiver, address _owner) private returns (uint256 _assets) {
      uint256 prevBalance = balanceOf(_owner);

      require(prevBalance >= _shares && prevBalance > 0, "Not enough shares");
      // Flashloan protection
      require((block.timestamp - lastDepositAt[_owner]) > 0, "No flashloans");

      _assets = convertToAssets(_shares);

      if (_liquidReserve() < _assets) {
        // Borrow to satisfy the withdrawal. We'll repay it in unwind
        lendingPool.borrow(address(DAI), _assets - _liquidReserve(), 2, 0, address(this));
        (,uint256 healthFactor,) = getAaveAccountStatus();
        require(healthFactor >= MIN_HEALTH_FACTOR, "Health factor too low");
      }
      require(_liquidReserve() >= _assets, "There is not enough liquidity");

      _burn(_receiver, _shares);

      if (fee > 0) {
          // If fee > 0 pay fee
          DAI.safeTransfer(feeRecipient, _assets.preciseMul(fee));
      }

      // Send reserve asset
      DAI.safeTransfer(_receiver, _assets - _assets.preciseMul(fee));

      currentDeposits -= _assets;
      // Withdrawal event
      emit Withdraw(msg.sender, _receiver, _owner, _assets, _shares);
  }

  function _createLeverageLongStETh(uint256 _DAIAmount, uint8 _leverageTimes) private {
      require(_leverageTimes >= 1 && _leverageTimes <= 9, "Wrong leverage");
      // Aprove AAVE lending pool to take our stETH
      stETH.approve(address(lendingPool), 2**256 - 1);
      // Swap DAI amount for WETH on uniswap
      _trade(address(DAI), address(WETH), _DAIAmount);
      // Swap WETH to stETH on curve
      _swapWETHToStETH(WETH.balanceOf(address(this)));
      // Deposit the stETH as collateral
      uint lastDepositAmount = stETH.balanceOf(address(this));
      lendingPool.deposit(address(stETH), lastDepositAmount, address(this), 0);

      for (uint i = 0; i < _leverageTimes; i++) {
          // Borrow WETH
          lendingPool.borrow(address(WETH), lastDepositAmount.preciseMul(LONG_LEVERAGE_FACTOR), 2, 0, address(this));
          // Swap WETH to stETH on curve
          _swapWETHToStETH(WETH.balanceOf(address(this)));
          // Deposit the stETH as collateral
          lastDepositAmount = stETH.balanceOf(address(this));
          lendingPool.deposit(address(stETH), lastDepositAmount, address(this), 0);
      }

      // Revoke approve
      stETH.approve(address(lendingPool), 0);
  }

  function _createLeverageShortETH(uint256 _DAIAmount, uint8 _leverageTimes) private {
    // Aprove AAVE lending pool to take our DAI
    require(_leverageTimes >= 1 && _leverageTimes <= 12, "Wrong leverage");
    DAI.approve(address(lendingPool), 2**256 - 1);

    // Get the price of WETH
    uint256 pricePerWETH = IPriceOracle(PRICE_ORACLE).getPrice(address(DAI), address(WETH));

    // Deposit the DAI as collateral
    lendingPool.deposit(address(DAI), _DAIAmount, address(this), 0);
    uint256 depositAmount = _DAIAmount;
    // Leverage short x times
    for (uint i = 0; i < _leverageTimes; i++) {
        // Borrow WETH
        lendingPool.borrow(address(WETH), depositAmount.preciseMul(pricePerWETH).preciseMul(SHORT_LEVERAGE_FACTOR), 2, 0, address(this));
        // Sell WETH for DAI deposit DAI
        depositAmount = _trade(address(WETH), address(DAI), WETH.balanceOf(address(this)));
        lendingPool.deposit(address(DAI), depositAmount, address(this), 0);
    }

    //Revoke approve
    DAI.approve(address(lendingPool), 0);
  }

  /**
   * @notice Updates deposit time when transferring tokens
   * @param _from           Address of the contributor sending tokens
   * @param _to             Address of the contributor receiving tokens
   * @param _amount         Amount to send
   */
  function _beforeTokenTransfer(
      address _from,
      address _to,
      uint256 _amount
  ) internal virtual override {
      super._beforeTokenTransfer(_from, _to, _amount);
      if (lastDepositAt[_from] > lastDepositAt[_to]) {
        lastDepositAt[_to] = lastDepositAt[_from];
      }
      if (_amount == balanceOf(_from)) {
        lastDepositAt[_from] = 0;
      }
  }

  /* ============ Private DeFi Aux Functions ============ */

  /**
   * Trades _tokenIn to _tokenOut using Uniswap V3
   *
   * @param _tokenIn             Token that is sold
   * @param _tokenOut            Token that is purchased
   * @param _amount              Amount of tokenin to sell
   */
  function _trade(
      address _tokenIn,
      address _tokenOut,
      uint256 _amount
  ) private returns (uint256) {
      if (_tokenIn == _tokenOut) {
          return _amount;
      }
      // Uses on chain oracle for all internal strategy operations to avoid attacks
      uint256 pricePerTokenUnit = IPriceOracle(PRICE_ORACLE).getPrice(_tokenIn, _tokenOut);
      require(pricePerTokenUnit != 0, "No price");

      // minAmount must have receive token decimals
      uint256 exactAmount =
          SafeDecimalMath.normalizeAmountTokens(_tokenIn, _tokenOut, _amount.preciseMul(pricePerTokenUnit));
      uint256 minAmountOut = exactAmount - exactAmount.preciseMul(DEFAULT_TRADE_SLIPPAGE);

      return _trade(_tokenIn, _tokenOut, _amount, minAmountOut, address(0));
  }

  /**
   * Trades _tokenIn to _tokenOut using Uniswap V3
   *
   * @param _tokenIn             Token that is sold
   * @param _tokenOut            Token that is purchased
   * @param _amount              Amount of tokenin to sell
   * @param _minAmountOut        Min amount of tokens out to recive
   * @param _hopToken            Hop token to use for UniV3 trade
   */
  function _trade(
      address _tokenIn,
      address _tokenOut,
      uint256 _amount,
      uint256 _minAmountOut,
      address _hopToken
  ) private returns (uint256) {
      ISwapRouter swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
      // Approve the router to spend token in.
      TransferHelper.safeApprove(_tokenIn, address(swapRouter), _amount);
      bytes memory path;
      if (_hopToken != address(0)) {
          uint24 fee0 = _getUniswapPoolFeeWithHighestLiquidity(_tokenIn, _hopToken);
          uint24 fee1 = _getUniswapPoolFeeWithHighestLiquidity(_tokenOut, _hopToken);
          path = abi.encodePacked(_tokenIn, fee0, _hopToken, fee1, _tokenOut);
      } else {
          uint24 ufee = _getUniswapPoolFeeWithHighestLiquidity(_tokenIn, _tokenOut);
          path = abi.encodePacked(_tokenIn, ufee, _tokenOut);
      }
      ISwapRouter.ExactInputParams memory params =
          ISwapRouter.ExactInputParams(path, address(this), block.timestamp, _amount, _minAmountOut);
      return swapRouter.exactInput(params);
  }

  /**
   * Returns the FEE of the highest liquidity pool in univ3 for this pair
   * @param sendToken               Token that is sold
   * @param receiveToken            Token that is purchased
   */
  function _getUniswapPoolFeeWithHighestLiquidity(address sendToken, address receiveToken)
      private
      view
      returns (uint24)
  {
      IUniswapV3Pool poolLow = IUniswapV3Pool(factory.getPool(sendToken, receiveToken, FEE_LOW));
      IUniswapV3Pool poolMedium = IUniswapV3Pool(factory.getPool(sendToken, receiveToken, FEE_MEDIUM));
      IUniswapV3Pool poolHigh = IUniswapV3Pool(factory.getPool(sendToken, receiveToken, FEE_HIGH));

      uint128 liquidityLow = address(poolLow) != address(0) ? poolLow.liquidity() : 0;
      uint128 liquidityMedium = address(poolMedium) != address(0) ? poolMedium.liquidity() : 0;
      uint128 liquidityHigh = address(poolHigh) != address(0) ? poolHigh.liquidity() : 0;
      if (liquidityLow >= liquidityMedium && liquidityLow >= liquidityHigh) {
          return FEE_LOW;
      }
      if (liquidityMedium >= liquidityLow && liquidityMedium >= liquidityHigh) {
          return FEE_MEDIUM;
      }
      return FEE_HIGH;
  }

  // Swaps WETH to stETH via Curve
  function _swapWETHToStETH(uint256 _ethAmount) private {
      // Convert WETH to ETH
      WETH.withdraw(_ethAmount);
      uint256 pricePerTokenUnit = IPriceOracle(PRICE_ORACLE).getPrice(address(WETH), address(stETH));
      // Exchange ETH to stETH on curve
      ICurvePool curvePool = ICurvePool(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);
      curvePool.exchange{value: _ethAmount}(0, 1, _ethAmount, _ethAmount.preciseMul(pricePerTokenUnit).preciseMul(99e16));
  }

  // solhint-disable-next-line
  receive() external payable {}

}