// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @dev Interface used to make a custom mint with whitelist and batch mint after freemint
 *
 *
 *
 */
interface IERC721Custom {

  /**
  * @dev Function use to check a merkle proof with the whitelist stored in contract
  *
  * - `address to`: address of the wallet
  * - `bytes32[] _merkleProof`: Proof use to check with the merkle root
  *
  */
  function checkMerkleProof(address to, bytes32[] calldata _merkleProof) external view returns(bool);

  /**
  * @dev Function use to airdrop token
  *
  * - `address to`: address of the wallet
  * - `bytes32[] _merkleProof`: Proof use to check with the merkle root
  *
  * Requirements:
  *
  * - Caller must be Admin
  */
  function mintWhitelist(address to, bytes32[] calldata _merkleProof) external;

  /**
  * @dev Function use to free mint token 1 by 1
  *
  * - `address to`: address of the wallet
  *
  * Requirements:
  *
  * - TotalSupply must be lower than freemintLimit
  * - Airdrop must be done
  */
  function freeMint(address to) external;

  /**
  * @dev Function use to mint token payable in batchmint 1 to 5
  *
  * - `address to`: address of the wallet
  * - `uint256 amount`: Amount of token to mint
  *
  * Requirements:
  *
  * - TotalSupply + amount must be lower than maxSupply
  * - TotalSupply must be greater than freemintLimit
  * - Airdrop must be done
  */
  function payableMint(address to, uint256 amount) external payable;

  /**
  * @dev Function use to mint
  *
  * It will automatically dispatch to the free or payable mint
  * each free or payable have requirements and must failed if you cant mint
  */
  function mint(uint256 amount) external payable;

  /**
  * @dev Function use to get back the fund
  *
  * - `address to`: address of the wallet
  *
  * Requirements:
  *
  * - Caller must be Admin
  */
  function withdrawFund(address to) external;

  /**
  * @dev Function use to set airdrop done
  *
  * Requirements:
  *
  * - Caller must be Admin
  */
  function setAirdropDone(bool _state) external;
}