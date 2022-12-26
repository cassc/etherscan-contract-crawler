pragma solidity 0.8.15;

import "ERC4626.sol";

abstract contract PricePerTokenMixin is ERC4626 {
    function pricePerToken() public view returns (uint256)
	{
		return convertToAssets(10 ** decimals());
	}
}