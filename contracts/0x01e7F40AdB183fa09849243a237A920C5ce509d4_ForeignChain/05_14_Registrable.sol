//SPDX-License-Identifier: MIT
pragma solidity 0.6.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IRegistry.sol";
import "../interfaces/IStakingBank.sol";

abstract contract Registrable {
  IRegistry public contractRegistry;

  // ========== CONSTRUCTOR ========== //

  constructor(address _contractRegistry) internal {
    require(_contractRegistry != address(0x0), "_registry is empty");
    contractRegistry = IRegistry(_contractRegistry);
  }

  // ========== MODIFIERS ========== //

  modifier onlyFromContract(address _msgSender, bytes32 _contractName) {
    require(
      contractRegistry.getAddress(_contractName) == _msgSender,
        string(abi.encodePacked("caller is not ", _contractName))
    );
    _;
  }

  modifier withRegistrySetUp() {
    require(address(contractRegistry) != address(0x0), "_registry is empty");
    _;
  }

  // ========== MUTATIVE ========== //

  function register() virtual external {
    // this is required only for ForeignChain
    // but for backward compatibility the body is implemented as empty
    // also note, that in order to use this method, we need new registry
  }

  function unregister() virtual external {
    // this is required only for ForeignChain
    // but for backward compatibility the body is implemented as empty
    // also note, that in order to use this method, we need new registry
  }

  // ========== VIEWS ========== //

  function getName() virtual external pure returns (bytes32);

  function stakingBankContract() public view returns (IStakingBank) {
    return IStakingBank(contractRegistry.requireAndGetAddress("StakingBank"));
  }

  function tokenContract() public view withRegistrySetUp returns (ERC20) {
    return ERC20(contractRegistry.requireAndGetAddress("UMB"));
  }
}