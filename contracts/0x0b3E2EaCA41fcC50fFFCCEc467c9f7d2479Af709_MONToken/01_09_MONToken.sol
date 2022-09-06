// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
import "../Dependencies/CheckContract.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../Dependencies/ERC20Permit.sol";

contract MONToken is CheckContract, ERC20Permit {
	using SafeMath for uint256;

	// uint for use with SafeMath
	uint256 internal _1_MILLION = 1e24; // 1e6 * 1e18 = 1e24

	address public immutable treasury;

	constructor(address _treasurySig) ERC20("Moneta", "MON") {
		require(_treasurySig != address(0), "Invalid Treasury Sig");
		treasury = _treasurySig;

		//Lazy Mint to setup protocol.
		//After the deployment scripts, deployer addr automatically send the fund to the treasury.
		_mint(_treasurySig, _1_MILLION.mul(100));
	}
}