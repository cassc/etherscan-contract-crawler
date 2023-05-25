// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "../../goldfinch/interfaces/ISeniorPoolEpochWithdrawals.sol";

import "../utils/AdminUpgradeable.sol";
import "../config/ConfigHelper.sol";
import "../config/AlloyxConfig.sol";

/**

 * @title FIDUVault
 * @notice FIDUVault for managing withdrawals
 * @author AlloyX
 */
contract FIDUVault is AdminUpgradeable, ERC721HolderUpgradeable {
  using SafeMath for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using ConfigHelper for AlloyxConfig;
  AlloyxConfig public config;
  bytes32 public constant INVESTOR_ROLE = keccak256("INVESTOR_ROLE");
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  bool internal locked;

  address public seniorPoolWithdrawTokenAddress;
  address public fiduAddress;
  address public usdcAddress;
  address public seniorPoolAddress;

  /**
   * @notice Initialize the contract
   */
  function initialize(address _seniorPoolWithdrawTokenAddress, address _configAddress) external initializer {
    __AdminUpgradeable_init(msg.sender);
    config = AlloyxConfig(_configAddress);

    seniorPoolWithdrawTokenAddress = _seniorPoolWithdrawTokenAddress;

    fiduAddress = config.fiduAddress();
    usdcAddress = config.usdcAddress();
    seniorPoolAddress = config.seniorPoolAddress();
    _grantRole(ADMIN_ROLE, msg.sender);
  }

  function changeSeniorPoolTokenAddress(address newAddress) external onlyRole(ADMIN_ROLE) {
    seniorPoolWithdrawTokenAddress = newAddress;
  }

  function grantInvestorRole(address investorAddress) external onlyRole(ADMIN_ROLE) {
    _grantRole(INVESTOR_ROLE, investorAddress);
  }

  function revokeInvestorRole(address investorAddress) external onlyRole(ADMIN_ROLE) {
    _revokeRole(INVESTOR_ROLE, investorAddress);
  }

  /**
   * @notice Deposit FIDU and create a request with Goldfinch
   */
  function deposit(uint256 _amount) external onlyRole(INVESTOR_ROLE) nonReentrant {
    ISeniorPoolEpochWithdrawals seniorPool = ISeniorPoolEpochWithdrawals(seniorPoolAddress);
    _transferERC20From(msg.sender, fiduAddress, address(this), _amount);
    seniorPool.requestWithdrawal(_amount);
  }

  /**
   * @notice Claim available USDC
   */
  function claim() external onlyRole(INVESTOR_ROLE) nonReentrant {
    ISeniorPoolEpochWithdrawals seniorPool = ISeniorPoolEpochWithdrawals(seniorPoolAddress);
    ERC721Enumerable seniorPoolWithdrawToken = ERC721Enumerable(seniorPoolWithdrawTokenAddress);
    uint256 tokenId = seniorPoolWithdrawToken.tokenOfOwnerByIndex(address(this), 0);
    ISeniorPoolEpochWithdrawals.WithdrawalRequest memory withdrawRequest = seniorPool.withdrawalRequest(tokenId);
    uint256 amountAvailable = withdrawRequest.usdcWithdrawable;
    require(amountAvailable > 0);
    seniorPool.claimWithdrawalRequest(tokenId);
    _transferERC20From(address(this), usdcAddress, msg.sender, amountAvailable);
  }

  /**
   * @notice Cancel withdraw request and redeem FIDU to owner
   */
  function cancel() external onlyRole(INVESTOR_ROLE) nonReentrant {
    ISeniorPoolEpochWithdrawals seniorPool = ISeniorPoolEpochWithdrawals(seniorPoolAddress);
    ERC721Enumerable seniorPoolWithdrawToken = ERC721Enumerable(seniorPoolWithdrawTokenAddress);
    uint256 tokenId = seniorPoolWithdrawToken.tokenOfOwnerByIndex(address(this), 0);
    ISeniorPoolEpochWithdrawals.WithdrawalRequest memory withdrawRequest = seniorPool.withdrawalRequest(tokenId);
    require(withdrawRequest.fiduRequested > 0);
    seniorPool.cancelWithdrawalRequest(tokenId);
    _transferERC20From(address(this), fiduAddress, msg.sender, withdrawRequest.fiduRequested);
  }

  /**
   * @notice Transfer certain amount token of certain address to some other account
   * @param _from the address to transfer from
   * @param _account the address to transfer
   * @param _amount the amount to transfer
   * @param _tokenAddress the token address to transfer
   */
  function _transferERC20From(address _from, address _tokenAddress, address _account, uint256 _amount) internal {
    IERC20Upgradeable(_tokenAddress).safeTransferFrom(_from, _account, _amount);
  }

  /**
   * @notice Ensure there is no reentrant
   */
  modifier nonReentrant() {
    require(!locked);
    locked = true;
    _;
    locked = false;
  }
}