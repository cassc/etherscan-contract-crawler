// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Initializable} from "upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlDefaultAdminRulesUpgradeable} from
  "upgradeable/access/AccessControlDefaultAdminRulesUpgradeable.sol";
import {IERC20} from "oz/token/ERC20/IERC20.sol";
import {SafeERC20} from "oz/token/ERC20/utils/SafeERC20.sol";

import {ISavingsDAI} from "./ISavingsDAI.sol";
import {IBridge} from "./IBridge.sol";

/**
 * @title L1Escrow
 * @author sepyke.eth
 * @notice Main smart contract to bridge DAI from Ethereum to Polygon zkEVM
 */
contract L1Escrow is
  Initializable,
  UUPSUpgradeable,
  AccessControlDefaultAdminRulesUpgradeable
{
  using SafeERC20 for IERC20;

  /// @notice Role identifiers
  bytes32 public constant MAKER_ROLE = keccak256("MAKER_ROLE");

  /// @notice DAI contract
  IERC20 public dai;

  /// @notice sDAI contract
  ISavingsDAI public sdai;

  /// @notice Polygon zkEVM bridge contract
  IBridge public zkEvmBridge;

  /// @notice Native DAI contract address on Polygon zkEVM
  address public destAddress;

  /// @notice Network ID of Polygon zkEVM on the Polygon zkEVM bridge
  uint32 public destId;

  /// @notice The total amount of DAI bridged to Polygon zkEVM
  uint256 public totalBridgedDAI;

  /// @notice The target amount of DAI locked in this smart contract
  uint256 public totalProtocolDAI;

  /// @notice The address to which yield from DSR should be sent
  address public beneficiary;

  /// @notice This event is emitted when the beneficiary address is updated
  event BeneficiaryUpdated(address newBeneficiary);

  /// @notice This event is emitted when the totalProtocolDAI is updated
  event TotalProtocolDAIUpdated(uint256 newAmount);

  /// @notice This event is emitted when the DAI is bridged
  event DAIBridged(address indexed bridgoor, uint256 amount, uint256 total);

  /// @notice This event is emitted when the DAI is claimed
  event DAIClaimed(address indexed bridgoor, uint256 amount, uint256 total);

  /// @notice This event is emitted when the excess DAI is claimed
  event YieldClaimed(address indexed beneficiary, uint256 amount);

  /// @notice This event is emitted when assets is rebalanced
  event AssetRebalanced();

  /// @notice This error is raised if new beneficiary address is invalid
  error BeneficiaryInvalid(address newBeneficiary);

  /// @notice This error is raised if message from the bridge is invalid
  error MessageInvalid();

  /// @notice This error is raised if bridged amount is invalid
  error BridgeAmountInvalid();

  /// @notice Disable initializer on deploy
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice L1Escrow initializer
   * @param _adminAddress The admin address
   * @param _makerAddress The MakerDAO address
   * @param _daiAddress The DAI address
   * @param _sdaiAddress The sDAI address
   * @param _bridgeAddress The Polygon zkEVM bridge address
   * @param _destId The Polygon zkEVM ID on the bridge
   * @param _destAddress The token address on the Polygon zkEVM network
   * @param _totalProtocolDAI The target amount of DAI locked
   * @param _beneficiary The address to which yield from DSR should be sent
   */
  function initialize(
    address _adminAddress,
    address _makerAddress,
    address _daiAddress,
    address _sdaiAddress,
    address _bridgeAddress,
    uint32 _destId,
    address _destAddress,
    uint256 _totalProtocolDAI,
    address _beneficiary
  ) public initializer {
    __AccessControlDefaultAdminRules_init(3 days, _adminAddress);
    __UUPSUpgradeable_init();

    _grantRole(MAKER_ROLE, _makerAddress);

    dai = IERC20(_daiAddress);
    sdai = ISavingsDAI(_sdaiAddress);
    zkEvmBridge = IBridge(_bridgeAddress);
    destId = _destId;
    destAddress = _destAddress;
    beneficiary = _beneficiary;
    totalProtocolDAI = _totalProtocolDAI;
  }

  /**
   * @dev The L1Escrow can only be upgraded by the owner
   * @param v new L1Escrow implementation
   */
  function _authorizeUpgrade(address v)
    internal
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {}

  /**
   * @notice Set a new target amount of DAI locked in this smart contract
   * @param amount A new target amount
   */
  function setProtocolDAI(uint256 amount) public virtual onlyRole(MAKER_ROLE) {
    totalProtocolDAI = amount;
    emit TotalProtocolDAIUpdated(amount);
  }

  /**
   * @notice Bridge DAI from Ethereum mainnet to Polygon zkEVM
   * @param recipient The recipient of the bridged token
   * @param amount DAI amount
   * @param forceUpdateGlobalExitRoot Indicates if the global exit root is
   *        updated or not
   */
  function bridgeToken(
    address recipient,
    uint256 amount,
    bool forceUpdateGlobalExitRoot
  ) external virtual {
    // Set minimum amount of bridged DAI to cover rounding issue
    // e.g. if you deposit 1 wei to sDAI, you will get 0 shares
    if (amount < 1 ether) revert BridgeAmountInvalid();

    dai.safeTransferFrom(msg.sender, address(this), amount);

    // NOTE:
    // Currently there is no way to check the max deposit amount.
    // sdai.maxDeposit is hardcoded to type(uint256).max.
    // sdai.deposit may reverted and it is possible that total amount of
    // locked DAI in this smart contract is greater than the totalProtocolDAI
    dai.safeApprove(address(sdai), amount);
    try sdai.deposit(amount, address(this)) returns (uint256) {}
    catch {
      dai.safeApprove(address(sdai), 0);
    }

    bytes memory messageData = abi.encode(recipient, amount);
    zkEvmBridge.bridgeMessage(
      destId, destAddress, forceUpdateGlobalExitRoot, messageData
    );
    totalBridgedDAI += amount;
    emit DAIBridged(msg.sender, amount, totalBridgedDAI);
  }

  /**
   * @notice Send excess yield to beneficiary
   */
  function sendExcessYield() public {
    uint256 sdaiBalance = IERC20(address(sdai)).balanceOf(address(this));
    uint256 daiBalance = IERC20(address(dai)).balanceOf(address(this));
    uint256 savingsBalance = sdai.previewRedeem(sdaiBalance);
    uint256 totalManagedDAI = savingsBalance + daiBalance;
    if (totalManagedDAI > 0) {
      uint256 excess = totalManagedDAI - totalBridgedDAI;
      if (excess > daiBalance) {
        uint256 withdrawAmount = excess - daiBalance;
        sdai.withdraw(withdrawAmount, address(this), address(this));
      }
      if (excess > 0.05 ether) {
        uint256 claimedYield = excess - 0.01 ether;
        dai.safeTransfer(beneficiary, claimedYield);
        emit YieldClaimed(beneficiary, claimedYield);
      }
    }
  }

  /**
   * @notice Rebalance total locked DAI in this smart contract
   */
  function rebalance() public {
    uint256 balance = IERC20(address(dai)).balanceOf(address(this));
    if (balance > totalProtocolDAI) {
      uint256 targetDepositAmount = balance - totalProtocolDAI;
      if (targetDepositAmount > 0.05 ether) {
        // Leave smol amount of DAI in this smart contract
        uint256 depositAmount = targetDepositAmount - 0.01 ether;
        dai.safeApprove(address(sdai), depositAmount);
        sdai.deposit(depositAmount, address(this));
        emit AssetRebalanced();
      }
    } else {
      uint256 sdaiBalance = IERC20(address(sdai)).balanceOf(address(this));
      uint256 savingsBalance = sdai.previewRedeem(sdaiBalance);
      uint256 withdrawAmount = totalProtocolDAI - balance;
      if (withdrawAmount > 0 && savingsBalance > withdrawAmount) {
        sdai.withdraw(withdrawAmount, address(this), address(this));
        emit AssetRebalanced();
      }
    }
  }

  /**
   * @notice Set new beneficiary address
   * @param b new beneficiary address
   */
  function setBeneficiary(address b)
    public
    virtual
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if (b == beneficiary || b == address(0)) {
      revert BeneficiaryInvalid(b);
    }
    sendExcessYield();
    beneficiary = b;
    emit BeneficiaryUpdated(b);
  }

  /**
   * @notice This function will be triggered by the bridge
   * @param originAddress The origin address
   * @param originNetwork The origin network
   * @param metadata Abi encoded metadata
   */
  function onMessageReceived(
    address originAddress,
    uint32 originNetwork,
    bytes memory metadata
  ) external payable virtual {
    if (msg.sender != address(zkEvmBridge)) revert MessageInvalid();
    if (originAddress != destAddress) revert MessageInvalid();
    if (originNetwork != destId) revert MessageInvalid();

    (address recipient, uint256 amount) =
      abi.decode(metadata, (address, uint256));

    uint256 sdaiBalance = IERC20(address(sdai)).balanceOf(address(this));
    uint256 savingsBalance = sdai.previewRedeem(sdaiBalance);
    if (amount > savingsBalance) {
      sdai.withdraw(savingsBalance, recipient, address(this));
      dai.safeTransfer(recipient, amount - savingsBalance);
    } else {
      sdai.withdraw(amount, recipient, address(this));
    }

    totalBridgedDAI -= amount;
    emit DAIClaimed(recipient, amount, totalBridgedDAI);
  }
}