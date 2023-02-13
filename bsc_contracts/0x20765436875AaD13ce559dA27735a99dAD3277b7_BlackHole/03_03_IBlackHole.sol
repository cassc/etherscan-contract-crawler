// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Contract for absorbing any ERC20 token and many other things.
 * @author 5Tr3TcH @ghostchain
 * @dev Nothing special, just a funny smart contract to be used as a zero address.
 */
interface IBlackHole {
	/**
	 * @dev Get the name of current blackhole.
	 * @return the name of blackhole
	 */
	function whoAmI() external view returns (string memory);
	
	/**
	 * @dev Get absorbed supply of ERC20 token.
	 * @param token address of ERC20 token
	 * @return balance of this address
	 */
	function absorbedBalance(address token) external view returns (uint256);
	
	/**
	 * @dev Get supply of ERC20 token that is not absorbed yet.
	 * @param token address of ERC20 token
	 * @return total supply minus balance of this contract
	 */
	function availableSupply(address token) external view returns (uint256);
}