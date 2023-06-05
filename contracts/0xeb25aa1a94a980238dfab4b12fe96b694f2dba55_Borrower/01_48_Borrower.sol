// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IVersioned} from "../../interfaces/IVersioned.sol";
import {ICreditLine} from "../../interfaces/ICreditLine.sol";
import {SafeERC20Transfer} from "../../library/SafeERC20Transfer.sol";
import {BaseUpgradeablePausable} from "../core/BaseUpgradeablePausable.sol";
import {ConfigHelper} from "../core/ConfigHelper.sol";
import {GoldfinchConfig} from "../core/GoldfinchConfig.sol";
import {IERC20withDec} from "../../interfaces/IERC20withDec.sol";
import {ITranchedPool} from "../../interfaces/ITranchedPool.sol";
import {ILoan} from "../../interfaces/ILoan.sol";
import {IBorrower} from "../../interfaces/IBorrower.sol";
import {BaseRelayRecipient} from "../../external/BaseRelayRecipient.sol";
import {ContextUpgradeSafe} from "@openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol";
import {Math} from "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";

/**
 * @title Goldfinch's Borrower contract
 * @notice These contracts represent the a convenient way for a borrower to interact with Goldfinch
 *  They are 100% optional. However, they let us add many sophisticated and convient features for borrowers
 *  while still keeping our core protocol small and secure. We therefore expect most borrowers will use them.
 *  This contract is the "official" borrower contract that will be maintained by Goldfinch governance. However,
 *  in theory, anyone can fork or create their own version, or not use any contract at all. The core functionality
 *  is completely agnostic to whether it is interacting with a contract or an externally owned account (EOA).
 * @author Goldfinch
 */

