// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MBTC is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, OwnableUpgradeable {
	uint8 private _decimals;
    
    function initialize(string memory name, string memory symbol, uint256 initialSupply, address payable beneficiary, uint8 decimals_) initializer public {
        __ERC20_init(name, symbol);
        __ERC20Burnable_init();
        __Ownable_init();
		
		_decimals = decimals_;
        _mint(beneficiary, initialSupply);
    }
	
	function decimals() public override view returns (uint8) {
		return _decimals;
	}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
	
	function version() public pure returns (string memory) {
		return "1.0";
	}
	
	receive() external payable{
		revert();
	}
	
	fallback() external payable{
		revert();
	}
	
}