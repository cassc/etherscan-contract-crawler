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
 *    NftApprovalSwapVerifier.sol :: 0x47b16A209c757FA4A34BbfBbE48204906C4FDE5d
 *    etherscan.io verified 2022-09-27
 */ 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../Interfaces/ICallExecutor.sol";
import "../Libraries/Bit.sol";
import "../Libraries/NativeOrERC20.sol";

/// @title Verifier for ERC721 swaps using ERC721.approve()
/// @notice These functions should be executed by metaPartialSignedDelegateCall() on Brink account proxy contracts
contract NftApprovalSwapVerifier {
  using NativeOrERC20 for address;

  ICallExecutor constant CALL_EXECUTOR = ICallExecutor(0xDE61dfE5fbF3F4Df70B16D0618f69B96A2754bf8);

  /// @dev Verifies swap from fungible token (ERC20 or Native) to ERC721
  /// @notice This should be executed by metaDelegateCall() or metaDelegateCall_EIP1271() with the following signed and unsigned params
  /// @param bitmapIndex The index of the replay bit's bytes32 slot [signed]
  /// @param bit The value of the replay bit [signed]
  /// @param tokenIn The input token provided for the swap. Can be ERC20 or Native [signed]
  /// @param nftOut The ERC721 output token required to be received from the swap [signed]
  /// @param tokenInAmount Amount of tokenIn provided [signed]
  /// @param expiryBlock The block when the swap expires [signed]
  /// @param recipient Address of the recipient of the token input [unsigned]
  /// @param to Address of the contract that will fulfill the swap [unsigned]
  /// @param data Data to execute on the `to` contract to fulfill the swap [unsigned]
  function tokenToNft(
    uint256 bitmapIndex, uint256 bit, address tokenIn, IERC721 nftOut, uint256 tokenInAmount, uint256 expiryBlock, address recipient,
    address to, bytes calldata data
  )
    external
  {
    require(expiryBlock > block.number, 'Expired');
  
    Bit.useBit(bitmapIndex, bit);

    address owner = proxyOwner();

    uint256 nftOutBalance = nftOut.balanceOf(owner);

    IERC20(tokenIn).transferFrom(owner, recipient, tokenInAmount);
    CALL_EXECUTOR.proxyCall(to, data);

    uint256 nftOutAmountReceived = nftOut.balanceOf(owner) - nftOutBalance;
    require(nftOutAmountReceived >= 1, 'NotEnoughReceived');
  }

  /// @dev Verifies swap from a single ERC721 ID to fungible token (ERC20 or Native)
  /// @notice This should be executed by metaDelegateCall() or metaDelegateCall_EIP1271() with the following signed and unsigned params
  /// @param bitmapIndex The index of the replay bit's bytes32 slot [signed]
  /// @param bit The value of the replay bit [signed]
  /// @param nftIn The ERC721 input token provided for the swap [signed]
  /// @param tokenOut The output token required to be received from the swap. Can be ERC20 or Native [signed]
  /// @param nftInID The ID of the nftIn token provided [signed]
  /// @param tokenOutAmount Amount of tokenOut required to be received [signed]
  /// @param expiryBlock The block when the swap expires [signed]
  /// @param recipient Address of the recipient of the nft input [unsigned]
  /// @param to Address of the contract that will fulfill the swap [unsigned]
  /// @param data Data to execute on the `to` contract to fulfill the swap [unsigned]
  function nftToToken(
    uint256 bitmapIndex, uint256 bit, IERC721 nftIn, address tokenOut, uint256 nftInID, uint256 tokenOutAmount, uint256 expiryBlock,
    address recipient, address to, bytes calldata data
  )
    external
  {
    require(expiryBlock > block.number, 'Expired');
  
    Bit.useBit(bitmapIndex, bit);

    address owner = proxyOwner();

    uint256 tokenOutBalance = tokenOut.balanceOf(owner);

    nftIn.transferFrom(owner, recipient, nftInID);
    CALL_EXECUTOR.proxyCall(to, data);

    uint256 tokenOutAmountReceived = tokenOut.balanceOf(owner) - tokenOutBalance;
    require(tokenOutAmountReceived >= tokenOutAmount, 'NotEnoughReceived');
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