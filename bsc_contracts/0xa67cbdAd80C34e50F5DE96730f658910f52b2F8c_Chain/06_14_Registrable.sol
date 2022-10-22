//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IRegistry.sol";
import "../interfaces/IStakingBank.sol";

/// @dev Any contract that we want to register in ContractRegistry, must inherit from Registrable
abstract contract Registrable {
    IRegistry public immutable contractRegistry;

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

    constructor(IRegistry _contractRegistry) {
        require(address(_contractRegistry) != address(0x0), "_registry is empty");
        contractRegistry = _contractRegistry;
    }

    /// @dev this method will be called as a first method in registration process when old contract will be replaced
    /// when called, old contract address is still in registry
    function register() virtual external;

    /// @dev this method will be called as a last method in registration process when old contract will be replaced
    /// when called, new contract address is already in registry
    function unregister() virtual external;

    /// @return contract name as bytes32
    function getName() virtual external pure returns (bytes32);

    /// @dev helper method for fetching StakingBank address
    function stakingBankContract() public view returns (IStakingBank) {
        return IStakingBank(contractRegistry.requireAndGetAddress("StakingBank"));
    }

    /// @dev helper method for fetching UMB address
    function tokenContract() public view withRegistrySetUp returns (ERC20) {
        return ERC20(contractRegistry.requireAndGetAddress("UMB"));
    }
}