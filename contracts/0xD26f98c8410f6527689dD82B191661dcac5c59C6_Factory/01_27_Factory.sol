// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IController.sol";
import "./interfaces/IReserve.sol";
import "../lib/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import "./Vault.sol";

contract Factory {
    using FixedPointMathLib for uint256; 
    using SafeTransferLib for ERC20;

    address public immutable reserve;
    
    event VaultDeployed(address controller, address vault);

    constructor(address _reserve) {
        reserve = _reserve;
    }

   function deploy(address controller, uint256 _collateral_fees) external returns(address) {
        address vault = address(new Vault(msg.sender, controller, reserve, _collateral_fees));
        IReserve(reserve).addVault(vault);
		emit VaultDeployed(controller, vault);

		return vault;
   }
}