contract Borrower is BaseUpgradeablePausable, BaseRelayRecipient, IBorrower {
  using SafeERC20Transfer for IERC20withDec;
  using ConfigHelper for GoldfinchConfig;

  GoldfinchConfig public config;

  address private constant USDT_ADDRESS = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  address private constant BUSD_ADDRESS = address(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
  address private constant GUSD_ADDRESS = address(0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd);
  address private constant DAI_ADDRESS = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

  function initialize(address owner, address _config) external override initializer {
    require(
      owner != address(0) && _config != address(0),
      "Owner and config addresses cannot be empty"
    );
    __BaseUpgradeablePausable__init(owner);
    config = GoldfinchConfig(_config);

    trustedForwarder = config.trustedForwarderAddress();

    // Handle default approvals. Pool, and OneInch for maximum amounts
    address oneInch = config.oneInchAddress();
    IERC20withDec usdc = config.getUSDC();
    usdc.approve(oneInch, uint256(-1));
    bytes memory data = abi.encodeWithSignature("approve(address,uint256)", oneInch, uint256(-1));
    _invoke(USDT_ADDRESS, data);
    _invoke(BUSD_ADDRESS, data);
    _invoke(GUSD_ADDRESS, data);
    _invoke(DAI_ADDRESS, data);
  }

  function lockJuniorCapital(address poolAddress) external onlyAdmin {
    ITranchedPool(poolAddress).lockJuniorCapital();
  }

  function lockPool(address poolAddress) external onlyAdmin {
    ITranchedPool(poolAddress).lockPool();
  }

  /**
   * @notice Drawdown on a loan
   * @param poolAddress Pool to drawdown from
   * @param amount usdc amount to drawdown
   * @param addressToSendTo Address to send the funds. Null address or address(this) will send funds back to the caller
   */
  function drawdown(
    address poolAddress,
    uint256 amount,
    address addressToSendTo
  ) external onlyAdmin {
    ILoan(poolAddress).drawdown(amount);

    if (addressToSendTo == address(0) || addressToSendTo == address(this)) {
      addressToSendTo = _msgSender();
    }

    transferERC20(config.usdcAddress(), addressToSendTo, amount);
  }

  /**
   * @notice Drawdown on a v1 or v2 pool and swap the usdc to the desired token using OneInch
   * @param amount usdc amount to drawdown from the pool
   * @param addressToSendTo address to send the `toToken` to
   * @param toToken address of the ERC20 to swap to
   * @param minTargetAmount min amount of `toToken` you're willing to accept from the swap (i.e. a slippage tolerance)
   */
  function drawdownWithSwapOnOneInch(
    address poolAddress,
    uint256 amount,
    address addressToSendTo,
    address toToken,
    uint256 minTargetAmount,
    uint256[] calldata exchangeDistribution
  ) public onlyAdmin {
    // Drawdown to the Borrower contract
    ILoan(poolAddress).drawdown(amount);

    // Do the swap
    swapOnOneInch(config.usdcAddress(), toToken, amount, minTargetAmount, exchangeDistribution);

    // Default to sending to the owner, and don't let funds stay in this contract
    if (addressToSendTo == address(0) || addressToSendTo == address(this)) {
      addressToSendTo = _msgSender();
    }

    // Fulfill the send to
    bytes memory _data = abi.encodeWithSignature("balanceOf(address)", address(this));
    uint256 receivedAmount = _toUint256(_invoke(toToken, _data));
    transferERC20(toToken, addressToSendTo, receivedAmount);
  }

  function transferERC20(address token, address to, uint256 amount) public onlyAdmin {
    bytes memory _data = abi.encodeWithSignature("transfer(address,uint256)", to, amount);
    _invoke(token, _data);
  }

  /**
   * @notice Pay back a v1 or v2 tranched pool
   * @param poolAddress pool address
   * @param amount USDC amount to pay
   */
  function pay(address poolAddress, uint256 amount) external onlyAdmin {
    require(
      config.getUSDC().transferFrom(_msgSender(), address(this), amount),
      "Failed to transfer USDC"
    );
    _pay(poolAddress, amount);
  }

  /**
   * @notice Pay back multiple pools. Supports v0.1.0 and v1.0.0 pools
   * @param pools list of pool addresses for which the caller is the borrower
   * @param amounts amounts to pay back
   */
  function payMultiple(address[] calldata pools, uint256[] calldata amounts) external onlyAdmin {
    require(pools.length == amounts.length, "Pools and amounts must be the same length");

    uint256 totalAmount;
    for (uint256 i = 0; i < amounts.length; i++) {
      totalAmount = totalAmount.add(amounts[i]);
    }

    // Do a single transfer, which is cheaper
    require(
      config.getUSDC().transferFrom(_msgSender(), address(this), totalAmount),
      "Failed to transfer USDC"
    );

    for (uint256 i = 0; i < amounts.length; i++) {
      _pay(pools[i], amounts[i]);
    }
  }

  /**
   * @notice Pay back a v2.0.0 Tranched Pool
   * @param poolAddress The pool to be paid back
   * @param principalAmount principal amount to pay
   * @param interestAmount interest amount to pay
   */
  function pay(
    address poolAddress,
    uint256 principalAmount,
    uint256 interestAmount
  ) external onlyAdmin {
    // Take the minimum USDC to cover actual amounts owed
    ITranchedPool pool = ITranchedPool(poolAddress);
    uint256 maxPrincipalPayment = pool.creditLine().balance();
    uint256 maxInterestPayment = pool.creditLine().interestOwed().add(
      pool.creditLine().interestAccrued()
    );
    uint256 principalPayment = Math.min(principalAmount, maxPrincipalPayment);
    uint256 interestPayment = Math.min(interestAmount, maxInterestPayment);
    config.getUSDC().safeERC20TransferFrom(
      _msgSender(),
      address(this),
      principalPayment + interestPayment
    );

    ILoan.PaymentAllocation memory pa = _payV2Separate(
      poolAddress,
      principalPayment,
      interestPayment
    );

    // Since we took the exact amounts owed, any payment remaining would be indicative of a bug
    assert(pa.paymentRemaining == 0);
  }

  function payInFull(address poolAddress, uint256 amount) external onlyAdmin {
    require(
      config.getUSDC().transferFrom(_msgSender(), address(this), amount),
      "Failed to transfer USDC"
    );
    _pay(poolAddress, amount);
    require(ILoan(poolAddress).creditLine().balance() == 0, "Failed to fully pay off creditline");
  }

  function payWithSwapOnOneInch(
    address poolAddress,
    uint256 originAmount,
    address fromToken,
    uint256 minTargetAmount,
    uint256[] calldata exchangeDistribution
  ) external onlyAdmin {
    transferFrom(fromToken, _msgSender(), address(this), originAmount);
    IERC20withDec usdc = config.getUSDC();
    swapOnOneInch(fromToken, address(usdc), originAmount, minTargetAmount, exchangeDistribution);
    uint256 usdcBalance = usdc.balanceOf(address(this));
    _pay(poolAddress, usdcBalance);
  }

  function payMultipleWithSwapOnOneInch(
    address[] calldata pools,
    uint256[] calldata minAmounts,
    uint256 originAmount,
    address fromToken,
    uint256[] calldata exchangeDistribution
  ) external onlyAdmin {
    require(pools.length == minAmounts.length, "Pools and amounts must be the same length");

    uint256 totalMinAmount = 0;
    for (uint256 i = 0; i < minAmounts.length; i++) {
      totalMinAmount = totalMinAmount.add(minAmounts[i]);
    }

    transferFrom(fromToken, _msgSender(), address(this), originAmount);

    IERC20withDec usdc = config.getUSDC();

    swapOnOneInch(fromToken, address(usdc), originAmount, totalMinAmount, exchangeDistribution);

    for (uint256 i = 0; i < minAmounts.length; i++) {
      _pay(pools[i], minAmounts[i]);
    }
  }

  /* INTERNAL FUNCTIONS */
  function _pay(address poolAddress, uint256 amount) internal {
    config.getUSDC().safeERC20Approve(poolAddress, amount);
    ILoan(poolAddress).pay(amount);
  }

  function _payV2Separate(
    address poolAddress,
    uint256 principalAmount,
    uint256 interestAmount
  ) internal returns (ILoan.PaymentAllocation memory) {
    ITranchedPool pool = ITranchedPool(poolAddress);
    config.getUSDC().safeERC20Approve(poolAddress, principalAmount + interestAmount);
    return pool.pay(principalAmount, interestAmount);
  }

  function transferFrom(address erc20, address sender, address recipient, uint256 amount) internal {
    bytes memory _data;
    // Do a low-level _invoke on this transfer, since Tether fails if we use the normal IERC20 interface
    _data = abi.encodeWithSignature(
      "transferFrom(address,address,uint256)",
      sender,
      recipient,
      amount
    );
    _invoke(address(erc20), _data);
  }

  function swapOnOneInch(
    address fromToken,
    address toToken,
    uint256 originAmount,
    uint256 minTargetAmount,
    uint256[] calldata exchangeDistribution
  ) internal {
    bytes memory _data = abi.encodeWithSignature(
      "swap(address,address,uint256,uint256,uint256[],uint256)",
      fromToken,
      toToken,
      originAmount,
      minTargetAmount,
      exchangeDistribution,
      0
    );
    _invoke(config.oneInchAddress(), _data);
  }

  /**
   * @notice Performs a generic transaction.
   * @param _target The address for the transaction.
   * @param _data The data of the transaction.
   * Mostly copied from Argent:
   * https://github.com/argentlabs/argent-contracts/blob/develop/contracts/wallet/BaseWallet.sol#L111
   */
  function _invoke(address _target, bytes memory _data) internal returns (bytes memory) {
    // External contracts can be compiled with different Solidity versions
    // which can cause "revert without reason" when called through,
    // for example, a standard IERC20 ABI compiled on the latest version.
    // This low-level call avoids that issue.

    bool success;
    bytes memory _res;
    // solhint-disable-next-line avoid-low-level-calls
    (success, _res) = _target.call(_data);
    if (!success && _res.length > 0) {
      // solhint-disable-next-line no-inline-assembly
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    } else if (!success) {
      revert("VM: wallet _invoke reverted");
    }
    return _res;
  }

  function _toUint256(bytes memory _bytes) internal pure returns (uint256 value) {
    assembly {
      value := mload(add(_bytes, 0x20))
    }
  }

  // OpenZeppelin contracts come with support for GSN _msgSender() (which just defaults to msg.sender)
  // Since there are two different versions of the function in the hierarchy, we need to instruct solidity to
  // use the relay recipient version which can actually pull the real sender from the parameters.
  // https://www.notion.so/My-contract-is-using-OpenZeppelin-How-do-I-add-GSN-support-2bee7e9d5f774a0cbb60d3a8de03e9fb
  function _msgSender()
    internal
    view
    override(ContextUpgradeSafe, BaseRelayRecipient)
    returns (address payable)
  {
    return BaseRelayRecipient._msgSender();
  }

  function _msgData()
    internal
    view
    override(ContextUpgradeSafe, BaseRelayRecipient)
    returns (bytes memory ret)
  {
    return BaseRelayRecipient._msgData();
  }

  function versionRecipient() external view override returns (string memory) {
    return "2.0.0";
  }
}