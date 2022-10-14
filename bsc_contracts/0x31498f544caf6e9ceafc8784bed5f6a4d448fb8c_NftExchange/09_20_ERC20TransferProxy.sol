// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./OwnableOperatorRole.sol";

contract ERC20TransferProxy is Initializable, OwnableUpgradeable, OwnableOperatorRole {
	using SafeERC20Upgradeable for IERC20Upgradeable;
	
	function initialize() public virtual initializer {
		__Ownable_init();
    }
	
    function erc20safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) external onlyOperator {
        require(token.transferFrom(from, to, value), "failure while transferring");
    }
}