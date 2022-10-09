// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

/**
 *    ,,                           ,,                                
 *   *MM                           db                      `7MM      
 *    MM                                                     MM      
 *    MM,dMMb.      `7Mb,od8     `7MM      `7MMpMMMb.        MM  ,MP'
 *    MM    `Mb       MM' "'       MM        MM    MM        MM ;Y   
 *    MM     M8       MM           MM        MM    MM        MM;Mm   
 *    MM.   ,M9       MM           MM        MM    MM        MM `Mb. 
 *    P^YbmdP'      .JMML.       .JMML.    .JMML  JMML.    .JMML. YA.
 *
 *    LimitApprovalSwapVerifier.sol :: 0x89d2D7803f8DC44eD24dCCeBE4222E35B0756a33
 *    etherscan.io verified 2022-10-08
 */ 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Interfaces/ICallExecutor.sol";
import "../Libraries/Bit.sol";

/// @title Verifier for ERC20 limit swaps
/// @notice These functions should be executed by metaPartialSignedDelegateCall() on Brink account proxy contracts
contract LimitApprovalSwapVerifier {
  /// @dev Revert when limit swap is expired
  error Expired();

  /// @dev Revert when swap has not received enough of the output asset to be fulfilled
  error NotEnoughReceived(uint256 amountReceived);

  ICallExecutor constant CALL_EXECUTOR = ICallExecutor(0xDE61dfE5fbF3F4Df70B16D0618f69B96A2754bf8);

  /// @dev Executes an ERC20 to ERC20 limit swap
  /// @notice This should be executed by metaDelegateCall() or metaDelegateCall_EIP1271() with the following signed and unsigned params
  /// @param bitmapIndex The index of the replay bit's bytes32 slot [signed]
  /// @param bit The value of the replay bit [signed]
  /// @param tokenIn The input token provided for the swap [signed]
  /// @param tokenOut The output token required to be received from the swap [signed]
  /// @param tokenInAmount Amount of tokenIn provided [signed]
  /// @param tokenOutAmount Amount of tokenOut required to be received [signed]
  /// @param expiryBlock The block when the swap expires [signed]
  /// @param recipient Address of the recipient of the token input [unsigned]
  /// @param to Address of the contract that will fulfill the swap [unsigned]
  /// @param data Data to execute on the `to` contract to fulfill the swap [unsigned]
  function tokenToToken(
    uint256 bitmapIndex, uint256 bit, IERC20 tokenIn, IERC20 tokenOut, uint256 tokenInAmount, uint256 tokenOutAmount,
    uint256 expiryBlock, address recipient, address to, bytes calldata data
  )
    external
  {
    if (expiryBlock <= block.number) {
      revert Expired();
    }
  
    Bit.useBit(bitmapIndex, bit);

    address owner = proxyOwner();

    uint256 tokenOutBalance = tokenOut.balanceOf(owner);

    IERC20(tokenIn).transferFrom(owner, recipient, tokenInAmount);

    CALL_EXECUTOR.proxyCall(to, data);

    uint256 tokenOutAmountReceived = tokenOut.balanceOf(owner) - tokenOutBalance;
    if (tokenOutAmountReceived < tokenOutAmount) {
      revert NotEnoughReceived(tokenOutAmountReceived);
    }
  }


  /// @dev Executes an ERC20 to ETH limit swap
  /// @notice This should be executed by metaDelegateCall() or metaDelegateCall_EIP1271() with the following signed and unsigned params
  /// @param bitmapIndex The index of the replay bit's bytes32 slot [signed]
  /// @param bit The value of the replay bit [signed]
  /// @param token The input token provided for the swap [signed]
  /// @param tokenAmount Amount of tokenIn provided [signed]
  /// @param ethAmount Amount of ETH to receive [signed]
  /// @param expiryBlock The block when the swap expires [signed]
  /// @param recipient Address of the recipient of the token input [unsigned]
  /// @param to Address of the contract that will fulfill the swap [unsigned]
  /// @param data Data to execute on the `to` contract to fulfill the swap [unsigned]
  function tokenToEth(
    uint256 bitmapIndex, uint256 bit, IERC20 token, uint256 tokenAmount, uint256 ethAmount, uint256 expiryBlock,
    address recipient, address to, bytes calldata data
  )
    external
  {
    if (expiryBlock <= block.number) {
      revert Expired();
    }

    Bit.useBit(bitmapIndex, bit);

    address owner = proxyOwner();
    
    uint256 ethBalance = address(owner).balance;

    IERC20(token).transferFrom(owner, recipient, tokenAmount);

    CALL_EXECUTOR.proxyCall(to, data);

    uint256 ethAmountReceived = address(owner).balance - ethBalance;
    if (ethAmountReceived < ethAmount) {
      revert NotEnoughReceived(ethAmountReceived);
    }
  }

  /// @dev Returns the owner address for the proxy
  /// @return _proxyOwner The owner address for the proxy
  function proxyOwner() internal view returns (address _proxyOwner) {
    assembly {
      // copies to "scratch space" 0 memory pointer
      extcodecopy(address(), 0, 0x28, 0x14)
      _proxyOwner := shr(0x60, mload(0))
    }
  }
}