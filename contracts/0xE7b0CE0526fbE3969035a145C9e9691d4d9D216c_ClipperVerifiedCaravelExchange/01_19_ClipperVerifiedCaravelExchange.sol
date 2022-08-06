//SPDX-License-Identifier: Copyright 2021 Shipyard Software, Inc.
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@prb/math/contracts/PRBMathSD59x18.sol";

import "./interfaces/WrapperContractInterface.sol";
import "./ClipperCaravelExchange.sol";

contract ClipperVerifiedCaravelExchange is ClipperCaravelExchange {
  using SafeERC20 for IERC20;
  using PRBMathSD59x18 for int256;
  using SafeCast for uint256;
  using SafeCast for int256;

  uint256 constant ONE_IN_DEFAULT_DECIMALS = 1e18;
  int256 constant SIGNED_ONE_IN_DEFAULT_DECIMALS = int256(ONE_IN_DEFAULT_DECIMALS);
  uint256 constant ONE_IN_PRICE_DECIMALS = 1e8;
  uint256 constant THE_YEAR_THREE_THOUSAND = 32503708800;

  struct UtilStruct {
    uint256 qX;
    uint256 qY;
    uint256 decimalMultiplierX;
    uint256 decimalMultiplierY;
  }

  constructor(address theSigner, address theWrapper, address[] memory tokens)
    ClipperCaravelExchange(theSigner, theWrapper, tokens){
      // Set up decimals
      uint i;
      for(i=0; i < tokens.length; i++){
        _sync(tokens[i]);
      }
  }

  function _sync(address token) internal override {
    lastBalances[token] = makeWriteValue(
      IERC20Metadata(token).decimals(),
      uint32(0),
      tokenBalance(token)
    );
  }

  function confirmUniqueDecimals(address token) internal view returns (uint8 decimals, uint32 newHash, uint256 currentBalance) {
    uint256 _current = lastBalances[token];
    decimals = uint8(_current >> 248);
    currentBalance = uint256(uint216(_current));
    uint32 lastHash = uint32(_current >> 216);
    newHash = uint32(block.number+uint256(uint160(tx.origin)));
    require(newHash != lastHash, "Clipper: Failed tx uniqueness");
  }

  // Hash:
  // uint8 decimals -> set on initiation and maintained
  // uint32 securityHash
  // uint216 actualBalance

  function makeWriteValue(uint8 decimals, uint32 newHash, uint256 newBalance) internal pure returns (uint256) {
    return (uint256(decimals) << 248) + (uint256(newHash) << 216) + uint256(newBalance.toUint216());
  }

  function setBalance(address token, uint256 newBalance) internal override {
    (uint8 decimals, uint32 newHash, ) = confirmUniqueDecimals(token);
    lastBalances[token] = makeWriteValue(decimals, newHash, newBalance);
  }

  function increaseBalance(address token, uint256 increaseAmount) internal override {
    (uint8 decimals, uint32 newHash, uint256 curBalance) = confirmUniqueDecimals(token);
    lastBalances[token] = makeWriteValue(decimals, newHash, curBalance+increaseAmount);
  }

  function decreaseBalance(address token, uint256 decreaseAmount) internal override {
    (uint8 decimals, uint32 newHash, uint256 curBalance) = confirmUniqueDecimals(token);
    lastBalances[token] = makeWriteValue(decimals, newHash, curBalance-decreaseAmount);
  }

  function getLastBalance(address token) public view override returns (uint256) {
    return uint256(uint216(lastBalances[token]));
  }

  function getLastBalanceAndDecimalMultiplier(address token) internal view returns (uint256 balance, uint256 decimalMultiplier) {
    uint256 _theBalance = lastBalances[token];
    balance = uint256(uint216(_theBalance));
    uint256 decimals = _theBalance >> 248;
    unchecked {
      if(decimals==18){
        decimalMultiplier = 1;
      } else if(decimals < 18){
        decimalMultiplier = 10**(18-decimals);
      } else {
        revert("Invalid decimals");
      }
    }
  }

  /* SWAP Functionality */

  function inputRequiresVerification(uint256 potentiallyPackedGoodUntil) internal pure returns (bool) {
    return potentiallyPackedGoodUntil > THE_YEAR_THREE_THOUSAND;
  }

  function unpackAndCheckInvariant(address inputToken, uint256 inputAmount,
    address outputToken, uint256 outputAmount,
    uint256 packedGoodUntil) internal view returns (uint256) {

    UtilStruct memory s;

    (uint256 pX, uint256 pY,uint256 wX, uint256 wY, uint256 k) = unpackGoodUntil(packedGoodUntil);
    (s.qX, s.decimalMultiplierX) = getLastBalanceAndDecimalMultiplier(inputToken);
    (s.qY, s.decimalMultiplierY) = getLastBalanceAndDecimalMultiplier(outputToken);

    require(
        swapIncreasesInvariant(
          inputAmount * s.decimalMultiplierX, pX, s.qX * s.decimalMultiplierX, wX,
          outputAmount * s.decimalMultiplierY, pY, s.qY * s.decimalMultiplierY, wY,
          k),
        "Clipper: Invariant");

    return uint256(uint32(packedGoodUntil));
  }

  function unpackGoodUntil(uint256 packedGoodUntil) public pure
    returns (uint256 pX, uint256 pY, uint256 wX, uint256 wY, uint256 k) {
    /*
        * Input asset price in 8 decimals - uint64
        * Output asset price in 8 decimals - uint64
        * k value in 18 decimals - uint64
        * Input asset weight - uint16
        * Output asset weight - uint16
        * Current good until value - uint32 - can be taken as uint256(uint32(packedGoodUntil))
    */
    // goodUntil = uint256(uint32(packedGoodUntil));
    packedGoodUntil = packedGoodUntil >> 32;
    wY = uint256(uint16(packedGoodUntil));
    packedGoodUntil = packedGoodUntil >> 16;
    wX = uint256(uint16(packedGoodUntil));
    packedGoodUntil = packedGoodUntil >> 16;
    k = uint256(uint64(packedGoodUntil));
    packedGoodUntil = packedGoodUntil >> 64;
    pY = uint256(uint64(packedGoodUntil));
    packedGoodUntil = packedGoodUntil >> 64;
    pX = uint256(uint64(packedGoodUntil));
  }

  /*
  Before calling:
  Set qX = lastBalances[inAsset];
  Set qY = lastBalances[outAsset];

  Multiply all quantities (q and in/out) by 10**(18-asset.decimals()).
  This puts all quantities in 18 decimals.

  Assumed decimals:
  K: 18
  Quantities: 18 (ONE_IN_DEFAULT_DECIMALS = 1e18)
  Prices: 8 (ONE_IN_PRICE_DECIMALS = 1e8)
  Weights: 0 (100 = 100)
  */
  function swapIncreasesInvariant(uint256 inX, uint256 pX, uint256 qX, uint256 wX,
    uint256 outY, uint256 pY, uint256 qY, uint256 wY,
    uint256 k) internal pure returns (bool) {

    uint256 invariantBefore;
    uint256 invariantAfter;
    {
      uint256 pqX = pX * qX / ONE_IN_PRICE_DECIMALS;
      uint256 pqwXk = fractionalPow(pqX * wX, k);
      if (pqwXk > 0) {
        invariantBefore += (ONE_IN_DEFAULT_DECIMALS * pqX) / pqwXk;
      }

      uint256 pqY = pY * qY / ONE_IN_PRICE_DECIMALS;
      uint256 pqwYk = fractionalPow(pqY * wY, k);
      if (pqwYk > 0) {
        invariantBefore += (ONE_IN_DEFAULT_DECIMALS * pqY) / pqwYk;
      }
    }
    {
      uint256 pqXinX = (pX * (qX + inX)) / ONE_IN_PRICE_DECIMALS;
      uint256 pqwXinXk = fractionalPow(pqXinX * wX, k);
      if (pqwXinXk > 0) {
        invariantAfter += (ONE_IN_DEFAULT_DECIMALS * pqXinX) / pqwXinXk;
      }

      uint256 pqYoutY = pY * (qY - outY) / ONE_IN_PRICE_DECIMALS;
      uint256 pqwYoutYk = fractionalPow(pqYoutY * wY, k);
      if (pqwYoutYk > 0) {
        invariantAfter += (ONE_IN_DEFAULT_DECIMALS * pqYoutY) / pqwYoutYk;
      }
    }
    return invariantAfter > invariantBefore;
  }

  function fractionalPow(uint256 input, uint256 pow) internal pure returns (uint256) {
    if (input == 0) {
      return 0;
    } else {
      // input^(pow/1e18) -> exp2( (pow * log2( input ) / 1e18 ) )
      return exp2((int256(pow) * log2(input.toInt256())) / SIGNED_ONE_IN_DEFAULT_DECIMALS);
    }
  }

  function exp2(int256 x) internal pure returns (uint256) {
    return x.exp2().toUint256();
  }

  function log2(int256 x) internal pure returns (int256 y) {
    y = x.log2();
  }

  // Don't need a separate "transmit" function here since it's already payable
  // Gas optimized - no balance checks
  // Don't need fairOutput checks since exactly inputAmount is wrapped
  function sellEthForToken(address outputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData) external override receivedInTime(goodUntil) payable {
    /* CHECKS */
    require(isToken(outputToken), "Clipper: Invalid token");
    // Wrap ETH (as balance or value) as input. This will revert if insufficient balance is provided
    safeEthSend(WRAPPER_CONTRACT, inputAmount);
    // Revert if it's signed by the wrong address    
    bytes32 digest = createSwapDigest(WRAPPER_CONTRACT, outputToken, inputAmount, outputAmount, goodUntil, destinationAddress);
    verifyDigestSignature(digest, theSignature);

    if(inputRequiresVerification(goodUntil)) {
      require(unpackAndCheckInvariant(WRAPPER_CONTRACT, inputAmount, outputToken, outputAmount, goodUntil) >= block.timestamp,
          "Clipper: Expired");
    }

    /* EFFECTS */
    increaseBalance(WRAPPER_CONTRACT, inputAmount);
    decreaseBalance(outputToken, outputAmount);

    /* INTERACTIONS */
    IERC20(outputToken).safeTransfer(destinationAddress, outputAmount);

    emit Swapped(WRAPPER_CONTRACT, outputToken, destinationAddress, inputAmount, outputAmount, auxiliaryData);
  }

  // Mostly copied from gas-optimized swap functionality
  function sellTokenForEth(address inputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData) external override receivedInTime(goodUntil) {
    /* CHECKS */
    require(isToken(inputToken), "Clipper: Invalid token");
    // Revert if it's signed by the wrong address    
    bytes32 digest = createSwapDigest(inputToken, WRAPPER_CONTRACT, inputAmount, outputAmount, goodUntil, destinationAddress);
    verifyDigestSignature(digest, theSignature);
    
    // Check that enough input token has been transmitted
    uint256 currentInputBalance = tokenBalance(inputToken);
    uint256 actualInput = currentInputBalance - getLastBalance(inputToken);
    uint256 fairOutput = calculateFairOutput(inputAmount, actualInput, outputAmount);

    if(inputRequiresVerification(goodUntil)) {
      require(unpackAndCheckInvariant(inputToken, actualInput, WRAPPER_CONTRACT, fairOutput, goodUntil) >= block.timestamp,
          "Clipper: Expired");
    }

    /* EFFECTS */
    setBalance(inputToken, currentInputBalance);
    decreaseBalance(WRAPPER_CONTRACT, fairOutput);

    /* INTERACTIONS */
    // Unwrap and forward ETH, without sync
    WrapperContractInterface(WRAPPER_CONTRACT).withdraw(fairOutput);
    safeEthSend(destinationAddress, fairOutput);

    emit Swapped(inputToken, WRAPPER_CONTRACT, destinationAddress, actualInput, fairOutput, auxiliaryData);
  }

  // Gas optimized, no balance checks
  // No need to check fairOutput since the inputToken pull works
  function transmitAndSellTokenForEth(address inputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData) external override receivedInTime(goodUntil) {
    /* CHECKS */
    require(isToken(inputToken), "Clipper: Invalid token");
    // Will revert if msg.sender has insufficient balance
    IERC20(inputToken).safeTransferFrom(msg.sender, address(this), inputAmount);
    // Revert if it's signed by the wrong address    
    bytes32 digest = createSwapDigest(inputToken, WRAPPER_CONTRACT, inputAmount, outputAmount, goodUntil, destinationAddress);
    verifyDigestSignature(digest, theSignature);

    if(inputRequiresVerification(goodUntil)) {
      require(unpackAndCheckInvariant(inputToken, inputAmount, WRAPPER_CONTRACT, outputAmount, goodUntil) >= block.timestamp,
          "Clipper: Expired");
    }

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
  function transmitAndSwap(address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData) external override receivedInTime(goodUntil) {
    /* CHECKS */
    require(isToken(inputToken) && isToken(outputToken), "Clipper: Invalid tokens");
    // Will revert if msg.sender has insufficient balance
    IERC20(inputToken).safeTransferFrom(msg.sender, address(this), inputAmount);
    // Revert if it's signed by the wrong address    
    bytes32 digest = createSwapDigest(inputToken, outputToken, inputAmount, outputAmount, goodUntil, destinationAddress);
    verifyDigestSignature(digest, theSignature);

    if(inputRequiresVerification(goodUntil)) {
      require(unpackAndCheckInvariant(inputToken, inputAmount, outputToken, outputAmount, goodUntil) >= block.timestamp,
          "Clipper: Expired");
    }

    /* EFFECTS */
    increaseBalance(inputToken, inputAmount);
    decreaseBalance(outputToken, outputAmount);

    /* INTERACTIONS */
    IERC20(outputToken).safeTransfer(destinationAddress, outputAmount);

    emit Swapped(inputToken, outputToken, destinationAddress, inputAmount, outputAmount, auxiliaryData);
  }

  // Gas optimized - single token balance check for input
  // output is dead-reckoned and scaled back if necessary
  function swap(address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData) public override receivedInTime(goodUntil) {
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

    if(inputRequiresVerification(goodUntil)) {
      require(unpackAndCheckInvariant(inputToken, actualInput, outputToken, fairOutput, goodUntil) >= block.timestamp,
          "Clipper: Expired");
    }

    /* EFFECTS */
    setBalance(inputToken, currentInputBalance);
    decreaseBalance(outputToken, fairOutput);

    /* INTERACTIONS */
    IERC20(outputToken).safeTransfer(destinationAddress, fairOutput);

    emit Swapped(inputToken, outputToken, destinationAddress, actualInput, fairOutput, auxiliaryData);
  }

}