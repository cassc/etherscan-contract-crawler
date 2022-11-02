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
 *    ApprovalSwapsV1.sol :: 0x9A7B09e63FD17a36e5Ab187a5D7B75149fEBFa53
 *    etherscan.io verified 2022-11-01
 */ 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@brinkninja/verifiers/contracts/Interfaces/ICallExecutor.sol";
import "@brinkninja/verifiers/contracts/Libraries/Bit.sol";

/// @title Verifier functions for swaps that use token approvals for input asset transfer
/// @notice These functions should be executed by metaDelegateCall() on Brink account proxy contracts
contract ApprovalSwapsV1 {
  /// @dev Revert when swap is expired
  error Expired();

  /// @dev Revert when swap has not received enough of the output asset to be fulfilled
  error NotEnoughReceived(uint256 amountReceived);

  ICallExecutor constant CALL_EXECUTOR_V2 = ICallExecutor(0x6FE756B9C61CF7e9f11D96740B096e51B64eBf13);

  /// @dev Executes an ERC20 to token (ERC20 or Native ETH) limit swap
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
    uint256 bitmapIndex, uint256 bit, IERC20 tokenIn, address tokenOut, uint256 tokenInAmount, uint256 tokenOutAmount,
    uint256 expiryBlock, address recipient, address to, bytes calldata data
  )
    external
  {
    if (expiryBlock <= block.number) {
      revert Expired();
    }
  
    Bit.useBit(bitmapIndex, bit);

    address owner = proxyOwner();

    uint256 tokenOutBalance = balanceOf(tokenOut, owner);

    IERC20(tokenIn).transferFrom(owner, recipient, tokenInAmount);

    CALL_EXECUTOR_V2.proxyCall(to, data);

    uint256 tokenOutAmountReceived = balanceOf(tokenOut, owner) - tokenOutBalance;
    if (tokenOutAmountReceived < tokenOutAmount) {
      revert NotEnoughReceived(tokenOutAmountReceived);
    }
  }

  /// @dev Verifies swap from ERC20 token to ERC721
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
    uint256 bitmapIndex, uint256 bit, IERC20 tokenIn, IERC721 nftOut, uint256 tokenInAmount, uint256 expiryBlock, address recipient,
    address to, bytes calldata data
  )
    external
  {
    require(expiryBlock > block.number, 'Expired');
  
    Bit.useBit(bitmapIndex, bit);

    address owner = proxyOwner();

    uint256 nftOutBalance = nftOut.balanceOf(owner);

    tokenIn.transferFrom(owner, recipient, tokenInAmount);
    CALL_EXECUTOR_V2.proxyCall(to, data);

    uint256 nftOutAmountReceived = nftOut.balanceOf(owner) - nftOutBalance;
    if (nftOutAmountReceived < 1) {
      revert NotEnoughReceived(nftOutAmountReceived);
    }
  }

  /// @dev Verifies swap from a single ERC721 ID to fungible token (ERC20 or Native)
  /// @notice This should be executed by metaDelegateCall() or metaDelegateCall_EIP1271() with the following signed and unsigned params
  /// @param bitmapIndex The index of the replay bit's bytes32 slot [signed]
  /// @param bit The value of the replay bit [signed]
  /// @param nftIn The ERC721 input token provided for the swap [signed]
  /// @param tokenOut The output token required to be received from the swap. Can be ERC20 or Native [signed]
  /// @param nftInId The ID of the nftIn token provided [signed]
  /// @param tokenOutAmount Amount of tokenOut required to be received [signed]
  /// @param expiryBlock The block when the swap expires [signed]
  /// @param recipient Address of the recipient of the nft input [unsigned]
  /// @param to Address of the contract that will fulfill the swap [unsigned]
  /// @param data Data to execute on the `to` contract to fulfill the swap [unsigned]
  function nftToToken(
    uint256 bitmapIndex, uint256 bit, IERC721 nftIn, address tokenOut, uint256 nftInId, uint256 tokenOutAmount, uint256 expiryBlock,
    address recipient, address to, bytes calldata data
  )
    external
  {
    require(expiryBlock > block.number, 'Expired');
  
    Bit.useBit(bitmapIndex, bit);

    address owner = proxyOwner();

    uint256 tokenOutBalance = balanceOf(tokenOut, owner);

    nftIn.transferFrom(owner, recipient, nftInId);
    CALL_EXECUTOR_V2.proxyCall(to, data);

    uint256 tokenOutAmountReceived = balanceOf(tokenOut, owner) - tokenOutBalance;
    if(tokenOutAmountReceived < tokenOutAmount) {
      revert NotEnoughReceived(tokenOutAmountReceived);
    }
  }

  /// @dev Verifies swap from an ERC20 token to an ERC1155 token
  /// @notice This should be executed by metaDelegateCall() or metaDelegateCall_EIP1271() with the following signed and unsigned params
  /// @param bitmapIndex The index of the replay bit's bytes32 slot [signed]
  /// @param bit The value of the replay bit [signed]
  /// @param tokenIn The ERC20 input token provided for the swap [signed]
  /// @param tokenInAmount Amount of tokenIn provided [signed]
  /// @param tokenOut The address of the ERC1155 output token required to be received [signed]
  /// @param tokenOutId The ID of the ERC1155 output token required to be received [signed]
  /// @param tokenOutAmount Amount of ERC1155 output token required to be received [signed]
  /// @param expiryBlock The block when the swap expires [signed]
  /// @param recipient Address of the recipient of the ERC20 input token [unsigned]
  /// @param to Address of the contract that will fulfill the swap [unsigned]
  /// @param data Data to execute on the `to` contract to fulfill the swap [unsigned]
  function tokenToERC1155(
    uint256 bitmapIndex, uint256 bit, IERC20 tokenIn, uint256 tokenInAmount, IERC1155 tokenOut, uint256 tokenOutId, uint256 tokenOutAmount, uint256 expiryBlock, address recipient,
    address to, bytes calldata data
  )
    external
  {
    require(expiryBlock > block.number, 'Expired');
  
    Bit.useBit(bitmapIndex, bit);

    address owner = proxyOwner();

    uint256 tokenOutBalance = tokenOut.balanceOf(owner, tokenOutId);

    tokenIn.transferFrom(owner, recipient, tokenInAmount);
    CALL_EXECUTOR_V2.proxyCall(to, data);

    uint256 tokenOutAmountReceived = tokenOut.balanceOf(owner, tokenOutId) - tokenOutBalance;
    if(tokenOutAmountReceived < tokenOutAmount) {
      revert NotEnoughReceived(tokenOutAmountReceived);
    }
  }

  /// @dev Verifies swap from an ERC1155 token to fungible token (ERC20 or Native)
  /// @notice This should be executed by metaDelegateCall() or metaDelegateCall_EIP1271() with the following signed and unsigned params
  /// @param bitmapIndex The index of the replay bit's bytes32 slot [signed]
  /// @param bit The value of the replay bit [signed]
  /// @param tokenIn The address of the ERC1155 input token provided for the swap [signed]
  /// @param tokenInId The ID of the ERC1155 input token provided for the swap [signed]
  /// @param tokenInAmount Amount of ERC1155 input token provided for the swap [signed]
  /// @param tokenOut The output token required to be received from the swap. Can be ERC20 or Native [signed]
  /// @param tokenOutAmount Amount of tokenOut required to be received [signed]
  /// @param expiryBlock The block when the swap expires [signed]
  /// @param recipient Address of the recipient of the ERC1155 input token [unsigned]
  /// @param to Address of the contract that will fulfill the swap [unsigned]
  /// @param data Data to execute on the `to` contract to fulfill the swap [unsigned]
  function ERC1155ToToken(
    uint256 bitmapIndex, uint256 bit, IERC1155 tokenIn, uint256 tokenInId, uint256 tokenInAmount, address tokenOut, uint256 tokenOutAmount, uint256 expiryBlock,
    address recipient, address to, bytes calldata data
  )
    external
  {
    require(expiryBlock > block.number, 'Expired');
  
    Bit.useBit(bitmapIndex, bit);

    address owner = proxyOwner();

    uint256 tokenOutBalance = balanceOf(tokenOut, owner);

    tokenIn.safeTransferFrom(owner, recipient, tokenInId, tokenInAmount, '');
    CALL_EXECUTOR_V2.proxyCall(to, data);

    uint256 tokenOutAmountReceived = balanceOf(tokenOut, owner) - tokenOutBalance;
    if(tokenOutAmountReceived < tokenOutAmount) {
      revert NotEnoughReceived(tokenOutAmountReceived);
    }
  }

  /// @dev Verifies swap from an ERC1155 token to another ERC1155 token
  /// @notice This should be executed by metaDelegateCall() or metaDelegateCall_EIP1271() with the following signed and unsigned params
  /// @param bitmapIndex The index of the replay bit's bytes32 slot [signed]
  /// @param bit The value of the replay bit [signed]
  /// @param tokenIn The address of the ERC1155 input token provided for the swap [signed]
  /// @param tokenInId The ID of the ERC1155 input token provided for the swap [signed]
  /// @param tokenInAmount Amount of ERC1155 input token provided for the swap [signed]
  /// @param tokenOut The address of the ERC1155 output token required to be received [signed]
  /// @param tokenOutId The ID of the ERC1155 output token required to be received [signed]
  /// @param tokenOutAmount Amount of ERC1155 output token required to be received [signed]
  /// @param expiryBlock The block when the swap expires [signed]
  /// @param recipient Address of the recipient of the ERC1155 input token [unsigned]
  /// @param to Address of the contract that will fulfill the swap [unsigned]
  /// @param data Data to execute on the `to` contract to fulfill the swap [unsigned]
  function ERC1155ToERC1155(
    uint256 bitmapIndex, uint256 bit, IERC1155 tokenIn, uint256 tokenInId, uint256 tokenInAmount, IERC1155 tokenOut, uint256 tokenOutId, uint256 tokenOutAmount, uint256 expiryBlock,
    address recipient, address to, bytes calldata data
  )
    external
  {
    require(expiryBlock > block.number, 'Expired');
  
    Bit.useBit(bitmapIndex, bit);

    address owner = proxyOwner();

    uint256 tokenOutBalance = tokenOut.balanceOf(owner, tokenOutId);

    tokenIn.safeTransferFrom(owner, recipient, tokenInId, tokenInAmount, '');
    CALL_EXECUTOR_V2.proxyCall(to, data);

    uint256 tokenOutAmountReceived = tokenOut.balanceOf(owner, tokenOutId) - tokenOutBalance;
    if(tokenOutAmountReceived < tokenOutAmount) {
      revert NotEnoughReceived(tokenOutAmountReceived);
    }
  }

  /// @dev Returns the owner balance of token, taking into account whether token is a native ETH representation or an ERC20
  /// @param token The token address. Can be 0x or 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE for ETH, or any valid ERC20 token address.
  /// @param owner The owner address to check balance for
  /// @return uint256 The token balance of owner
  function balanceOf(address token, address owner) internal view returns (uint256) {
    if (isEth(token)) {
      return owner.balance;
    } else {
      return IERC20(token).balanceOf(owner);
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

  /// @dev Returns true if the token address is a representation native ETH
  /// @param token The address to check
  /// @return bool True if the token address is a representation native ETH
  function isEth(address token) internal pure returns (bool) {
    return (token == address(0) || token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
  }
}