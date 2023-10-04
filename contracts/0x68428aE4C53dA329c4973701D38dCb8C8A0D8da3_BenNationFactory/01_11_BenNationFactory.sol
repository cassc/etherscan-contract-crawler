// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Ownable} from "./oz/access/Ownable.sol";
import {IERC20Metadata} from "./oz/token/ERC20/extensions/IERC20Metadata.sol";

import {BenNationInitializable} from "./BenNationInitializable.sol";
import {BenNationVault} from "./BenNationVault.sol";

contract BenNationFactory is Ownable {
  event NewBenNationContract(address indexed smartChef, address indexed vault);

  /*
   * @notice Deploy the pool
   * @param _stakedToken: staked token address
   * @param _rewardToken: reward token address
   * @param _rewardPerBlock: reward per block (in rewardToken)
   * @param _startBlock: start block
   * @param _endBlock: end block
   * @param _poolLimitPerUser: pool limit per user in stakedToken (if any, else 0)
   * @param _numberBlocksForUserLimit: block numbers available for user limit (after start block)
   * @param _admin: admin address with ownership
   */
  function deployPool(
    IERC20Metadata _stakedToken,
    IERC20Metadata _rewardToken,
    uint256 _rewardPerBlock,
    uint256 _startBlock,
    uint256 _endBlock,
    uint256 _poolLimitPerUser,
    uint256 _numberBlocksForUserLimit,
    address _admin
  ) external onlyOwner {
    bytes32 salt = keccak256(abi.encodePacked(_stakedToken, _rewardToken, _startBlock));
    address benNationAddress;
    {
      bytes memory bytecode = type(BenNationInitializable).creationCode;

      assembly ("memory-safe") {
        benNationAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
      }
    }

    address vault;
    if (_stakedToken == _rewardToken) {
      bytes memory bytecode = type(BenNationVault).creationCode;
      assembly ("memory-safe") {
        vault := create2(0, add(bytecode, 32), mload(bytecode), salt)
      }
      BenNationVault(vault).transferOwnership(benNationAddress);
    }

    BenNationInitializable(benNationAddress).initialize(
      _stakedToken,
      _rewardToken,
      _rewardPerBlock,
      _startBlock,
      _endBlock,
      _poolLimitPerUser,
      _numberBlocksForUserLimit,
      vault,
      _admin
    );

    emit NewBenNationContract(benNationAddress, vault);
  }
}