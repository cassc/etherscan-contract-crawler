pragma solidity ^0.6.12;

import "IERC20.sol";
import "ERC20.sol";
import "SafeMath.sol";

/*
 *     ,_,
 *    (',')
 *    {/"\}
 *    -"-"-
 */

interface IOldeNana is IERC20 {
	function rewards(address) external view returns(uint256);
	function lastUpdate(address) external view returns(uint256);
}

contract BananaV2 is ERC20("Banana", "BANANA") {
	using SafeMath for uint256;

	address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
	IOldeNana public constant oldeNana = IOldeNana(0xE2311ae37502105b442bBef831E9b53c5d2e9B3b);
	address public constant yieldHub = 0x86CC33dBE3d2fb95bc6734e1E5920D287695215F;

	constructor() public {
		_mint(msg.sender, 3_650_000 ether);
	}

	function swap() external {
		swap(oldeNana.balanceOf(msg.sender));
	}

	function swap(uint256 _amount) public {
		_mint(msg.sender, _amount);
		oldeNana.transferFrom(msg.sender, BURN_ADDRESS, _amount);
	}

	function burnFrom(address _from, uint256 _amount) external {
		require(msg.sender == yieldHub, "!hub");
		_burn(_from, _amount);
	}

	function burnFor(address _user, uint256 _amount) external {
		uint256 currentAllowance = allowance(_user, msg.sender);
		_approve(_user, msg.sender, currentAllowance.sub(_amount));
		_burn(_user, _amount);
	}

	function burn(uint256 _amount) external {
		_burn(msg.sender, _amount);
	}

	function mint(address _to, uint256 _amount) external {
		require(msg.sender == yieldHub, "!hub");
		_mint(_to, _amount);
	}
}