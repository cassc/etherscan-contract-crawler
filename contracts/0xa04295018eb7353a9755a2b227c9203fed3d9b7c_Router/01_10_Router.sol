// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";

import "./access/MPCSignable.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IRouter.sol";

contract Router is MPCSignable, Pausable, IRouter {
  IVault public vault;
  address public immutable WETH;
  mapping(bytes32 => bool) public claimed;

  constructor(IVault _vault, address _WETH, address _MPC) MPCSignable(_MPC) {
    vault = _vault;
    WETH = _WETH;
  }

  function create(
    Tariff calldata tariff,
    Input calldata input,
    bytes memory signature
  ) public whenNotPaused onlyMPCSignable(_getCreateHash(tariff), signature) {
    _validate(tariff, input);

    if (
      (input.token == tariff.baseToken && input.amount >= tariff.thresholdBaseAmount) ||
      (input.token == tariff.quoteToken && input.amount >= tariff.thresholdQuoteAmount)
    ) {
      vault.depositTokensToMPC(input.user, input.token, input.amount);
    } else {
      vault.depositTokens(input.user, input.token, input.amount);
    }

    emit DualCreated(
      input.user,
      block.chainid,
      tariff.baseToken,
      tariff.quoteToken,
      input.token,
      input.amount,
      tariff.stakingPeriod,
      tariff.yield
    );
  }

  function createWithPermit(
    Tariff calldata tariff,
    Input calldata input,
    bytes memory signature,
    Permit calldata permit
  ) public whenNotPaused onlyMPCSignable(_getCreateHash(tariff), signature) {
    _validate(tariff, input);

    if (
      (input.token == tariff.baseToken && input.amount >= tariff.thresholdBaseAmount) ||
      (input.token == tariff.quoteToken && input.amount >= tariff.thresholdQuoteAmount)
    ) {
      vault.depositTokensToMPCWithPermit(input.user, input.token, input.amount, permit);
    } else {
      vault.depositTokensWithPermit(input.user, input.token, input.amount, permit);
    }

    emit DualCreated(
      input.user,
      block.chainid,
      tariff.baseToken,
      tariff.quoteToken,
      input.token,
      input.amount,
      tariff.stakingPeriod,
      tariff.yield
    );
  }

  function createETH(
    Tariff calldata tariff,
    bytes memory signature
  ) public payable whenNotPaused onlyMPCSignable(_getCreateHash(tariff), signature) {
    address user = msg.sender;
    address inputToken = WETH;
    uint256 inputAmount = msg.value;

    _validate(tariff, Input(user, inputToken, inputAmount));

    if (
      (inputToken == tariff.baseToken && inputAmount >= tariff.thresholdBaseAmount) ||
      (inputToken == tariff.quoteToken && inputAmount >= tariff.thresholdQuoteAmount)
    ) {
      vault.depositToMPC{value: msg.value}();
    } else {
      vault.deposit{value: msg.value}();
    }

    emit DualCreated(
      user,
      block.chainid,
      tariff.baseToken,
      tariff.quoteToken,
      inputToken,
      inputAmount,
      tariff.stakingPeriod,
      tariff.yield
    );
  }

  function claim(
    address user,
    address receiver,
    address outputToken,
    uint256 outputAmount,
    bytes32 txHash,
    bytes memory signature
  ) public onlyMPCSignable(_getClaimHash(user, outputToken, outputAmount, txHash), signature) {
    require(msg.sender == user || (msg.sender == mpc() && user == receiver), "Router: Bad sender");
    require(txHash != 0x00, "Router: Bad transaction hash");
    require(claimed[txHash] == false, "Router: Dual is already claimed");

    require(outputAmount > 0, "Router: Too small output amount");

    claimed[txHash] = true;

    if (outputToken == address(WETH)) {
      vault.withdraw(payable(receiver), outputAmount);
    } else {
      vault.withdrawTokens(receiver, outputToken, outputAmount);
    }

    emit DualClaimed(user, receiver, outputToken, outputAmount, txHash);
  }

  function cancel(address user, address inputToken, uint256 inputAmount, bytes32 txHash) public onlyMPC {
    require(txHash != 0x00, "Router: Bad transaction hash");
    require(claimed[txHash] == false, "Router: Dual is already claimed");
    require(inputAmount > 0, "Router: Too small input amount");

    claimed[txHash] = true;

    if (inputToken == address(WETH)) {
      vault.withdraw(payable(user), inputAmount);
    } else {
      vault.withdrawTokens(user, inputToken, inputAmount);
    }

    emit DualCanceled(user, inputToken, inputAmount, txHash);
  }

  function updateVault(IVault _vault) public onlyMPC {
    require(address(_vault) != address(0x0), "Router: Bad address");

    IVault oldVault = vault;
    vault = _vault;

    emit VaultUpdated(oldVault, _vault);
  }

  function pause() public whenNotPaused onlyMPC {
    _pause();
  }

  function unpause() public whenPaused onlyMPC {
    _unpause();
  }

  function _validate(Tariff memory tariff, Input memory input) private view {
    require(input.user != address(0x0), "Router: Bad user");
    require(tariff.user == address(0x0) || tariff.user == input.user, "Router: Bad tariff user");
    require(msg.sender == input.user || msg.sender == mpc(), "Router: Access denied");

    require(tariff.expireAt > block.timestamp, "Router: Tariff expired");
    require(tariff.yield > 0, "Router: Bad tariff yield");
    require(tariff.stakingPeriod > 0, "Router: Bad tariff staking period");

    require(input.token == tariff.baseToken || input.token == tariff.quoteToken, "Router: Input must be one from pair");

    if (tariff.baseToken == input.token) {
      require(input.amount >= tariff.minBaseAmount, "Router: Too small input amount");
      require(input.amount <= tariff.maxBaseAmount, "Router: Exceeds maximum input amount");
    } else {
      require(input.amount >= tariff.minQuoteAmount, "Router: Too small input amount");
      require(input.amount <= tariff.maxQuoteAmount, "Router: Exceeds maximum input amount");
    }
  }

  function _getCreateHash(Tariff calldata tariff) internal view returns (bytes32) {
    return keccak256(
      abi.encode(
        block.chainid,
        tariff.user,
        tariff.baseToken,
        tariff.quoteToken,
        tariff.minBaseAmount,
        tariff.maxBaseAmount,
        tariff.minQuoteAmount,
        tariff.maxQuoteAmount,
        tariff.thresholdBaseAmount,
        tariff.thresholdQuoteAmount,
        tariff.stakingPeriod,
        tariff.yield,
        tariff.expireAt
      )
    );
  }

  function _getClaimHash(address user, address token, uint256 amount, bytes32 txHash) internal view returns (bytes32) {
    return keccak256(abi.encode(block.chainid, user, token, amount, txHash));
  }
}