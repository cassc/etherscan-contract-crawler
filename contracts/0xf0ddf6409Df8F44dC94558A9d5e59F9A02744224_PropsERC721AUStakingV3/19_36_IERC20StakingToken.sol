// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ISignatureMinting.sol";

interface IERC20StakingToken {
   function issueTokens(address _to, uint256 _amount) external;
   function getSignatureVerifier() external view returns (address);
   function revertOnInvalidMintSignature(address sender,  ISignatureMinting.SignatureMintCartItem memory cartItem) external view;
   function logMintActivity(string memory uid, address wallet_address, uint256 incrementalQuantity) external;
   function getMintedByUid(string calldata _uid, address _wallet) external view returns (uint256);
}