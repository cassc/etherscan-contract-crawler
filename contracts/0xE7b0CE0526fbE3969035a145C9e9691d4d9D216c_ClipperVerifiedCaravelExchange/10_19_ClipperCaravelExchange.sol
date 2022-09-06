//SPDX-License-Identifier: Copyright 2021 Shipyard Software, Inc.
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "./interfaces/WrapperContractInterface.sol";

import "./ClipperCommonExchange.sol";

contract ClipperCaravelExchange is ClipperCommonExchange, Ownable {
  using SafeCast for uint256;
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;

  modifier receivedInTime(uint256 goodUntil){
    require(block.timestamp <= goodUntil, "Clipper: Expired");
    _;
  }

  constructor(address theSigner, address theWrapper, address[] memory tokens)
    ClipperCommonExchange(theSigner, theWrapper, tokens)
    {}

  function addAsset(address token) external onlyOwner {
    assetSet.add(token);
    _sync(token);
  }

  function tokenBalance(address token) internal view returns (uint256) {
    (bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(IERC20.balanceOf.selector, address(this)));
    require(success && data.length >= 32);
    return abi.decode(data, (uint256));
  }

  function _sync(address token) internal virtual override {
    setBalance(token, tokenBalance(token));
  }

  function confirmUnique(address token) internal view returns (uint32 newHash, uint256 currentBalance) {
    uint256 _current = lastBalances[token];
    currentBalance = uint256(uint224(_current));
    uint32 lastHash = uint32(_current >> 224);
    newHash = uint32(block.number+uint256(uint160(tx.origin)));
    require(newHash != lastHash, "Clipper: Failed tx uniqueness");
  }

  function makeWriteValue(uint32 newHash, uint256 newBalance) internal pure returns (uint256) {
    return (uint256(newHash) << 224) + uint256(newBalance.toUint224());
  }

  function setBalance(address token, uint256 newBalance) internal virtual {
    (uint32 newHash, ) = confirmUnique(token);
    lastBalances[token] = makeWriteValue(newHash, newBalance);
  }

  function increaseBalance(address token, uint256 increaseAmount) internal virtual {
    (uint32 newHash, uint256 curBalance) = confirmUnique(token);
    lastBalances[token] = makeWriteValue(newHash, curBalance+increaseAmount);
  }

  function decreaseBalance(address token, uint256 decreaseAmount) internal virtual {
    (uint32 newHash, uint256 curBalance) = confirmUnique(token);
    lastBalances[token] = makeWriteValue(newHash, curBalance-decreaseAmount);
  }

  function getLastBalance(address token) public view virtual override returns (uint256) {
    return uint256(uint224(lastBalances[token]));
  }

  // Can deposit raw ETH by attaching as msg.value
  function deposit(address sender, uint256[] calldata depositAmounts, uint256 nDays, uint256 poolTokens, uint256 goodUntil, Signature calldata theSignature) public payable override receivedInTime(goodUntil){
    if(msg.value > 0){
      safeEthSend(WRAPPER_CONTRACT, msg.value);
    }
    // Make sure the depositor is allowed
    require(msg.sender==sender, "Listed sender does not match msg.sender");
    bytes32 depositDigest = createDepositDigest(sender, depositAmounts, nDays, poolTokens, goodUntil);
    // Revert if it's signed by the wrong address
    verifyDigestSignature(depositDigest, theSignature);

    // Check deposit amounts, syncing as we go
    uint i=0;
    uint n = depositAmounts.length;
    while(i < n){
      uint256 allegedDeposit = depositAmounts[i];
      if(allegedDeposit > 0){
        address _token = tokenAt(i);
        uint256 currentBalance = tokenBalance(_token);
        require(currentBalance - getLastBalance(_token) >= allegedDeposit, "Insufficient token deposit");
        setBalance(_token, currentBalance);
      }
      i++;
    }
    // OK now we're good
    _mintOrVesting(sender, nDays, poolTokens);
    emit Deposited(sender, poolTokens, nDays);
  }

  function depositSingleAsset(address sender, address inputToken, uint256 inputAmount, uint256 nDays, uint256 poolTokens, uint256 goodUntil, Signature calldata theSignature) public payable override receivedInTime(goodUntil){
    if(msg.value > 0){
      safeEthSend(WRAPPER_CONTRACT, msg.value);
    }
    // Make sure the depositor is allowed
    require(msg.sender==sender && isToken(inputToken), "Invalid input");

    // Check the signature
    bytes32 depositDigest = createSingleDepositDigest(sender, inputToken, inputAmount, nDays, poolTokens, goodUntil);
    // Revert if it's signed by the wrong address
    verifyDigestSignature(depositDigest, theSignature);

    // Check deposit amount and sync balance
    uint256 currentBalance = tokenBalance(inputToken);
    require(currentBalance - getLastBalance(inputToken) >= inputAmount, "Insufficient token deposit");
    // sync the balance
    setBalance(inputToken, currentBalance);

    // OK now we're good
    _mintOrVesting(sender, nDays, poolTokens);
    emit Deposited(sender, poolTokens, nDays);
  }

  /* WITHDRAWAL FUNCTIONALITY */
  
  /* Single asset withdrawal functionality */

  function withdrawSingleAsset(address tokenHolder, uint256 poolTokenAmountToBurn, address assetAddress, uint256 assetAmount, uint256 goodUntil, Signature calldata theSignature) external override receivedInTime(goodUntil) {
    /* CHECKS */
    require(msg.sender==tokenHolder, "tokenHolder does not match msg.sender");
    
    bool sendEthBack;
    if(assetAddress == CLIPPER_ETH_SIGIL) {
      assetAddress = WRAPPER_CONTRACT;
      sendEthBack = true;
    }

    bytes32 withdrawalDigest = createWithdrawalDigest(tokenHolder, poolTokenAmountToBurn, assetAddress, assetAmount, goodUntil);
    // Reverts if it's signed by the wrong address
    verifyDigestSignature(withdrawalDigest, theSignature);

    /* EFFECTS */
    // Reverts if pool token balance is insufficient
    _burn(msg.sender, poolTokenAmountToBurn);
    
    // Reverts if the pool's balance of the token is insufficient  
    decreaseBalance(assetAddress, assetAmount);

    /* INTERACTIONS */
    if(sendEthBack) {
      WrapperContractInterface(WRAPPER_CONTRACT).withdraw(assetAmount);
      safeEthSend(msg.sender, assetAmount);
    } else {
      IERC20(assetAddress).safeTransfer(msg.sender, assetAmount);
    }

    emit AssetWithdrawn(tokenHolder, poolTokenAmountToBurn, assetAddress, assetAmount);
  }

  /* SWAP Functionality */

  // Don't need a separate "transmit" function here since it's already payable
  // Gas optimized - no balance checks
  // Don't need fairOutput checks since exactly inputAmount is wrapped
  function sellEthForToken(address outputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData) external virtual override receivedInTime(goodUntil) payable {
    /* CHECKS */
    require(isToken(outputToken), "Clipper: Invalid token");
    // Wrap ETH (as balance or value) as input. This will revert if insufficient balance is provided
    safeEthSend(WRAPPER_CONTRACT, inputAmount);
    // Revert if it's signed by the wrong address    
    bytes32 digest = createSwapDigest(WRAPPER_CONTRACT, outputToken, inputAmount, outputAmount, goodUntil, destinationAddress);
    verifyDigestSignature(digest, theSignature);

    /* EFFECTS */
    increaseBalance(WRAPPER_CONTRACT, inputAmount);
    decreaseBalance(outputToken, outputAmount);

    /* INTERACTIONS */
    IERC20(outputToken).safeTransfer(destinationAddress, outputAmount);

    emit Swapped(WRAPPER_CONTRACT, outputToken, destinationAddress, inputAmount, outputAmount, auxiliaryData);
  }

  // Mostly copied from gas-optimized swap functionality
  function sellTokenForEth(address inputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData) external virtual override receivedInTime(goodUntil) {
    /* CHECKS */
    require(isToken(inputToken), "Clipper: Invalid token");
    // Revert if it's signed by the wrong address    
    bytes32 digest = createSwapDigest(inputToken, WRAPPER_CONTRACT, inputAmount, outputAmount, goodUntil, destinationAddress);
    verifyDigestSignature(digest, theSignature);
    
    // Check that enough input token has been transmitted
    uint256 currentInputBalance = tokenBalance(inputToken);
    uint256 actualInput = currentInputBalance - getLastBalance(inputToken);
    uint256 fairOutput = calculateFairOutput(inputAmount, actualInput, outputAmount);


    /* EFFECTS */
    setBalance(inputToken, currentInputBalance);
    decreaseBalance(WRAPPER_CONTRACT, fairOutput);

    /* INTERACTIONS */
    // Unwrap and forward ETH, without sync
    WrapperContractInterface(WRAPPER_CONTRACT).withdraw(fairOutput);
    safeEthSend(destinationAddress, fairOutput);

    emit Swapped(inputToken, WRAPPER_CONTRACT, destinationAddress, actualInput, fairOutput, auxiliaryData);
  }

  function transmitAndDepositSingleAsset(address inputToken, uint256 inputAmount, uint256 nDays, uint256 poolTokens, uint256 goodUntil, Signature calldata theSignature) external virtual override receivedInTime(goodUntil){
    // Make sure the depositor is allowed
    require(isToken(inputToken), "Invalid input");

    // Will revert if msg.sender has insufficient balance
    IERC20(inputToken).safeTransferFrom(msg.sender, address(this), inputAmount);

    // Check the signature
    bytes32 depositDigest = createSingleDepositDigest(msg.sender, inputToken, inputAmount, nDays, poolTokens, goodUntil);
    // Revert if it's signed by the wrong address
    verifyDigestSignature(depositDigest, theSignature);

    // sync the deposited asset
    increaseBalance(inputToken, inputAmount);

    // OK now we're good
    _mintOrVesting(msg.sender, nDays, poolTokens);
    emit Deposited(msg.sender, poolTokens, nDays);
  }

  // Gas optimized, no balance checks
  // No need to check fairOutput since the inputToken pull works
  function transmitAndSellTokenForEth(address inputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData) external virtual override receivedInTime(goodUntil) {
    /* CHECKS */
    require(isToken(inputToken), "Clipper: Invalid token");
    // Will revert if msg.sender has insufficient balance
    IERC20(inputToken).safeTransferFrom(msg.sender, address(this), inputAmount);
    // Revert if it's signed by the wrong address    
    bytes32 digest = createSwapDigest(inputToken, WRAPPER_CONTRACT, inputAmount, outputAmount, goodUntil, destinationAddress);
    verifyDigestSignature(digest, theSignature);

    /* EFFECTS */
    increaseBalance(inputToken, inputAmount);
    decreaseBalance(WRAPPER_CONTRACT, outputAmount);

    /* INTERACTIONS */
    // Unwrap and forward ETH, we've already updated the balance
    WrapperContractInterface(WRAPPER_CONTRACT).withdraw(outputAmount);
    safeEthSend(destinationAddress, outputAmount);

    emit Swapped(inputToken, WRAPPER_CONTRACT, destinationAddress, inputAmount, outputAmount, auxiliaryData);
  }

  // all-in-one transfer from msg.sender to destinationAddress.
  // Gas optimized - never checks balances
  // No need to check fairOutput since the inputToken pull works
  function transmitAndSwap(address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData) external virtual override receivedInTime(goodUntil) {
    /* CHECKS */
    require(isToken(inputToken) && isToken(outputToken), "Clipper: Invalid tokens");
    // Will revert if msg.sender has insufficient balance
    IERC20(inputToken).safeTransferFrom(msg.sender, address(this), inputAmount);
    // Revert if it's signed by the wrong address    
    bytes32 digest = createSwapDigest(inputToken, outputToken, inputAmount, outputAmount, goodUntil, destinationAddress);
    verifyDigestSignature(digest, theSignature);

    /* EFFECTS */
    increaseBalance(inputToken, inputAmount);
    decreaseBalance(outputToken, outputAmount);

    /* INTERACTIONS */
    IERC20(outputToken).safeTransfer(destinationAddress, outputAmount);

    emit Swapped(inputToken, outputToken, destinationAddress, inputAmount, outputAmount, auxiliaryData);
  }

  // Gas optimized - single token balance check for input
  // output is dead-reckoned and scaled back if necessary
  function swap(address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData) public virtual override receivedInTime(goodUntil) {
    /* CHECKS */
    require(isToken(inputToken) && isToken(outputToken), "Clipper: Invalid tokens");

    { // Avoid stack too deep
    // Revert if it's signed by the wrong address    
    bytes32 digest = createSwapDigest(inputToken, outputToken, inputAmount, outputAmount, goodUntil, destinationAddress);
    verifyDigestSignature(digest, theSignature);
    }

    // Get fair output value
    uint256 currentInputBalance = tokenBalance(inputToken);
    uint256 actualInput = currentInputBalance-getLastBalance(inputToken);    
    uint256 fairOutput = calculateFairOutput(inputAmount, actualInput, outputAmount);


    /* EFFECTS */
    setBalance(inputToken, currentInputBalance);
    decreaseBalance(outputToken, fairOutput);

    /* INTERACTIONS */
    IERC20(outputToken).safeTransfer(destinationAddress, fairOutput);

    emit Swapped(inputToken, outputToken, destinationAddress, actualInput, fairOutput, auxiliaryData);
  }

}