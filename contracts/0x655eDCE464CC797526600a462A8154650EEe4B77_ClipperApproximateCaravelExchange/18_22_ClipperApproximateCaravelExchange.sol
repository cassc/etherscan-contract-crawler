// SPDX-License-Identifier: UNLICENSED
// Copyright 2023 Shipyard Software, Inc.
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

import "./interfaces/WrapperContractInterface.sol";
import "./interfaces/TriageContractInterface.sol";

import "./ClipperCaravelExchange.sol";

contract ClipperApproximateCaravelExchange is ClipperCaravelExchange, ERC20Permit {
  using SafeERC20 for IERC20;

  uint256 constant ONE_IN_SIX_DECIMALS = 1e6;

  bool private _marketHalted;
  address public triageRole;

  error ClipperInvariant();

  event TriageAddressChanged(address indexed newAddress);

  function tokenName() internal pure override returns (string memory) {
    return "Clipper LP Token";
  }

  function tokenSymbol() internal pure override returns (string memory) {
    return "ClipperLP";
  }

  constructor(address theSigner, address theWrapper, address[] memory tokens)
    ClipperCaravelExchange(theSigner, theWrapper, tokens) ERC20Permit(tokenSymbol()) {
  }

  /*
    Triage emergency functionality.

    owner can set an address that has the ability to halt trade.
    Only proportional withdrawals are allowed if trade is halted.
  */
  function setTriageRole(address newTriage) external onlyOwner {
    triageRole = newTriage;
    emit TriageAddressChanged(newTriage);
  }

  function isTradeHalted() public view override returns (bool) {
    return _marketHalted;
  }

  function stopTrade() external {
    if(msg.sender==triageRole){
      _marketHalted = true;
    }
  }

  function resumeTrade() external {
    if(msg.sender==triageRole){
      _marketHalted = false;
    }
  }

  /* SWAP Functionality */

  // checks timestamp
  // return value: qX, qY
  function unpackAndCheckInvariant(address inputToken, address outputToken, uint256 packedGoodUntil) internal view receivedInTime(uint256(uint32(packedGoodUntil))) returns (uint256 qX, uint256 qY) {
    (uint256 offchainX, uint256 offchainY, uint256 maximumX, uint256 minimumY) = unpackGoodUntil(packedGoodUntil);
    qX = getLastBalance(inputToken);
    qY = getLastBalance(outputToken);

    if(!checkInvariant(qX, qY, offchainX, offchainY, maximumX, minimumY)){
      revert ClipperInvariant();
    }
  }

  function checkInvariant(uint256 qX, uint256 qY, uint256 offchainX, uint256 offchainY, uint256 maximumX, uint256 minimumY) internal pure returns (bool) {
    /*
      Nine regions in quantity space:
      qX: -- A -- offchainX --- B --- maximumX -- C --
      qY: -- 1 -- minimumY --- 2 ---- offchainY -- 3 --

      C1 -> fail (too much qX AND too little qY)
      C2,C3 -> fail (too much qX)
      A1,B1 -> fail (too little qY)
      A3 -> succeed (no or exclusively beneficial change from offchain state)
      A2,B3 -> succeed (allowable within slippage)
      B2 -> complex linear case
    */

    if(qY >= offchainY && qX <= offchainX){
      // Region A3
      return true;
    } else if(qY < minimumY || qX > maximumX) {
      // Regions C1, C2, C3, A1, B1
      return false;
    } else {
      if(qY >= offchainY){
        // Region B3
        return true;
      } else if(qX <= offchainX) {
        // Region A2
        return true;
      }
      else {
        // Region B2, complex linear case
        // qY is somewhere between minimumY and offchainY
        // qX is somewhere between offchainX and maximumX

        // between minimumY and offchainY, we go up maximumX - offchainX
        uint256 targetDiffX = ((ONE_IN_SIX_DECIMALS*(qY-minimumY)*(maximumX-offchainX))/(offchainY-minimumY))/ONE_IN_SIX_DECIMALS;
        return qX <= (offchainX + targetDiffX);
      }
    }
  }

  function unpackGoodUntil(uint256 packedGoodUntil) internal pure
    returns (uint256 offchainX, uint256 offchainY, uint256 maximumX, uint256 minimumY) {
    /*
        * Offchain balance input Token - uint96
        * Offchain balance output Token - uint96
        * Input multiplier - uint16
        * Output multiplier - uint16
        * Current good until value - uint32 - can be taken as uint256(uint32(packedGoodUntil))
    */
    // goodUntil = uint256(uint32(packedGoodUntil));
    offchainX = uint256(packedGoodUntil >> 160);
    offchainY = uint256(uint96(packedGoodUntil >> 64));
    uint256 rawMultX = uint256(uint16(packedGoodUntil >> 48));
    uint256 rawMultY = uint256(uint16(packedGoodUntil >> 32));

    maximumX = ((ONE_IN_SIX_DECIMALS+rawMultX)*offchainX)/ONE_IN_SIX_DECIMALS;
    minimumY = ((ONE_IN_SIX_DECIMALS-rawMultY)*offchainY)/ONE_IN_SIX_DECIMALS;
  }

  // Don't need a separate "transmit" function here since it's already payable
  // Gas optimized - no balance checks
  // Don't need fairOutput checks since exactly inputAmount is wrapped
  function sellEthForToken(address outputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData) external override marketIsRunning payable {
    /* CHECKS */
    // Wrap ETH (as balance or value) as input. This will revert if insufficient balance is provided
    safeEthSend(WRAPPER_CONTRACT, inputAmount);
    // Revert if it's signed by the wrong address
    bytes32 digest = createSwapDigest(WRAPPER_CONTRACT, outputToken, inputAmount, outputAmount, goodUntil, destinationAddress);
    verifyDigestSignature(digest, theSignature);

    (uint256 qX, uint256 qY) = unpackAndCheckInvariant(WRAPPER_CONTRACT, outputToken, goodUntil);

    /* EFFECTS */
    setBalance(WRAPPER_CONTRACT, qX+inputAmount);
    setBalance(outputToken, qY-outputAmount);

    /* INTERACTIONS */
    IERC20(outputToken).safeTransfer(destinationAddress, outputAmount);

    emit Swapped(WRAPPER_CONTRACT, outputToken, destinationAddress, inputAmount, outputAmount, auxiliaryData);
  }

  // Mostly copied from gas-optimized swap functionality
  function sellTokenForEth(address inputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData) external override marketIsRunning {
    /* CHECKS */
    // Revert if it's signed by the wrong address
    bytes32 digest = createSwapDigest(inputToken, WRAPPER_CONTRACT, inputAmount, outputAmount, goodUntil, destinationAddress);
    verifyDigestSignature(digest, theSignature);

    (uint256 qX, uint256 qY) = unpackAndCheckInvariant(inputToken, WRAPPER_CONTRACT, goodUntil);
    // Check that enough input token has been transmitted
    uint256 currentInputBalance = tokenBalance(inputToken);
    uint256 actualInput = currentInputBalance - qX;
    uint256 fairOutput = calculateFairOutput(inputAmount, actualInput, outputAmount);

    /* EFFECTS */
    setBalance(inputToken, currentInputBalance);
    setBalance(WRAPPER_CONTRACT, qY-fairOutput);

    /* INTERACTIONS */
    // Unwrap and forward ETH, without sync
    WrapperContractInterface(WRAPPER_CONTRACT).withdraw(fairOutput);
    safeEthSend(destinationAddress, fairOutput);

    emit Swapped(inputToken, WRAPPER_CONTRACT, destinationAddress, actualInput, fairOutput, auxiliaryData);
  }

  // Gas optimized, no balance checks
  // No need to check fairOutput since the inputToken pull works
  function transmitAndSellTokenForEth(address inputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData) external override marketIsRunning {
    /* CHECKS */
    // Will revert if msg.sender has insufficient balance
    IERC20(inputToken).safeTransferFrom(msg.sender, address(this), inputAmount);
    // Revert if it's signed by the wrong address
    bytes32 digest = createSwapDigest(inputToken, WRAPPER_CONTRACT, inputAmount, outputAmount, goodUntil, destinationAddress);
    verifyDigestSignature(digest, theSignature);

    (uint256 qX, uint256 qY) = unpackAndCheckInvariant(inputToken, WRAPPER_CONTRACT, goodUntil);

    /* EFFECTS */
    setBalance(inputToken, qX+inputAmount);
    setBalance(WRAPPER_CONTRACT, qY-outputAmount);

    /* INTERACTIONS */
    // Unwrap and forward ETH, we've already updated the balance
    WrapperContractInterface(WRAPPER_CONTRACT).withdraw(outputAmount);
    safeEthSend(destinationAddress, outputAmount);

    emit Swapped(inputToken, WRAPPER_CONTRACT, destinationAddress, inputAmount, outputAmount, auxiliaryData);
  }

  // all-in-one transfer from msg.sender to destinationAddress.
  // Gas optimized - never checks balances
  // No need to check fairOutput since the inputToken pull works
  function transmitAndSwap(address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData) external override marketIsRunning {
    /* CHECKS */
    // Will revert if msg.sender has insufficient balance
    IERC20(inputToken).safeTransferFrom(msg.sender, address(this), inputAmount);
    // Revert if it's signed by the wrong address
    bytes32 digest = createSwapDigest(inputToken, outputToken, inputAmount, outputAmount, goodUntil, destinationAddress);
    verifyDigestSignature(digest, theSignature);

    (uint256 qX, uint256 qY) = unpackAndCheckInvariant(inputToken, outputToken, goodUntil);

    /* EFFECTS */
    setBalance(inputToken, qX+inputAmount);
    setBalance(outputToken, qY-outputAmount);

    /* INTERACTIONS */
    IERC20(outputToken).safeTransfer(destinationAddress, outputAmount);

    emit Swapped(inputToken, outputToken, destinationAddress, inputAmount, outputAmount, auxiliaryData);
  }

  // Gas optimized - single token balance check for input
  // output is dead-reckoned and scaled back if necessary
  function swap(address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData) public override marketIsRunning {
    /* CHECKS */
    { // Avoid stack too deep
    // Revert if it's signed by the wrong address
    bytes32 digest = createSwapDigest(inputToken, outputToken, inputAmount, outputAmount, goodUntil, destinationAddress);
    verifyDigestSignature(digest, theSignature);
    }
    (uint256 qX, uint256 qY) = unpackAndCheckInvariant(inputToken, outputToken, goodUntil);
    // Get fair output value
    uint256 currentInputBalance = tokenBalance(inputToken);
    uint256 actualInput = currentInputBalance-qX;
    uint256 fairOutput = calculateFairOutput(inputAmount, actualInput, outputAmount);

    /* EFFECTS */
    setBalance(inputToken, currentInputBalance);
    setBalance(outputToken, qY-fairOutput);

    /* INTERACTIONS */
    IERC20(outputToken).safeTransfer(destinationAddress, fairOutput);

    emit Swapped(inputToken, outputToken, destinationAddress, actualInput, fairOutput, auxiliaryData);
  }

}