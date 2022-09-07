// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./SwapSetters.sol";
import "./SwapGetters.sol";

contract SwapGovernance is SwapSetters, SwapGetters, ERC1967Upgrade  {
    event ContractUpgraded(address indexed oldContract, address indexed newContract);

    /// @dev upgrade serves to upgrade contract implementations
    function upgrade(address newImplementation) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");

        address currentImplementation = _getImplementation();

        _upgradeTo(newImplementation);

        /// @dev call initialize function of the new implementation
        (bool success, bytes memory reason) = newImplementation.delegatecall(abi.encodeWithSignature("initialize()"));

        require(success, string(reason));

        emit ContractUpgraded(currentImplementation, newImplementation);
    }

    function updateFeePercent(uint256 _feePercent) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        require(_feePercent <= 3000, "Atlas Dex:  Fee can't be more than 0.3% on one side.");
        FEE_PERCENT = _feePercent;
    }

    function updateFeeCollector(address _feeCollector) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        require(_feeCollector != address(0), "Atlas Dex: Fee Collector Invalid");         
        FEE_COLLECTOR = _feeCollector;
    }
}